//
//  StreamTextAccumulator.swift
//  JChat
//

import Foundation

struct StreamTextAccumulator {
    private(set) var bufferedText = ""
    private var lastFlushTime = ContinuousClock.now
    private let minCharactersBeforeFlush: Int
    private let maxInterval: Duration

    init(
        minCharactersBeforeFlush: Int = ConversationFeatureFlags.streamFlushMinimumCharacters,
        maxIntervalMilliseconds: Int = ConversationFeatureFlags.streamFlushIntervalMilliseconds
    ) {
        self.minCharactersBeforeFlush = max(1, minCharactersBeforeFlush)
        maxInterval = .milliseconds(max(1, maxIntervalMilliseconds))
    }

    mutating func append(_ chunk: String) -> String? {
        guard !chunk.isEmpty else { return nil }
        bufferedText += chunk

        let now = ContinuousClock.now
        let shouldFlushForSize = bufferedText.count >= minCharactersBeforeFlush
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
        bufferedText = ""
        lastFlushTime = ContinuousClock.now
    }

    private mutating func flush(now: ContinuousClock.Instant) -> String? {
        guard !bufferedText.isEmpty else {
            lastFlushTime = now
            return nil
        }

        let output = bufferedText
        bufferedText = ""
        lastFlushTime = now
        return output
    }
}
