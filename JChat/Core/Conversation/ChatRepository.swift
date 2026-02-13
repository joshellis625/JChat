//
//  ChatRepository.swift
//  JChat
//

import Foundation
import SwiftData

@MainActor
protocol ChatRepositoryProtocol {
    func createNewChat(in context: ModelContext) throws -> Chat
    func deleteChat(_ chat: Chat, in context: ModelContext) throws
    func deleteMessage(_ message: Message, in context: ModelContext) throws
    func save(context: ModelContext) throws
}

struct SwiftDataChatRepository: ChatRepositoryProtocol {
    func createNewChat(in context: ModelContext) throws -> Chat {
        let chat = Chat()

        // Inherit parameters from the most recent chat so control choices carry forward.
        let chatDescriptor = FetchDescriptor<Chat>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        if let mostRecent = try context.fetch(chatDescriptor).first {
            chat.inheritParameters(from: mostRecent)
        }

        // Assign default character if one is configured.
        let settingsDescriptor = FetchDescriptor<AppSettings>()
        if let settings = try context.fetch(settingsDescriptor).first,
           let defaultCharacterID = settings.defaultCharacterID {
            let characterDescriptor = FetchDescriptor<Character>(predicate: #Predicate { $0.id == defaultCharacterID })
            chat.character = try context.fetch(characterDescriptor).first
        }

        // Fall back to whichever character is flagged default.
        if chat.character == nil {
            let defaultDescriptor = FetchDescriptor<Character>(predicate: #Predicate { $0.isDefault == true })
            chat.character = try context.fetch(defaultDescriptor).first
        }

        // Set default model: character preferred -> global default.
        if let preferredModel = chat.character?.preferredModelID,
           !preferredModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let modelDescriptor = FetchDescriptor<CachedModel>(predicate: #Predicate { $0.id == preferredModel })
            if try context.fetch(modelDescriptor).first != nil {
                chat.selectedModelID = preferredModel
            }
        }

        if chat.selectedModelID == nil {
            let settings = try context.fetch(settingsDescriptor).first
            if let defaultModel = settings?.defaultModelID {
                chat.selectedModelID = defaultModel
            }
        }

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
