//
//  ConversationFeatureFlags.swift
//  JChat
//

import Foundation

enum ConversationFeatureFlags {
    // Stage-gate for the rebuilt conversation pipeline. Keep false until migration is complete.
    static let useRebuiltConversationStore = false

    // Streaming UI update controls to reduce layout churn during fast token streams.
    static let streamFlushMinimumCharacters = 32
    static let streamFlushIntervalMilliseconds = 45
}
