//
//  JChatTests.swift
//  JChatTests
//
//  Created by Josh Ellis on 1/31/26.
//

import Foundation
@testable import JChat
import SwiftData
import Testing

struct JChatTests {
    // Minimal in-memory repository/engine doubles for ConversationStore tests.
    @MainActor
    private struct InMemoryChatRepository: ChatRepositoryProtocol {
        func createNewChat(in context: ModelContext) throws -> Chat {
            let chat = Chat()
            context.insert(chat)
            try context.save()
            return chat
        }

        func deleteChat(_ chat: Chat, in context: ModelContext) throws {
            context.delete(chat)
            try context.save()
        }

        func deleteMessage(_ message: Message, in context: ModelContext) throws {
            if let chat = message.chat {
                chat.messages.removeAll { $0.id == message.id }
            }
            context.delete(message)
            try context.save()
        }

        func save(context: ModelContext) throws {
            try context.save()
        }
    }

    private actor EmptyEngine: ChatEngineProtocol {
        func streamAssistantResponse(request: ChatEngineRequest) async -> AsyncThrowingStream<ChatEngineEvent, Error> {
            AsyncThrowingStream { continuation in
                continuation.yield(.done)
                continuation.finish()
            }
        }

        func prettyRequestJSON(for request: ChatEngineRequest) async -> String? {
            nil
        }
    }

    @Test func chatTotalsIncludePromptAndCompletion() {
        let chat = Chat()
        chat.totalPromptTokens = 120
        chat.totalCompletionTokens = 80

        #expect(chat.totalTokens == 200)
    }

    @Test func inheritCopiesAllOverrides() {
        let source = Chat()
        source.temperatureOverride = 0.5
        source.topPOverride = 0.9
        source.topKOverride = 40
        source.maxTokensOverride = 2000
        source.reasoningEnabledOverride = true
        source.reasoningEffortOverride = "high"
        source.reasoningMaxTokensOverride = 4096
        source.reasoningExcludeOverride = true
        source.verbosityOverride = "high"

        let target = Chat()
        target.inheritParameters(from: source)

        #expect(target.temperatureOverride == 0.5)
        #expect(target.topPOverride == 0.9)
        #expect(target.topKOverride == 40)
        #expect(target.maxTokensOverride == 2000)
        #expect(target.reasoningEnabledOverride == true)
        #expect(target.reasoningEffortOverride == "high")
        #expect(target.reasoningMaxTokensOverride == 4096)
        #expect(target.reasoningExcludeOverride == true)
        #expect(target.verbosityOverride == "high")
    }

    @Test func resetAllOverridesClearsValuesAndCount() {
        let chat = Chat()
        chat.temperatureOverride = 1.2
        chat.topKOverride = 50
        chat.verbosityOverride = "low"

        #expect(chat.overrideCount == 3)

        chat.resetAllOverrides()

        #expect(chat.temperatureOverride == nil)
        #expect(chat.topKOverride == nil)
        #expect(chat.verbosityOverride == nil)
        #expect(chat.overrideCount == 0)
    }

    @Test func usageRemovalClampsAtZero() {
        let chat = Chat()
        chat.addUsage(promptTokens: 10, completionTokens: 5, cost: 0.12)
        chat.removeUsage(promptTokens: 99, completionTokens: 99, cost: 1.0)

        #expect(chat.totalPromptTokens == 0)
        #expect(chat.totalCompletionTokens == 0)
        #expect(chat.totalCost == 0)
    }

    @Test func streamAccumulatorFlushesOnSizeThreshold() {
        var accumulator = StreamTextAccumulator(minCharactersBeforeFlush: 5, maxIntervalMilliseconds: 9999)

        #expect(accumulator.append("ab") == nil)
        #expect(accumulator.append("cd") == nil)
        #expect(accumulator.append("e") == "abcde")
    }

    @Test func streamAccumulatorFlushesRemainingContent() {
        var accumulator = StreamTextAccumulator(minCharactersBeforeFlush: 100, maxIntervalMilliseconds: 9999)

        #expect(accumulator.append("hello") == nil)
        #expect(accumulator.flush() == "hello")
        #expect(accumulator.flush() == nil)
    }

    @Test func messageRowSnapshotCopiesModelFields() {
        let message = Message(
            role: .assistant,
            content: "Hello",
            promptTokens: 21,
            completionTokens: 34,
            cost: 0.0042,
            modelID: "openai/gpt-5"
        )
        message.isEdited = true

        let row = MessageRowViewData(message: message)

        #expect(row.id == message.id)
        #expect(row.role == .assistant)
        #expect(row.content == "Hello")
        #expect(row.promptTokens == 21)
        #expect(row.completionTokens == 34)
        #expect(row.cost == 0.0042)
        #expect(row.modelID == "openai/gpt-5")
        #expect(row.isEdited == true)
    }

