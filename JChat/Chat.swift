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

    // Assistant relationship (model-independent roles/system prompts)
    @Relationship(inverse: \Assistant.chats) var assistant: Assistant?

    // Per-chat parameter overrides (nil = use assistant's default)
    var temperatureOverride: Double?
    var topPOverride: Double?
    var topKOverride: Int?
    var maxTokensOverride: Int?
    var frequencyPenaltyOverride: Double?
    var presencePenaltyOverride: Double?
    var repetitionPenaltyOverride: Double?
    var minPOverride: Double?
    var topAOverride: Double?

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

    // Effective parameter resolution: chat override → assistant default → fallback
    var effectiveTemperature: Double { temperatureOverride ?? assistant?.temperature ?? 0.7 }
    var effectiveTopP: Double { topPOverride ?? assistant?.topP ?? 1.0 }
    var effectiveTopK: Int { topKOverride ?? assistant?.topK ?? 0 }
    var effectiveMaxTokens: Int { maxTokensOverride ?? assistant?.maxTokens ?? 4096 }
    var effectiveFrequencyPenalty: Double { frequencyPenaltyOverride ?? assistant?.frequencyPenalty ?? 0.0 }
    var effectivePresencePenalty: Double { presencePenaltyOverride ?? assistant?.presencePenalty ?? 0.0 }
    var effectiveRepetitionPenalty: Double { repetitionPenaltyOverride ?? assistant?.repetitionPenalty ?? 1.0 }
    var effectiveMinP: Double { minPOverride ?? assistant?.minP ?? 0.0 }
    var effectiveTopA: Double { topAOverride ?? assistant?.topA ?? 0.0 }
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
