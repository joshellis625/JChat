//
//  MessageRowViewData.swift
//  JChat
//

import Foundation

struct MessageRowViewData: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let promptTokens: Int
    let completionTokens: Int
    let cost: Double
    let modelID: String?
    let isEdited: Bool
    let rawRequestJSON: String?
    let rawResponseJSON: String?
    let rawUsageJSON: String?

    init(
        id: UUID,
        role: MessageRole,
        content: String,
        timestamp: Date,
        promptTokens: Int,
        completionTokens: Int,
        cost: Double,
        modelID: String?,
        isEdited: Bool,
        rawRequestJSON: String?,
        rawResponseJSON: String?,
        rawUsageJSON: String?
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.cost = cost
        self.modelID = modelID
        self.isEdited = isEdited
        self.rawRequestJSON = rawRequestJSON
        self.rawResponseJSON = rawResponseJSON
        self.rawUsageJSON = rawUsageJSON
    }

    init(message: Message) {
        self.init(
            id: message.id,
            role: message.role,
            content: message.content,
            timestamp: message.timestamp,
            promptTokens: message.promptTokens,
            completionTokens: message.completionTokens,
            cost: message.cost,
            modelID: message.modelID,
            isEdited: message.isEdited,
            rawRequestJSON: message.rawRequestJSON,
            rawResponseJSON: message.rawResponseJSON,
            rawUsageJSON: message.rawUsageJSON
        )
    }

    func updatingContent(_ newContent: String) -> MessageRowViewData {
        MessageRowViewData(
            id: id,
            role: role,
            content: newContent,
            timestamp: timestamp,
            promptTokens: promptTokens,
            completionTokens: completionTokens,
            cost: cost,
            modelID: modelID,
            isEdited: isEdited,
            rawRequestJSON: rawRequestJSON,
            rawResponseJSON: rawResponseJSON,
            rawUsageJSON: rawUsageJSON
        )
    }
}
