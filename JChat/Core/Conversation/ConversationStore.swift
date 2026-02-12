//
//  ConversationStore.swift
//  JChat
//

import SwiftUI
import SwiftData

/// Primary state store for the V2 chat surface.
@MainActor
@Observable
final class ConversationStore {
    var selectedChat: Chat?
    var isLoading = false
    var isStreaming = false
    var streamingContent: String = ""
    var errorMessage: String?
    var errorSuggestion: String?

    private let repository: any ChatRepositoryProtocol
    private let engine: any ChatEngineProtocol
    private var streamingTask: Task<Void, Never>?
    private var activeStreamingSessionID: UUID?

    init(repository: any ChatRepositoryProtocol, engine: any ChatEngineProtocol) {
        self.repository = repository
        self.engine = engine
    }

    convenience init() {
        self.init(repository: SwiftDataChatRepository(), engine: OpenRouterChatEngine())
    }

    func createNewChat(in context: ModelContext) {
        do {
            selectedChat = try repository.createNewChat(in: context)
        } catch {
            setError((error as? JChatError) ?? .unknown(error))
        }
    }

    func deleteChat(_ chat: Chat, in context: ModelContext) {
        if selectedChat?.id == chat.id {
            selectedChat = nil
        }
        do {
            try repository.deleteChat(chat, in: context)
        } catch {
            setError((error as? JChatError) ?? .unknown(error))
        }
    }

    func sendMessage(content: String, context: ModelContext) async {
        guard let chat = selectedChat else { return }
        guard let modelID = selectedModelID(for: chat),
              let apiKey = loadAPIKeyOrSetError() else { return }
        resetStreamingStateForNewRequest()

        let userMessage = Message(role: .user, content: content)
        userMessage.chat = chat
        chat.messages.append(userMessage)

        startAssistantResponse(
            in: chat,
            modelID: modelID,
            apiKey: apiKey,
            context: context,
            titleSeed: content
        )
    }

    func stopStreaming() {
        streamingTask?.cancel()
        // Keep the task reference alive until cancellation cleanup finishes so
        // already-streamed content can be persisted to the assistant message.
        activeStreamingSessionID = nil
        isLoading = false
        isStreaming = false
    }

    func clearError() {
        errorMessage = nil
        errorSuggestion = nil
    }

    func regenerateMessage(withID messageID: UUID, in context: ModelContext) async {
        guard let chat = selectedChat else { return }

        let sorted = chat.sortedMessages
        guard let index = sorted.firstIndex(where: { $0.id == messageID }),
              index > 0,
              sorted[index - 1].role == .user else { return }

        if let target = chat.messages.first(where: { $0.id == messageID }) {
            chat.messages.removeAll { $0.id == messageID }
            context.delete(target)
        }

        guard let modelID = selectedModelID(for: chat),
              let apiKey = loadAPIKeyOrSetError() else { return }
        resetStreamingStateForNewRequest()

        startAssistantResponse(
            in: chat,
            modelID: modelID,
            apiKey: apiKey,
            context: context,
            titleSeed: nil
        )
    }

    func deleteMessage(withID messageID: UUID, in context: ModelContext) {
        guard let chat = selectedChat,
              let message = chat.messages.first(where: { $0.id == messageID }) else {
            return
        }

        do {
            try repository.deleteMessage(message, in: context)
        } catch {
            setError((error as? JChatError) ?? .unknown(error))
        }
    }

    func updateMessageContent(messageID: UUID, newContent: String, in context: ModelContext) {
        guard let chat = selectedChat,
              let message = chat.messages.first(where: { $0.id == messageID }) else {
            return
        }

        let trimmed = newContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        message.content = trimmed
        message.isEdited = true

        do {
            try repository.save(context: context)
        } catch {
            setError((error as? JChatError) ?? .unknown(error))
        }
    }

    private func selectedModelID(for chat: Chat) -> String? {
        guard let modelID = chat.selectedModelID, !modelID.isEmpty else {
            setError(.noModelSelected)
            return nil
        }
        return modelID
    }

    private func loadAPIKeyOrSetError() -> String? {
        do {
            let apiKey = try KeychainManager.shared.loadAPIKey()
            guard !apiKey.isEmpty else {
                setError(.apiKeyNotConfigured)
                return nil
            }
            return apiKey
        } catch {
            setError(.apiKeyNotConfigured)
            return nil
        }
    }

    private func resetStreamingStateForNewRequest() {
        isLoading = true
        isStreaming = true
        streamingContent = ""
        errorMessage = nil
        errorSuggestion = nil
    }

