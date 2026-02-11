//
//  JChatTests.swift
//  JChatTests
//
//  Created by Josh Ellis on 1/31/26.
//

import Testing
import SwiftData
@testable import JChat

struct JChatTests {

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
        source.streamOverride = false
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
        #expect(target.streamOverride == false)
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
        chat.streamOverride = true
        chat.verbosityOverride = "low"

        #expect(chat.overrideCount == 4)

        chat.resetAllOverrides()

        #expect(chat.temperatureOverride == nil)
        #expect(chat.topKOverride == nil)
        #expect(chat.streamOverride == nil)
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

    @Test @MainActor
    func deletingUserMessageDoesNotReduceChatTotals() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let viewModel = ChatViewModel()
        let chat = Chat()

        context.insert(chat)
        viewModel.selectedChat = chat

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

        viewModel.deleteMessage(userMessage, in: context)

        #expect(chat.totalPromptTokens == originalPrompt)
        #expect(chat.totalCompletionTokens == originalCompletion)
        #expect(chat.totalCost == originalCost)
        #expect(!chat.messages.contains(where: { $0.id == deletedID }))
    }

    @Test @MainActor
    func deletingAssistantMessageDoesNotReduceChatTotals() throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let viewModel = ChatViewModel()
        let chat = Chat()

        context.insert(chat)
        viewModel.selectedChat = chat

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

        viewModel.deleteMessage(assistantMessage, in: context)

        #expect(chat.totalPromptTokens == originalPrompt)
        #expect(chat.totalCompletionTokens == originalCompletion)
        #expect(chat.totalCost == originalCost)
        #expect(!chat.messages.contains(where: { $0.id == deletedID }))
    }

    @Test @MainActor
    func regeneratingAssistantMessageDoesNotRefundPriorUsage() async throws {
        let container = try makeInMemoryModelContainer()
        let context = container.mainContext
        let viewModel = ChatViewModel()
        let chat = Chat()

        context.insert(chat)
        viewModel.selectedChat = chat
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

        await viewModel.regenerateMessage(assistantMessage, in: context)

        #expect(chat.totalPromptTokens == originalPrompt)
        #expect(chat.totalCompletionTokens == originalCompletion)
        #expect(chat.totalCost == originalCost)
        #expect(!chat.messages.contains(where: { $0.id == regeneratedID }))
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
