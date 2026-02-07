//
//  AppSettings.swift
//  JChat
//

import Foundation
import SwiftData

@Model
final class AppSettings {
    @Attribute(.unique) var id: UUID
    var defaultCharacterID: UUID?
    var defaultModelID: String?
    var modelCacheMaxAge: TimeInterval
    var lastModelFetchDate: Date?
    var textSizeMultiplier: Double

    init() {
        self.id = UUID()
        self.modelCacheMaxAge = 86400 // 24 hours
        self.textSizeMultiplier = 1.0
    }

    static func fetchOrCreate(in context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }
}
