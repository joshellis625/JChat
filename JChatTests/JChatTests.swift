//
//  JChatTests.swift
//  JChatTests
//
//  Created by Josh Ellis on 1/31/26.
//

import Testing
@testable import JChat

struct JChatTests {

    @Test func chatTotalsIncludePromptAndCompletion() {
        let chat = Chat()
        chat.totalPromptTokens = 120
        chat.totalCompletionTokens = 80

        #expect(chat.totalTokens == 200)
    }

    @Test func inheritCopiesAllOverrides() {
        let source = Chat()
        source.temperatureOverride = 0.5
        source.topPOverride = 0.9
        source.topKOverride = 40
        source.maxTokensOverride = 2000
        source.streamOverride = false
        source.reasoningEnabledOverride = true
        source.reasoningEffortOverride = "high"
        source.reasoningMaxTokensOverride = 4096
        source.reasoningExcludeOverride = true
        source.verbosityOverride = "high"

        let target = Chat()
        target.inheritParameters(from: source)

        #expect(target.temperatureOverride == 0.5)
        #expect(target.topPOverride == 0.9)
        #expect(target.topKOverride == 40)
        #expect(target.maxTokensOverride == 2000)
        #expect(target.streamOverride == false)
        #expect(target.reasoningEnabledOverride == true)
        #expect(target.reasoningEffortOverride == "high")
        #expect(target.reasoningMaxTokensOverride == 4096)
        #expect(target.reasoningExcludeOverride == true)
        #expect(target.verbosityOverride == "high")
    }

    @Test func resetAllOverridesClearsValuesAndCount() {
        let chat = Chat()
        chat.temperatureOverride = 1.2
        chat.topKOverride = 50
        chat.streamOverride = true
        chat.verbosityOverride = "low"

        #expect(chat.overrideCount == 4)

        chat.resetAllOverrides()

        #expect(chat.temperatureOverride == nil)
        #expect(chat.topKOverride == nil)
        #expect(chat.streamOverride == nil)
        #expect(chat.verbosityOverride == nil)
        #expect(chat.overrideCount == 0)
    }

}