    @Test @MainActor
    func conversationStoreCreateAndDeleteChatWorksWithRepository() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )

        store.createNewChat(in: context)
        #expect(store.selectedChat != nil)

        let created = try #require(store.selectedChat)
        store.deleteChat(created, in: context)

        #expect(store.selectedChat == nil)
    }

    @Test @MainActor
    func deletingUserMessageDoesNotReduceChatTotals() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()

        context.insert(chat)
        store.selectedChat = chat

        chat.totalPromptTokens = 300
        chat.totalCompletionTokens = 150
        chat.totalCost = 0.42

        let userMessage = Message(role: .user, content: "Hello", promptTokens: 50, completionTokens: 25, cost: 0.10)
        userMessage.chat = chat
        chat.messages.append(userMessage)
        try context.save()

        let originalPrompt = chat.totalPromptTokens
        let originalCompletion = chat.totalCompletionTokens
        let originalCost = chat.totalCost
        let deletedID = userMessage.id

        store.deleteMessage(withID: userMessage.id, in: context)

        #expect(chat.totalPromptTokens == originalPrompt)
        #expect(chat.totalCompletionTokens == originalCompletion)
        #expect(chat.totalCost == originalCost)
        #expect(!chat.messages.contains(where: { $0.id == deletedID }))
    }

    @Test @MainActor
    func deletingAssistantMessageDoesNotReduceChatTotals() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()

        context.insert(chat)
        store.selectedChat = chat

        chat.totalPromptTokens = 420
        chat.totalCompletionTokens = 280
        chat.totalCost = 0.99

        let assistantMessage = Message(role: .assistant, content: "Response", promptTokens: 120, completionTokens: 80, cost: 0.35)
        assistantMessage.chat = chat
        chat.messages.append(assistantMessage)
        try context.save()

        let originalPrompt = chat.totalPromptTokens
        let originalCompletion = chat.totalCompletionTokens
        let originalCost = chat.totalCost
        let deletedID = assistantMessage.id

        store.deleteMessage(withID: assistantMessage.id, in: context)

        #expect(chat.totalPromptTokens == originalPrompt)
        #expect(chat.totalCompletionTokens == originalCompletion)
        #expect(chat.totalCost == originalCost)
        #expect(!chat.messages.contains(where: { $0.id == deletedID }))
    }

    @Test @MainActor
    func regeneratingAssistantMessageDoesNotRefundPriorUsage() async throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()

        context.insert(chat)
        store.selectedChat = chat
        chat.selectedModelID = nil

        chat.totalPromptTokens = 900
        chat.totalCompletionTokens = 600
        chat.totalCost = 1.80

        let userMessage = Message(role: .user, content: "Tell me a joke")
        userMessage.chat = chat
        chat.messages.append(userMessage)

        let assistantMessage = Message(role: .assistant, content: "Old answer", promptTokens: 250, completionTokens: 140, cost: 0.55)
        assistantMessage.chat = chat
        chat.messages.append(assistantMessage)
        try context.save()

        let originalPrompt = chat.totalPromptTokens
        let originalCompletion = chat.totalCompletionTokens
        let originalCost = chat.totalCost
        let regeneratedID = assistantMessage.id

        await store.regenerateMessage(withID: assistantMessage.id, in: context)

        #expect(chat.totalPromptTokens == originalPrompt)
        #expect(chat.totalCompletionTokens == originalCompletion)
        #expect(chat.totalCost == originalCost)
        #expect(!chat.messages.contains(where: { $0.id == regeneratedID }))
    }

    // MARK: - StreamTextAccumulator Edge Cases

    @Test func streamAccumulatorEmptyStringIsNoop() {
        var accumulator = StreamTextAccumulator(minCharactersBeforeFlush: 3, maxIntervalMilliseconds: 9999)
        #expect(accumulator.append("") == nil)
        #expect(accumulator.pending == "")
        #expect(accumulator.append("ab") == nil)
        #expect(accumulator.pending == "ab")
    }

    @Test func streamAccumulatorExactThresholdFlushes() {
        var accumulator = StreamTextAccumulator(minCharactersBeforeFlush: 4, maxIntervalMilliseconds: 9999)
        #expect(accumulator.append("abc") == nil)
        #expect(accumulator.append("d") == "abcd")
        #expect(accumulator.pending == "")
    }

    @Test func streamAccumulatorUnicodeCharacterCount() {
        var accumulator = StreamTextAccumulator(minCharactersBeforeFlush: 3, maxIntervalMilliseconds: 9999)
        #expect(accumulator.append("🎯") == nil)
        #expect(accumulator.append("🚀") == nil)
        #expect(accumulator.append("✅") == "🎯🚀✅")
    }

    @Test func streamAccumulatorResetClearsPending() {
        var accumulator = StreamTextAccumulator(minCharactersBeforeFlush: 100, maxIntervalMilliseconds: 9999)
        _ = accumulator.append("hello world")
        accumulator.reset()
        #expect(accumulator.pending == "")
        #expect(accumulator.flush() == nil)
    }

    // MARK: - updateMessageContent

    @Test @MainActor
    func updateMessageContentSetsIsEdited() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()
        context.insert(chat)
        store.selectedChat = chat

        let msg = Message(role: .user, content: "Original")
        msg.chat = chat
        chat.messages.append(msg)

        store.updateMessageContent(messageID: msg.id, newContent: "  Edited content  ", in: context)

        #expect(msg.content == "Edited content")
        #expect(msg.isEdited == true)
    }

    @Test @MainActor
    func updateMessageContentRejectsWhitespaceOnly() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()
        context.insert(chat)
        store.selectedChat = chat

        let msg = Message(role: .user, content: "Original")
        msg.chat = chat
        chat.messages.append(msg)

        store.updateMessageContent(messageID: msg.id, newContent: "   \n\t  ", in: context)

        #expect(msg.content == "Original")
        #expect(msg.isEdited == false)
    }

    // MARK: - deleteMessage edge cases

    @Test @MainActor
    func deleteMessageWithUnknownIDIsNoop() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()
        context.insert(chat)
        store.selectedChat = chat

        let msg = Message(role: .user, content: "Keep me")
        msg.chat = chat
        chat.messages.append(msg)

        store.deleteMessage(withID: UUID(), in: context)

        #expect(chat.messages.count == 1)
        #expect(store.errorMessage == nil)
    }

    @Test @MainActor
    func deleteMessageOnEmptyChatIsNoop() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let store = ConversationStore(
            repository: InMemoryChatRepository(),
            engine: EmptyEngine()
        )
        let chat = Chat()
        context.insert(chat)
        store.selectedChat = chat

        store.deleteMessage(withID: UUID(), in: context)

        #expect(chat.messages.isEmpty)
        #expect(store.errorMessage == nil)
    }

    // MARK: - MessageRowViewData

    @Test func messageRowUpdatingContentPreservesAllFields() {
        let msg = Message(
            role: .user,
            content: "Original",
            promptTokens: 10,
            completionTokens: 5,
            cost: 0.001,
            modelID: "openai/gpt-5"
        )
        msg.isEdited = true
        msg.rawRequestJSON = "{\"test\": true}"
        msg.rawResponseJSON = "{\"response\": true}"
        msg.rawUsageJSON = "{\"usage\": true}"

        let row = MessageRowViewData(message: msg)
        let updated = row.updatingContent("Updated content")

        #expect(updated.id == row.id)
        #expect(updated.role == row.role)
        #expect(updated.content == "Updated content")
        #expect(updated.timestamp == row.timestamp)
        #expect(updated.promptTokens == row.promptTokens)
        #expect(updated.completionTokens == row.completionTokens)
        #expect(updated.cost == row.cost)
        #expect(updated.modelID == row.modelID)
        #expect(updated.isEdited == row.isEdited)
        #expect(updated.rawRequestJSON == row.rawRequestJSON)
        #expect(updated.rawResponseJSON == row.rawResponseJSON)
        #expect(updated.rawUsageJSON == row.rawUsageJSON)
    }

    // MARK: - Chat.effectiveXxx defaults

    @Test func effectiveTemperatureDefaultsToOne() {
        let chat = Chat()
        #expect(chat.effectiveTemperature == 1.0)
        chat.temperatureOverride = 0.3
        #expect(chat.effectiveTemperature == 0.3)
    }

    @Test func effectiveReasoningEnabledDefaultsToTrue() {
        let chat = Chat()
        #expect(chat.effectiveReasoningEnabled == true)
        chat.reasoningEnabledOverride = false
        #expect(chat.effectiveReasoningEnabled == false)
    }

    @MainActor
    private func makeInMemoryModelContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: Chat.self,
            Message.self,
            AppSettings.self,
            Character.self,
            CachedModel.self,
            configurations: config
        )
    }
}
