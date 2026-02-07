//
//  Chat.swift
//  JChat
//

import Foundation
import SwiftData

@Model
final class Chat {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade) var messages: [Message] = []
    var totalPromptTokens: Int
    var totalCompletionTokens: Int
    var totalCost: Double

    // Model selection for this chat
    var selectedModelID: String?

    // Character relationship (identity: name, system prompt, preferred model)
    @Relationship(inverse: \Character.chats) var character: Character?

    // Per-chat parameter overrides (nil = use global default)
    var temperatureOverride: Double?
    var topPOverride: Double?
    var topKOverride: Int?
    var maxTokensOverride: Int?
    var frequencyPenaltyOverride: Double?
    var presencePenaltyOverride: Double?
    var repetitionPenaltyOverride: Double?
    var minPOverride: Double?
    var topAOverride: Double?

    // Stream + Reasoning + Verbosity overrides
    var streamOverride: Bool?
    var reasoningEnabledOverride: Bool?
    var reasoningEffortOverride: String?
    var reasoningMaxTokensOverride: Int?
    var reasoningExcludeOverride: Bool?
    var verbosityOverride: String?

    init(title: String = "New Chat") {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
        self.totalPromptTokens = 0
        self.totalCompletionTokens = 0
        self.totalCost = 0.0
    }

    var totalTokens: Int {
        totalPromptTokens + totalCompletionTokens
    }

    var sortedMessages: [Message] {
        messages.sorted { $0.timestamp < $1.timestamp }
    }

    // MARK: - Effective Parameter Resolution (chat override → global default)

    var effectiveTemperature: Double { temperatureOverride ?? 1.0 }
    var effectiveTopP: Double { topPOverride ?? 1.0 }
    var effectiveTopK: Int { topKOverride ?? 0 }
    var effectiveMaxTokens: Int { maxTokensOverride ?? 4096 }
    var effectiveFrequencyPenalty: Double { frequencyPenaltyOverride ?? 0.0 }
    var effectivePresencePenalty: Double { presencePenaltyOverride ?? 0.0 }
    var effectiveRepetitionPenalty: Double { repetitionPenaltyOverride ?? 1.0 }
    var effectiveMinP: Double { minPOverride ?? 0.0 }
    var effectiveTopA: Double { topAOverride ?? 0.0 }

    // Stream + Reasoning + Verbosity
    var effectiveStream: Bool { streamOverride ?? true }
    var effectiveReasoningEnabled: Bool { reasoningEnabledOverride ?? true }
    var effectiveReasoningEffort: String { reasoningEffortOverride ?? "medium" }
    var effectiveReasoningMaxTokens: Int? { reasoningMaxTokensOverride }
    var effectiveReasoningExclude: Bool? { reasoningExcludeOverride }
    var effectiveVerbosity: String? { verbosityOverride }

    // MARK: - Parameter Inheritance

    /// Copy all parameter overrides from another chat (for new chat inheritance)
    func inheritParameters(from source: Chat) {
        temperatureOverride = source.temperatureOverride
        topPOverride = source.topPOverride
        topKOverride = source.topKOverride
        maxTokensOverride = source.maxTokensOverride
        frequencyPenaltyOverride = source.frequencyPenaltyOverride
        presencePenaltyOverride = source.presencePenaltyOverride
        repetitionPenaltyOverride = source.repetitionPenaltyOverride
        minPOverride = source.minPOverride
        topAOverride = source.topAOverride
        streamOverride = source.streamOverride
        reasoningEnabledOverride = source.reasoningEnabledOverride
        reasoningEffortOverride = source.reasoningEffortOverride
        reasoningMaxTokensOverride = source.reasoningMaxTokensOverride
        reasoningExcludeOverride = source.reasoningExcludeOverride
        verbosityOverride = source.verbosityOverride
    }

    /// Reset all parameter overrides to nil (use global defaults)
    func resetAllOverrides() {
        temperatureOverride = nil
        topPOverride = nil
        topKOverride = nil
        maxTokensOverride = nil
        frequencyPenaltyOverride = nil
        presencePenaltyOverride = nil
        repetitionPenaltyOverride = nil
        minPOverride = nil
        topAOverride = nil
        streamOverride = nil
        reasoningEnabledOverride = nil
        reasoningEffortOverride = nil
        reasoningMaxTokensOverride = nil
        reasoningExcludeOverride = nil
        verbosityOverride = nil
    }
}

@Model
final class Message {
    @Attribute(.unique) var id: UUID
    var role: MessageRole
    var content: String
    var timestamp: Date
    var promptTokens: Int
    var completionTokens: Int
    var cost: Double
    var modelID: String?
    var isEdited: Bool
    @Relationship(inverse: \Chat.messages) var chat: Chat?

    init(
        role: MessageRole,
        content: String,
        promptTokens: Int = 0,
        completionTokens: Int = 0,
        cost: Double = 0.0,
        modelID: String? = nil
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.cost = cost
        self.modelID = modelID
        self.isEdited = false
    }

    var totalTokens: Int {
        promptTokens + completionTokens
    }
}

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}
