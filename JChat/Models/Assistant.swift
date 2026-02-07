//
//  Assistant.swift
//  JChat
//

import Foundation
import SwiftData

@Model
final class Assistant {
    @Attribute(.unique) var id: UUID
    var name: String
    var systemPrompt: String
    var temperature: Double
    var topP: Double
    var topK: Int
    var maxTokens: Int
    var frequencyPenalty: Double
    var presencePenalty: Double
    var repetitionPenalty: Double
    var minP: Double
    var topA: Double
    var isDefault: Bool
    var createdAt: Date
    @Relationship(deleteRule: .nullify) var chats: [Chat] = []

    init(
        name: String = "General Assistant",
        systemPrompt: String = "",
        temperature: Double = 0.7,
        topP: Double = 1.0,
        topK: Int = 0,
        maxTokens: Int = 4096,
        frequencyPenalty: Double = 0.0,
        presencePenalty: Double = 0.0,
        repetitionPenalty: Double = 1.0,
        minP: Double = 0.0,
        topA: Double = 0.0,
        isDefault: Bool = false
    ) {
        self.id = UUID()
        self.name = name
        self.systemPrompt = systemPrompt
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.maxTokens = maxTokens
        self.frequencyPenalty = frequencyPenalty
        self.presencePenalty = presencePenalty
        self.repetitionPenalty = repetitionPenalty
        self.minP = minP
        self.topA = topA
        self.isDefault = isDefault
        self.createdAt = Date()
    }

    static func createDefault(in context: ModelContext) -> Assistant {
        let descriptor = FetchDescriptor<Assistant>(predicate: #Predicate { $0.isDefault == true })
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let assistant = Assistant(name: "General Assistant", isDefault: true)
        context.insert(assistant)
        try? context.save()
        return assistant
    }
}
