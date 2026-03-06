//
//  ConversationFeatureFlags.swift
//  JChat
//

import Foundation

enum ConversationFeatureFlags {
    // Stage-gate for the rebuilt conversation pipeline. Keep false until migration is complete.
    static let useRebuiltConversationStore = false

    // Streaming UI update controls to reduce layout churn during fast token streams.
    // 32 chars: large enough to batch micro-deltas from fast models, small enough
    // that the user sees words appearing smoothly rather than in large jumps.
    static let streamFlushMinimumCharacters = 32
    // 45 ms: ~22 fps ceiling for text redraws; keeps CPU usage low while still
    // feeling instant. Lower values increase layout pressure with no perceptible benefit.
    static let streamFlushIntervalMilliseconds = 45
}
