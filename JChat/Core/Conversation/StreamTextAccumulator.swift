//
//  StreamTextAccumulator.swift
//  JChat
//

import Foundation

struct StreamTextAccumulator {
    private(set) var pending = ""
    private var lastFlushTime = ContinuousClock.now
    private let minCharactersBeforeFlush: Int
    private let maxInterval: Duration

    init(
        minCharactersBeforeFlush: Int = ConversationFeatureFlags.streamFlushMinimumCharacters,
        maxIntervalMilliseconds: Int = ConversationFeatureFlags.streamFlushIntervalMilliseconds
    ) {
        self.minCharactersBeforeFlush = max(1, minCharactersBeforeFlush)
        self.maxInterval = .milliseconds(max(1, maxIntervalMilliseconds))
    }

    mutating func append(_ chunk: String) -> String? {
        guard !chunk.isEmpty else { return nil }
        pending += chunk

        let now = ContinuousClock.now
        let shouldFlushForSize = pending.count >= minCharactersBeforeFlush
        let shouldFlushForTime = now - lastFlushTime >= maxInterval

        if shouldFlushForSize || shouldFlushForTime {
            return flush(now: now)
        }
        return nil
    }

    mutating func flush() -> String? {
        flush(now: ContinuousClock.now)
    }

    mutating func reset() {
        pending = ""
        lastFlushTime = ContinuousClock.now
    }

    private mutating func flush(now: ContinuousClock.Instant) -> String? {
        guard !pending.isEmpty else {
            lastFlushTime = now
            return nil
        }

        let output = pending
        pending = ""
        lastFlushTime = now
        return output
    }
}
