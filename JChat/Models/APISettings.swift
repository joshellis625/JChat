//
//  APISettings.swift
//  JChat
//

import Foundation
import SwiftData

@Model
final class APISettings {
    @Attribute(.unique) var id: UUID
    var selectedModel: String
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double
    
    // Transient property - not stored in SwiftData, backed by Keychain
    @Transient var apiKey: String {
        get {
            guard let key = try? KeychainManager.shared.loadAPIKey() else {
                return ""
            }
            return key
        }
        set {
            if newValue.isEmpty {
                try? KeychainManager.shared.deleteAPIKey()
            } else {
                try? KeychainManager.shared.saveAPIKey(newValue)
            }
        }
    }
    
    init() {
        self.id = UUID()
        self.selectedModel = "anthropic/claude-3.5-sonnet"
        self.temperature = 0.7
        self.maxTokens = 4096
        self.topP = 1.0
        self.frequencyPenalty = 0.0
        self.presencePenalty = 0.0
    }
    
    static func fetchOrCreate(in context: ModelContext) -> APISettings {
        let descriptor = FetchDescriptor<APISettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let newSettings = APISettings()
        context.insert(newSettings)
        try? context.save()
        return newSettings
    }
}