    private func setError(_ error: JChatError) {
        errorMessage = error.errorDescription
        errorSuggestion = error.recoverySuggestion
    }

    private func buildHistory(for chat: Chat) -> [(role: String, content: String)] {
        var history: [(role: String, content: String)] = []

        if let systemPrompt = chat.character?.systemPrompt, !systemPrompt.isEmpty {
            history.append((role: "system", content: systemPrompt))
        }

        for msg in chat.sortedMessages {
            history.append((role: msg.role.rawValue, content: msg.content))
        }

        return history
    }

    private func buildParameters(for chat: Chat) -> ChatParameters {
        ChatParameters(
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
    }

    private func startAssistantResponse(
        in chat: Chat,
        modelID: String,
        apiKey: String,
        context: ModelContext,
        titleSeed: String?
    ) {
        let sessionID = UUID()
        activeStreamingSessionID = sessionID

        let request = ChatEngineRequest(
            messages: buildHistory(for: chat),
            modelID: modelID,
            parameters: buildParameters(for: chat),
            apiKey: apiKey
        )

        let assistantMessage = Message(role: .assistant, content: "", modelID: modelID)
        assistantMessage.chat = chat
        chat.messages.append(assistantMessage)

        streamingTask = Task { @MainActor in
            var accumulator = StreamTextAccumulator()
            var renderedContent = ""

            do {
                let stream = await engine.streamAssistantResponse(request: request)
                for try await event in stream {
                    switch event {
                    case .delta(let text):
                        if let flushed = accumulator.append(text) {
                            renderedContent += flushed
                            if activeStreamingSessionID == sessionID {
                                streamingContent = renderedContent
                            }
                        }
                    case .usage(let promptTokens, let completionTokens):
                        let previousPromptTokens = assistantMessage.promptTokens
                        let previousCompletionTokens = assistantMessage.completionTokens
                        let previousCost = assistantMessage.cost

                        assistantMessage.promptTokens = promptTokens
                        assistantMessage.completionTokens = completionTokens

                        var updatedCost = previousCost
                        let modelDescriptor = FetchDescriptor<CachedModel>(predicate: #Predicate { $0.id == modelID })
                        if let cachedModel = try? context.fetch(modelDescriptor).first {
                            updatedCost = cachedModel.calculateCost(promptTokens: promptTokens, completionTokens: completionTokens)
                        }
                        assistantMessage.cost = updatedCost

                        let promptDelta = promptTokens - previousPromptTokens
                        let completionDelta = completionTokens - previousCompletionTokens
                        let costDelta = updatedCost - previousCost

                        if promptDelta > 0 || completionDelta > 0 || costDelta > 0 {
                            chat.addUsage(
                                promptTokens: max(0, promptDelta),
                                completionTokens: max(0, completionDelta),
                                cost: max(0, costDelta)
                            )
                        } else if promptDelta < 0 || completionDelta < 0 || costDelta < 0 {
                            chat.removeUsage(
                                promptTokens: max(0, -promptDelta),
                                completionTokens: max(0, -completionDelta),
                                cost: max(0, -costDelta)
                            )
                        }
                    case .modelID(let id):
                        assistantMessage.modelID = id
                    case .done:
                        break
                    }
                }

                if let remaining = accumulator.flush() {
                    renderedContent += remaining
                    if activeStreamingSessionID == sessionID {
                        streamingContent = renderedContent
                    }
                }

                assistantMessage.content = renderedContent

                if let titleSeed,
                   chat.sortedMessages.filter({ $0.role == .user }).count == 1 {
                    chat.title = String(titleSeed.prefix(40)) + (titleSeed.count > 40 ? "..." : "")
                }

                try repository.save(context: context)
            } catch is CancellationError {
                if let remaining = accumulator.flush() {
                    renderedContent += remaining
                    if activeStreamingSessionID == sessionID {
                        streamingContent = renderedContent
                    }
                }
                assistantMessage.content = renderedContent
                try? repository.save(context: context)
            } catch {
                if let remaining = accumulator.flush() {
                    renderedContent += remaining
                    if activeStreamingSessionID == sessionID {
                        streamingContent = renderedContent
                    }
                }
                setError((error as? JChatError) ?? .unknown(error))
                assistantMessage.content = renderedContent
                if assistantMessage.content.isEmpty {
                    chat.messages.removeAll { $0.id == assistantMessage.id }
                    context.delete(assistantMessage)
                }
                try? context.save()
            }

            if activeStreamingSessionID == sessionID {
                isLoading = false
                isStreaming = false
                streamingContent = ""
                activeStreamingSessionID = nil
            }
            if activeStreamingSessionID == nil {
                streamingTask = nil
            }
        }
    }
}
