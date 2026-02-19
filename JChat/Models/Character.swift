//
//  Character.swift
//  JChat
//

import Foundation
import SwiftData

@Model
final class Character {
    @Attribute(.unique) var id: UUID
    var name: String
    var systemPrompt: String
    var preferredModelID: String?
    var isDefault: Bool
    var createdAt: Date
    @Relationship(deleteRule: .nullify) var chats: [Chat] = []

    init(
        name: String = "Default Character",
        systemPrompt: String = "",
        preferredModelID: String? = nil,
        isDefault: Bool = false
    ) {
        id = UUID()
        self.name = name
        self.systemPrompt = systemPrompt
        self.preferredModelID = preferredModelID
        self.isDefault = isDefault
        createdAt = Date()
    }

    static func createDefault(in context: ModelContext) -> Character {
        let descriptor = FetchDescriptor<Character>(predicate: #Predicate { $0.isDefault == true })
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let character = Character(name: "Default Character", isDefault: true)
        context.insert(character)
        try? context.save()
        return character
    }
}
