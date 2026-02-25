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

    // Reasoning + Verbosity overrides
    var reasoningEnabledOverride: Bool?
    var reasoningEffortOverride: String?
    var reasoningMaxTokensOverride: Int?
    var reasoningExcludeOverride: Bool?
    var verbosityOverride: String?

    init(title: String = "New Chat") {
        id = UUID()
        self.title = title
        createdAt = Date()
        totalPromptTokens = 0
        totalCompletionTokens = 0
        totalCost = 0.0
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
    var effectiveMaxTokens: Int { maxTokensOverride ?? 0 } // 0 = unlimited (Off)
    var effectiveFrequencyPenalty: Double { frequencyPenaltyOverride ?? 0.0 }
    var effectivePresencePenalty: Double { presencePenaltyOverride ?? 0.0 }
    var effectiveRepetitionPenalty: Double { repetitionPenaltyOverride ?? 1.0 }
    var effectiveMinP: Double { minPOverride ?? 0.0 }
    var effectiveTopA: Double { topAOverride ?? 0.0 }

    // Reasoning + Verbosity
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
        reasoningEnabledOverride = nil
        reasoningEffortOverride = nil
        reasoningMaxTokensOverride = nil
        reasoningExcludeOverride = nil
        verbosityOverride = nil
    }

    // MARK: - Overrides Summary

    var overrideCount: Int {
        var count = 0
        if temperatureOverride != nil { count += 1 }
        if topPOverride != nil { count += 1 }
        if topKOverride != nil { count += 1 }
        if maxTokensOverride != nil { count += 1 }
        if frequencyPenaltyOverride != nil { count += 1 }
        if presencePenaltyOverride != nil { count += 1 }
        if repetitionPenaltyOverride != nil { count += 1 }
        if minPOverride != nil { count += 1 }
        if topAOverride != nil { count += 1 }
        if reasoningEnabledOverride != nil { count += 1 }
        if reasoningEffortOverride != nil { count += 1 }
        if reasoningMaxTokensOverride != nil { count += 1 }
        if reasoningExcludeOverride != nil { count += 1 }
        if verbosityOverride != nil { count += 1 }
        return count
    }

    /// Count of overrides that differ from their default values.
    /// Used for the badge on the parameter inspector button.
    var activeOverrideCount: Int {
        var count = 0
        if let v = temperatureOverride, v != 1.0 { count += 1 }
        if let v = topPOverride, v != 1.0 { count += 1 }
        if let v = topKOverride, v != 0 { count += 1 }
        if let v = maxTokensOverride, v != 0 { count += 1 }
        if let v = frequencyPenaltyOverride, v != 0.0 { count += 1 }
        if let v = presencePenaltyOverride, v != 0.0 { count += 1 }
        if let v = repetitionPenaltyOverride, v != 1.0 { count += 1 }
        if let v = minPOverride, v != 0.0 { count += 1 }
        if let v = topAOverride, v != 0.0 { count += 1 }
        if let v = reasoningEnabledOverride, v != true { count += 1 }
        if let v = reasoningEffortOverride, v != "medium" { count += 1 }
        if let v = reasoningMaxTokensOverride, v != 0 { count += 1 }
        if let v = reasoningExcludeOverride, v != false { count += 1 }
        if let v = verbosityOverride, v != "medium" { count += 1 }
        return count
    }

    // MARK: - Usage Totals

    func addUsage(promptTokens: Int, completionTokens: Int, cost: Double) {
        totalPromptTokens += promptTokens
        totalCompletionTokens += completionTokens
        totalCost += cost
    }

    func removeUsage(promptTokens: Int, completionTokens: Int, cost: Double) {
        totalPromptTokens = max(0, totalPromptTokens - promptTokens)
        totalCompletionTokens = max(0, totalCompletionTokens - completionTokens)
        totalCost = max(0, totalCost - cost)
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
    var rawRequestJSON: String?   // prettified POST body captured at send time (user messages)
    var rawResponseJSON: String?  // assistant content response JSON (assistant messages)
    var rawUsageJSON: String?     // final streaming usage chunk from OpenRouter (assistant messages)
    @Relationship(inverse: \Chat.messages) var chat: Chat?

    init(
        role: MessageRole,
        content: String,
        promptTokens: Int = 0,
        completionTokens: Int = 0,
        cost: Double = 0.0,
        modelID: String? = nil
    ) {
        id = UUID()
        self.role = role
        self.content = content
        timestamp = Date()
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.cost = cost
        self.modelID = modelID
        isEdited = false
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
