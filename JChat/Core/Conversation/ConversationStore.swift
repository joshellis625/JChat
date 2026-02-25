//
//  ConversationStore.swift
//  JChat
//

import SwiftData
import SwiftUI

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
    private(set) var titleGenerationInProgressChatIDs: Set<UUID> = []
    private(set) var titleGenerationFailedChatIDs: Set<UUID> = []
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
        let inheritedModelID = selectedChat?.selectedModelID?.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            let newChat = try repository.createNewChat(in: context)
            if let inheritedModelID, !inheritedModelID.isEmpty, newChat.selectedModelID != inheritedModelID {
                newChat.selectedModelID = inheritedModelID
                try repository.save(context: context)
            }
            selectedChat = newChat
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

        await startAssistantResponse(
            in: chat,
            triggerUserMessage: userMessage,
            modelID: modelID,
            apiKey: apiKey,
            context: context
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

        let precedingUserMessage = sorted[index - 1]

        if let target = chat.messages.first(where: { $0.id == messageID }) {
            chat.messages.removeAll { $0.id == messageID }
            context.delete(target)
        }

        guard let modelID = selectedModelID(for: chat),
              let apiKey = loadAPIKeyOrSetError() else { return }
        resetStreamingStateForNewRequest()

        await startAssistantResponse(
            in: chat,
            triggerUserMessage: precedingUserMessage,
            modelID: modelID,
            apiKey: apiKey,
            context: context
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

    func resendLastUserMessage(in context: ModelContext) async {
        guard let chat = selectedChat,
              let lastUser = chat.sortedMessages.last,
              lastUser.role == .user,
              let modelID = selectedModelID(for: chat),
              let apiKey = loadAPIKeyOrSetError() else { return }
        resetStreamingStateForNewRequest()
        await startAssistantResponse(
            in: chat,
            triggerUserMessage: lastUser,
            modelID: modelID,
            apiKey: apiKey,
            context: context
        )
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

    func generatePendingAutoTitles(in context: ModelContext) async {
        guard let apiKey = loadAPIKeySilently() else { return }
        let descriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.createdAt)])
        let chats = (try? context.fetch(descriptor)) ?? []
        for chat in chats {
            guard shouldGenerateAutoTitle(for: chat) else { continue }
            await generateAutoTitleIfNeeded(for: chat, apiKey: apiKey, context: context)
        }
    }

    func isGeneratingTitle(for chatID: UUID) -> Bool {
        titleGenerationInProgressChatIDs.contains(chatID)
    }

    func didFailGeneratingTitle(for chatID: UUID) -> Bool {
        titleGenerationFailedChatIDs.contains(chatID)
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

    private func loadAPIKeySilently() -> String? {
        do {
            let apiKey = try KeychainManager.shared.loadAPIKey()
            let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        } catch {
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
        // Only include a parameter when it differs from its API default.
        // nil values are omitted from the JSON payload entirely.
        let temp = chat.effectiveTemperature
        let topP = chat.effectiveTopP
        let maxTok = chat.effectiveMaxTokens // 0 = unlimited/off

        return ChatParameters(
            temperature: temp != 1.0 ? temp : nil,
            maxTokens: maxTok > 0 ? maxTok : nil,
            topP: topP != 1.0 ? topP : nil,
            topK: chat.effectiveTopK > 0 ? chat.effectiveTopK : nil,
            frequencyPenalty: chat.effectiveFrequencyPenalty != 0 ? chat.effectiveFrequencyPenalty : nil,
            presencePenalty: chat.effectivePresencePenalty != 0 ? chat.effectivePresencePenalty : nil,
            repetitionPenalty: chat.effectiveRepetitionPenalty != 1.0 ? chat.effectiveRepetitionPenalty : nil,
            minP: chat.effectiveMinP != 0 ? chat.effectiveMinP : nil,
            topA: chat.effectiveTopA != 0 ? chat.effectiveTopA : nil,
            reasoningEnabled: chat.effectiveReasoningEnabled,
            reasoningEffort: chat.effectiveReasoningEffort,
            reasoningMaxTokens: chat.effectiveReasoningMaxTokens,
            reasoningExclude: chat.effectiveReasoningExclude,
            verbosity: chat.effectiveVerbosity
        )
    }

    private func startAssistantResponse(
        in chat: Chat,
        triggerUserMessage: Message,
        modelID: String,
        apiKey: String,
        context: ModelContext
    ) async {
        let sessionID = UUID()
        activeStreamingSessionID = sessionID

        let request = ChatEngineRequest(
            messages: buildHistory(for: chat),
            modelID: modelID,
            parameters: buildParameters(for: chat),
            apiKey: apiKey
        )

        // Capture the prettified POST body on the specific user message that triggered this request
        triggerUserMessage.rawRequestJSON = await engine.prettyRequestJSON(for: request)

        let assistantMessage = Message(role: .assistant, content: "", modelID: modelID)
        assistantMessage.chat = chat
        chat.messages.append(assistantMessage)

        streamingTask = Task { @MainActor in
            var accumulator = StreamTextAccumulator()
            var renderedContent = ""
            // Accumulated from the stream to build the response JSON inspector data.
            // OpenRouter doesn't store messages, so this is our only record of what the API returned.
            var capturedFinishReason: String?
            var capturedGenerationID: String?

            do {
                let stream = await engine.streamAssistantResponse(request: request)
                for try await event in stream {
                    switch event {
                    case let .delta(text):
                        if let flushed = accumulator.append(text) {
                            renderedContent += flushed
                            if activeStreamingSessionID == sessionID {
                                streamingContent = renderedContent
                            }
                        }
                    case let .usage(promptTokens, completionTokens, rawJSON):
                        assistantMessage.rawUsageJSON = rawJSON
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
                    case let .modelID(id):
                        assistantMessage.modelID = id
                    case let .generationID(id):
                        capturedGenerationID = id
                    case let .finishReason(reason):
                        capturedFinishReason = reason
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
                assistantMessage.rawResponseJSON = buildResponseJSON(
                    generationID: capturedGenerationID,
                    model: assistantMessage.modelID ?? modelID,
                    finishReason: capturedFinishReason ?? "stop",
                    content: renderedContent,
                    promptTokens: assistantMessage.promptTokens,
                    completionTokens: assistantMessage.completionTokens
                )
                try repository.save(context: context)
                await generateAutoTitleIfNeeded(for: chat, apiKey: apiKey, context: context)
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

    private func generateAutoTitleIfNeeded(for chat: Chat, apiKey: String, context: ModelContext) async {
        guard shouldGenerateAutoTitle(for: chat) else { return }
        guard !titleGenerationInProgressChatIDs.contains(chat.id) else { return }
        titleGenerationFailedChatIDs.remove(chat.id)
        titleGenerationInProgressChatIDs.insert(chat.id)
        defer { titleGenerationInProgressChatIDs.remove(chat.id) }

        do {
            let title = try await requestAutoTitle(for: chat, apiKey: apiKey)
            if let normalizedTitle = normalizedAutoTitle(title), !normalizedTitle.isEmpty {
                chat.title = normalizedTitle
                try repository.save(context: context)
                print("[AutoTitle] Success for chat \(chat.id) with model \(autoTitleModelID(for: chat))")
            } else {
                titleGenerationFailedChatIDs.insert(chat.id)
                print("[AutoTitle] Empty/invalid title for chat \(chat.id) with model \(autoTitleModelID(for: chat))")
            }
        } catch {
            titleGenerationFailedChatIDs.insert(chat.id)
            print("[AutoTitle] Failed for chat \(chat.id) with model \(autoTitleModelID(for: chat)): \(error)")
        }
    }

    private func shouldGenerateAutoTitle(for chat: Chat) -> Bool {
        guard shouldAttemptTitleGeneration(basedOn: chat.title) else { return false }
        let userMessages = chat.sortedMessages.filter { $0.role == .user && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let assistantMessages = chat.sortedMessages.filter { $0.role == .assistant && !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !userMessages.isEmpty && !assistantMessages.isEmpty
    }

    private func requestAutoTitle(for chat: Chat, apiKey: String) async throws -> String {
        let sorted = chat.sortedMessages
        guard let firstUser = sorted.first(where: { $0.role == .user }),
              let firstAssistant = sorted.first(where: { $0.role == .assistant }) else {
            throw JChatError.decodingError("Unable to collect first exchange for title generation.")
        }

        let userExcerpt = String(firstUser.content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(600))
        let assistantExcerpt = String(firstAssistant.content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(600))

        let userPrompt = """
        Generate a short conversation title using the following: + \(userExcerpt) + \(assistantExcerpt)
        Output only the title and nothing else.
        Use 3 to 5 words.
        No markdown.
        No punctuation.
        """

        var parameters = ChatParameters()
        parameters.temperature = 0.2
        parameters.maxTokens = 32
        parameters.reasoningEnabled = false

        let completion = try await OpenRouterService.shared.sendMessage(
            request: ModelCallRequest(
                messages: [(role: "user", content: userPrompt)],
                modelID: autoTitleModelID(for: chat),
                parameters: parameters,
                apiKey: apiKey,
                stream: false
            )
        )
        return completion.content
    }

    private func autoTitleModelID(for chat: Chat) -> String {
        let fallback = "google/gemma-12b-it"
        guard let selected = chat.selectedModelID?.trimmingCharacters(in: .whitespacesAndNewlines),
              !selected.isEmpty else {
            return fallback
        }
        return selected
    }

    private func normalizedAutoTitle(_ raw: String) -> String? {
        let firstLine = raw
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !firstLine.isEmpty else { return nil }

        let normalized = firstLine
            .replacingOccurrences(of: "conversation title", with: "", options: [.caseInsensitive, .regularExpression])
            .replacingOccurrences(of: "title", with: "", options: [.caseInsensitive, .regularExpression])
            .replacingOccurrences(of: "[*_`#:\\-—–|\\[\\]\\(\\)\"'“”.,!?;]+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return nil }
        let words = normalized
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }

        guard words.count >= 3 else { return nil }
        return words.prefix(5).joined(separator: " ")
    }

    /// Reconstructs an OpenRouter-compatible chat completion response object.
    ///
    /// Because OpenRouter does not store user or assistant messages, this
    /// synthetic JSON is the only persistent record of what the API returned.
    /// The structure follows the ``ChatResponse`` schema from the OpenRouter
    /// OpenAPI spec (``object: "chat.completion"``).
    private func buildResponseJSON(
        generationID: String?,
        model: String,
        finishReason: String,
        content: String,
        promptTokens: Int,
        completionTokens: Int
    ) -> String? {
        let responseDict: [String: Any] = [
            "id": generationID ?? "unknown",
            "object": "chat.completion",
            "created": Int(Date().timeIntervalSince1970),
            "model": model,
            "choices": [[
                "index": 0,
                "message": [
                    "role": "assistant",
                    "content": content
                ],
                "finish_reason": finishReason
            ]],
            "usage": [
                "prompt_tokens": promptTokens,
                "completion_tokens": completionTokens,
                "total_tokens": promptTokens + completionTokens
            ]
        ]

        guard let data = try? JSONSerialization.data(
            withJSONObject: responseDict,
            options: [.prettyPrinted, .sortedKeys]
        ) else { return nil }

        return String(data: data, encoding: .utf8)
    }

    private func shouldAttemptTitleGeneration(basedOn title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        if trimmed == "New Chat" { return true }

        let lower = trimmed.lowercased()
        if lower.contains("conversation title") { return true }
        if trimmed.contains("*") || trimmed.contains("`") || trimmed.contains(":") {
            return true
        }
        return false
    }
}
