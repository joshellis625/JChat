//
//  ChatViewModel.swift
//  JChat
//

import SwiftUI
import SwiftData

@Observable
class ChatViewModel {
    var selectedChat: Chat?
    var isLoading = false
    var isStreaming = false
    var streamingContent: String = ""
    var errorMessage: String?
    var errorSuggestion: String?

    private let service = OpenRouterService.shared
    private var streamingTask: Task<Void, Never>?

    func createNewChat(in context: ModelContext) -> Chat {
        let chat = Chat()

        // Inherit parameters from the most recent chat (so settings carry forward)
        let chatDescriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let mostRecent = try? context.fetch(chatDescriptor).first {
            chat.inheritParameters(from: mostRecent)
        }

        // Assign default character if available
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        if let settings = try? context.fetch(settingsDescriptor).first,
           let defaultCharacterID = settings.defaultCharacterID {
            let characterDescriptor = FetchDescriptor<Character>(predicate: #Predicate { $0.id == defaultCharacterID })
            chat.character = try? context.fetch(characterDescriptor).first
        }
        // Fall back to any default character
        if chat.character == nil {
            let defaultDescriptor = FetchDescriptor<Character>(predicate: #Predicate { $0.isDefault == true })
            chat.character = try? context.fetch(defaultDescriptor).first
        }

        // Set default model: character preferred → settings default
        if let preferredModel = chat.character?.preferredModelID, !preferredModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let modelDescriptor = FetchDescriptor<CachedModel>(predicate: #Predicate { $0.id == preferredModel })
            if let _ = try? context.fetch(modelDescriptor).first {
                chat.selectedModelID = preferredModel
            }
        }

        if chat.selectedModelID == nil {
            let settings = try? context.fetch(settingsDescriptor).first
            if let defaultModel = settings?.defaultModelID {
                chat.selectedModelID = defaultModel
            }
        }

        context.insert(chat)
        try? context.save()
        selectedChat = chat
        return chat
    }

    func deleteChat(_ chat: Chat, in context: ModelContext) {
        if selectedChat?.id == chat.id {
            selectedChat = nil
        }
        context.delete(chat)
        try? context.save()
    }

    @MainActor
    func sendMessage(content: String, context: ModelContext) async {
        guard let chat = selectedChat else { return }

        guard let modelID = chat.selectedModelID, !modelID.isEmpty else {
            errorMessage = JChatError.noModelSelected.errorDescription
            errorSuggestion = JChatError.noModelSelected.recoverySuggestion
            return
        }

        let apiKey: String
        do {
            apiKey = try KeychainManager.shared.loadAPIKey()
        } catch {
            let err = JChatError.apiKeyNotConfigured
            errorMessage = err.errorDescription
            errorSuggestion = err.recoverySuggestion
            return
        }

        guard !apiKey.isEmpty else {
            let err = JChatError.apiKeyNotConfigured
            errorMessage = err.errorDescription
            errorSuggestion = err.recoverySuggestion
            return
        }

        isLoading = true
        isStreaming = true
        streamingContent = ""
        errorMessage = nil
        errorSuggestion = nil

        // Add user message
        let userMessage = Message(role: .user, content: content)
        userMessage.chat = chat
        chat.messages.append(userMessage)

        // Build message history
        var history: [(role: String, content: String)] = []
        if let systemPrompt = chat.character?.systemPrompt, !systemPrompt.isEmpty {
            history.append((role: "system", content: systemPrompt))
        }
        for msg in chat.sortedMessages {
            history.append((role: msg.role.rawValue, content: msg.content))
        }

        // Build parameters from chat effective values
        let params = ChatParameters(
            temperature: chat.effectiveTemperature,
            maxTokens: chat.effectiveMaxTokens,
            topP: chat.effectiveTopP,
            topK: chat.effectiveTopK > 0 ? chat.effectiveTopK : nil,
            frequencyPenalty: chat.effectiveFrequencyPenalty != 0 ? chat.effectiveFrequencyPenalty : nil,
            presencePenalty: chat.effectivePresencePenalty != 0 ? chat.effectivePresencePenalty : nil,
            repetitionPenalty: chat.effectiveRepetitionPenalty != 1.0 ? chat.effectiveRepetitionPenalty : nil,
            minP: chat.effectiveMinP != 0 ? chat.effectiveMinP : nil,
            topA: chat.effectiveTopA != 0 ? chat.effectiveTopA : nil,
            stream: chat.effectiveStream,
            reasoningEnabled: chat.effectiveReasoningEnabled,
            reasoningEffort: chat.effectiveReasoningEffort,
            reasoningMaxTokens: chat.effectiveReasoningMaxTokens,
            reasoningExclude: chat.effectiveReasoningExclude,
            verbosity: chat.effectiveVerbosity
        )

        // Create placeholder assistant message for streaming
        let assistantMessage = Message(role: .assistant, content: "", modelID: modelID)
        assistantMessage.chat = chat
        chat.messages.append(assistantMessage)

        let capturedModelID = modelID
        streamingTask = Task {
            do {
                let stream = await service.streamMessage(
                    messages: history,
                    modelID: capturedModelID,
                    parameters: params,
                    apiKey: apiKey
                )
                for try await event in stream {
                    switch event {
                    case .delta(let text):
                        streamingContent += text
                        assistantMessage.content = streamingContent
                    case .usage(let prompt, let completion):
                        assistantMessage.promptTokens = prompt
                        assistantMessage.completionTokens = completion
                        let modelDescriptor = FetchDescriptor<CachedModel>(predicate: #Predicate { $0.id == capturedModelID })
                        if let cachedModel = try? context.fetch(modelDescriptor).first {
                            assistantMessage.cost = cachedModel.calculateCost(promptTokens: prompt, completionTokens: completion)
                        }
                        chat.totalPromptTokens += prompt
                        chat.totalCompletionTokens += completion
                        chat.totalCost += assistantMessage.cost
                    case .modelID(let id):
                        assistantMessage.modelID = id
                    case .done:
                        break
                    case .error(let jchatError):
                        throw jchatError
                    }
                }

                // Auto-title on first exchange
                if chat.sortedMessages.filter({ $0.role == .user }).count == 1 {
                    chat.title = String(content.prefix(40)) + (content.count > 40 ? "..." : "")
                }

                try? context.save()
            } catch {
                let jchatError = (error as? JChatError) ?? .unknown(error)
                errorMessage = jchatError.errorDescription
                errorSuggestion = jchatError.recoverySuggestion
                if assistantMessage.content.isEmpty {
                    chat.messages.removeAll { $0.id == assistantMessage.id }
                    context.delete(assistantMessage)
                }
                try? context.save()
            }

            isLoading = false
            isStreaming = false
            streamingContent = ""
        }
    }

    func stopStreaming() {
        streamingTask?.cancel()
        streamingTask = nil
        isLoading = false
        isStreaming = false
        streamingContent = ""
    }

    @MainActor
    func regenerateMessage(_ message: Message, in context: ModelContext) async {
        guard let chat = selectedChat else { return }

        let sorted = chat.sortedMessages
        guard let index = sorted.firstIndex(where: { $0.id == message.id }),
              index > 0,
              sorted[index - 1].role == .user else { return }

        // Subtract old assistant message stats
        chat.totalPromptTokens -= message.promptTokens
        chat.totalCompletionTokens -= message.completionTokens
        chat.totalCost -= message.cost

        // Delete old assistant message
        chat.messages.removeAll { $0.id == message.id }
        context.delete(message)

        // Re-send using existing user message (don't create a new one)
        guard let modelID = chat.selectedModelID, !modelID.isEmpty else {
            errorMessage = JChatError.noModelSelected.errorDescription
            errorSuggestion = JChatError.noModelSelected.recoverySuggestion
            return
        }

        let apiKey: String
        do {
            apiKey = try KeychainManager.shared.loadAPIKey()
        } catch {
            let err = JChatError.apiKeyNotConfigured
            errorMessage = err.errorDescription
            errorSuggestion = err.recoverySuggestion
            return
        }
        guard !apiKey.isEmpty else {
            let err = JChatError.apiKeyNotConfigured
            errorMessage = err.errorDescription
            errorSuggestion = err.recoverySuggestion
            return
        }

        isLoading = true
        isStreaming = true
        streamingContent = ""
        errorMessage = nil
        errorSuggestion = nil

        // Build message history from existing messages (user msg is already there)
        var history: [(role: String, content: String)] = []
        if let systemPrompt = chat.character?.systemPrompt, !systemPrompt.isEmpty {
            history.append((role: "system", content: systemPrompt))
        }
        for msg in chat.sortedMessages {
            history.append((role: msg.role.rawValue, content: msg.content))
        }

        let params = ChatParameters(
            temperature: chat.effectiveTemperature,
            maxTokens: chat.effectiveMaxTokens,
            topP: chat.effectiveTopP,
            topK: chat.effectiveTopK > 0 ? chat.effectiveTopK : nil,
            frequencyPenalty: chat.effectiveFrequencyPenalty != 0 ? chat.effectiveFrequencyPenalty : nil,
            presencePenalty: chat.effectivePresencePenalty != 0 ? chat.effectivePresencePenalty : nil,
            repetitionPenalty: chat.effectiveRepetitionPenalty != 1.0 ? chat.effectiveRepetitionPenalty : nil,
            minP: chat.effectiveMinP != 0 ? chat.effectiveMinP : nil,
            topA: chat.effectiveTopA != 0 ? chat.effectiveTopA : nil,
            stream: chat.effectiveStream,
            reasoningEnabled: chat.effectiveReasoningEnabled,
            reasoningEffort: chat.effectiveReasoningEffort,
            reasoningMaxTokens: chat.effectiveReasoningMaxTokens,
            reasoningExclude: chat.effectiveReasoningExclude,
            verbosity: chat.effectiveVerbosity
        )

        // Create new assistant message placeholder
        let assistantMessage = Message(role: .assistant, content: "", modelID: modelID)
        assistantMessage.chat = chat
        chat.messages.append(assistantMessage)

        let capturedModelID = modelID
        streamingTask = Task {
            do {
                let stream = await service.streamMessage(
                    messages: history,
                    modelID: capturedModelID,
                    parameters: params,
                    apiKey: apiKey
                )
                for try await event in stream {
                    switch event {
                    case .delta(let text):
                        streamingContent += text
                        assistantMessage.content = streamingContent
                    case .usage(let prompt, let completion):
                        assistantMessage.promptTokens = prompt
                        assistantMessage.completionTokens = completion
                        let modelDescriptor = FetchDescriptor<CachedModel>(predicate: #Predicate { $0.id == capturedModelID })
                        if let cachedModel = try? context.fetch(modelDescriptor).first {
                            assistantMessage.cost = cachedModel.calculateCost(promptTokens: prompt, completionTokens: completion)
                        }
                        chat.totalPromptTokens += prompt
                        chat.totalCompletionTokens += completion
                        chat.totalCost += assistantMessage.cost
                    case .modelID(let id):
                        assistantMessage.modelID = id
                    case .done:
                        break
                    case .error(let jchatError):
                        throw jchatError
                    }
                }
                try? context.save()
            } catch {
                let jchatError = (error as? JChatError) ?? .unknown(error)
                errorMessage = jchatError.errorDescription
                errorSuggestion = jchatError.recoverySuggestion
                if assistantMessage.content.isEmpty {
                    chat.messages.removeAll { $0.id == assistantMessage.id }
                    context.delete(assistantMessage)
                }
                try? context.save()
            }

            isLoading = false
            isStreaming = false
            streamingContent = ""
        }
    }

    func deleteMessage(_ message: Message, in context: ModelContext) {
        guard let chat = selectedChat else { return }
        chat.totalPromptTokens -= message.promptTokens
        chat.totalCompletionTokens -= message.completionTokens
        chat.totalCost -= message.cost
        chat.messages.removeAll { $0.id == message.id }
        context.delete(message)
        try? context.save()
    }
}
