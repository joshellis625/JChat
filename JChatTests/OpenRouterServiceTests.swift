import Foundation
@testable import WhisperQuill
import Testing

@Suite(.serialized)
struct OpenRouterServiceTests {
    @Test
    func requestEncodingIncludesExpectedFields() async throws {
        let session = makeMockSession()
        let attempts = LockedInt(0)
        var capturedBody: [String: Any] = [:]

        MockURLProtocol.requestHandler = { request in
            attempts.increment()
            let data = try self.extractBodyData(from: request)
            capturedBody = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            return (self.makeHTTPResponse(statusCode: 200), self.makeChatCompletionData(text: "Hello"))
        }

        let service = OpenRouterService(
            session: session,
            chatRetryPolicy: RetryPolicy(maxAttempts: 1, baseDelaySeconds: 0, maxDelaySeconds: 0, jitterRatio: 0)
        )

        let params = ChatParameters(
            temperature: 0.7,
            maxTokens: 1500,
            topP: 0.9,
            topK: nil,
            frequencyPenalty: nil,
            presencePenalty: nil,
            repetitionPenalty: nil,
            minP: nil,
            topA: nil,
            reasoningEnabled: true,
            reasoningEffort: "medium",
            reasoningMaxTokens: nil,
            reasoningExclude: nil,
            verbosity: nil
        )

        _ = try await service.sendMessage(
            request: ModelCallRequest(
                messages: [(role: "system", content: "Be helpful"), (role: "user", content: "Hi")],
                modelID: "openai/gpt-5-nano",
                parameters: params,
                apiKey: "test-key",
                stream: false
            )
        )

        #expect(attempts.value == 1)
        #expect(capturedBody["model"] as? String == "openai/gpt-5-nano")
        #expect(capturedBody["stream"] as? Bool == false)
        #expect(capturedBody["temperature"] as? Double == 0.7)
        #expect(capturedBody["max_tokens"] as? Int == 1500)
        #expect(capturedBody["top_p"] as? Double == 0.9)
        #expect(capturedBody["top_k"] == nil)
        #expect(capturedBody["stream_options"] == nil)

        let reasoning = try #require(capturedBody["reasoning"] as? [String: Any])
        #expect(reasoning["enabled"] as? Bool == true)
        #expect(reasoning["effort"] as? String == "medium")
        #expect(reasoning["max_tokens"] == nil)
    }

    @Test
    func anthropicReasoningMutualExclusionOmitsEffortWhenMaxTokensSet() async throws {
        let session = makeMockSession()
        var capturedBody: [String: Any] = [:]

        MockURLProtocol.requestHandler = { request in
            let data = try self.extractBodyData(from: request)
            capturedBody = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
            return (self.makeHTTPResponse(statusCode: 200), self.makeChatCompletionData(text: "Done"))
        }

        let service = OpenRouterService(
            session: session,
            chatRetryPolicy: RetryPolicy(maxAttempts: 1, baseDelaySeconds: 0, maxDelaySeconds: 0, jitterRatio: 0)
        )

        let params = ChatParameters(
            temperature: 1.0,
            maxTokens: 1024,
            topP: 1.0,
            topK: nil,
            frequencyPenalty: nil,
            presencePenalty: nil,
            repetitionPenalty: nil,
            minP: nil,
            topA: nil,
            reasoningEnabled: true,
            reasoningEffort: "high",
            reasoningMaxTokens: 4096,
            reasoningExclude: false,
            verbosity: "high"
        )

        _ = try await service.sendMessage(
            request: ModelCallRequest(
                messages: [(role: "user", content: "Hi")],
                modelID: "anthropic/claude-sonnet-4",
                parameters: params,
                apiKey: "test-key",
                stream: false
            )
        )

        let reasoning = try #require(capturedBody["reasoning"] as? [String: Any])
        #expect(reasoning["max_tokens"] as? Int == 4096)
        #expect(reasoning["effort"] == nil)
    }

    @Test
    func streamParserHandlesKeepaliveMalformedAndUsageChunks() async throws {
        let deltaPayload = #"{"choices":[{"delta":{"content":"Hel"}}],"model":"openai/gpt-5-nano"}"#
        let malformedPayload = #"{"bad_json":"#
        let usagePayload = #"{"usage":{"prompt_tokens":3,"completion_tokens":5},"model":"openai/gpt-5-nano"}"#
        let donePayload = "[DONE]"

        let deltaEvents = OpenRouterService.parseSSEPayloadForTesting(deltaPayload)
        let malformedEvents = OpenRouterService.parseSSEPayloadForTesting(malformedPayload)
        let usageEvents = OpenRouterService.parseSSEPayloadForTesting(usagePayload)
        let doneEvents = OpenRouterService.parseSSEPayloadForTesting(donePayload)

        let combined = deltaEvents + malformedEvents + usageEvents + doneEvents

        var output = ""
        var usage: (Int, Int)?
        var doneSeen = false

        for event in combined {
            switch event {
            case let .delta(text):
                output += text
            case let .usage(prompt, completion, _):
                usage = (prompt, completion)
            case .done:
                doneSeen = true
            case .modelID, .generationID, .finishReason, .error:
                break
            }
        }

        #expect(output == "Hel")
        #expect(usage?.0 == 3)
        #expect(usage?.1 == 5)
        #expect(doneSeen == true)
        #expect(malformedEvents.isEmpty == true)

        let messageContentPayload = #"{"choices":[{"message":{"role":"assistant","content":"World"}}]}"#
        let messageEvents = OpenRouterService.parseSSEPayloadForTesting(messageContentPayload)
        var messageText = ""
        for event in messageEvents {
            if case let .delta(text) = event {
                messageText += text
            }
        }
        #expect(messageText == "World")
    }

    @Test
    func parseSSEPayloadYieldsFinishReason() {
        let payload = #"{"choices":[{"delta":{"content":""},"finish_reason":"length"}],"model":"openai/gpt-5-nano"}"#
        let events = OpenRouterService.parseSSEPayloadForTesting(payload)
        let reasons = events.compactMap { if case let .finishReason(r) = $0 { return r } else { return nil } }
        #expect(reasons == ["length"])
    }

    @Test
    func parseSSEPayloadYieldsGenerationID() {
        let payload = #"{"id":"gen-abc123","choices":[{"delta":{"content":"Hi"}}],"model":"openai/gpt-5-nano"}"#
        let events = OpenRouterService.parseSSEPayloadForTesting(payload)
        let ids = events.compactMap { if case let .generationID(id) = $0 { return id } else { return nil } }
        #expect(ids == ["gen-abc123"])
    }

    @Test
    func parseSSEPayloadContentFilterFinishReason() {
        let payload = #"{"choices":[{"delta":{"content":""},"finish_reason":"content_filter"}],"model":"openai/gpt-5-nano"}"#
        let events = OpenRouterService.parseSSEPayloadForTesting(payload)
        let reasons = events.compactMap { if case let .finishReason(r) = $0 { return r } else { return nil } }
        #expect(reasons == ["content_filter"])
    }

    @Test
    func parseSSEPayloadEmptyFinishReasonIsNotEmitted() {
        let payload = #"{"choices":[{"delta":{"content":"Hi"},"finish_reason":""}],"model":"openai/gpt-5-nano"}"#
        let events = OpenRouterService.parseSSEPayloadForTesting(payload)
        let reasons = events.compactMap { if case let .finishReason(r) = $0 { return r } else { return nil } }
        #expect(reasons.isEmpty)
    }

    @Test
    func parseSSEPayloadErrorEnvelopeYieldsErrorEvent() {
        let payload = #"{"error":{"message":"Model is overloaded"}}"#
        let events = OpenRouterService.parseSSEPayloadForTesting(payload)
        let errors = events.compactMap { if case let .error(e) = $0 { return e } else { return nil } }
        #expect(errors.count == 1)
        if case .streamingError(let msg) = errors.first {
            #expect(msg == "Model is overloaded")
        } else {
            Issue.record("Expected .streamingError")
        }
    }

    @Test
    func parseSSEPayloadErrorWithBlankMessageIsIgnored() {
        let payload = #"{"error":{"message":"   "}}"#
        let events = OpenRouterService.parseSSEPayloadForTesting(payload)
        let errors = events.compactMap { if case let .error(e) = $0 { return e } else { return nil } }
        #expect(errors.isEmpty)
    }

    @Test
    func streamReaderHandlesDataLinesWithoutBlankSeparators() async throws {
        let session = makeMockSession()
        let streamBody = [
            #"data: {"choices":[{"delta":{"content":"Hel"}}],"model":"openai/gpt-5-nano"}"#,
            #"data: {"bad_json":"#,
            #"data: {"choices":[{"delta":{"content":"lo"}}],"model":"openai/gpt-5-nano"}"#,
            #"data: {"usage":{"prompt_tokens":4,"completion_tokens":6},"model":"openai/gpt-5-nano"}"#,
            "data: [DONE]",
        ].joined(separator: "\n")

        MockURLProtocol.requestHandler = { _ in
            (
                self.makeHTTPResponse(statusCode: 200, headers: ["Content-Type": "text/event-stream"]),
                Data(streamBody.utf8)
            )
        }

        let service = OpenRouterService(
            session: session,
            chatRetryPolicy: RetryPolicy(maxAttempts: 1, baseDelaySeconds: 0, maxDelaySeconds: 0, jitterRatio: 0)
        )

        let stream = await service.streamMessage(
            request: ModelCallRequest(
                messages: [(role: "user", content: "No blank line stream")],
                modelID: "openai/gpt-5-nano",
                parameters: ChatParameters(),
                apiKey: "test-key"
            )
        )

        var output = ""
        var usage: (Int, Int)?
        var doneSeen = false

        for try await event in stream {
            switch event {
            case let .delta(text):
                output += text
            case let .usage(prompt, completion, _):
                usage = (prompt, completion)
            case .done:
                doneSeen = true
            case .modelID, .generationID, .finishReason, .error:
                break
            }
        }

        #expect(output == "Hello")
        #expect(usage?.0 == 4)
        #expect(usage?.1 == 6)
        #expect(doneSeen == true)
    }

    @Test
    func retryPolicyRetriesTransientStatusThenSucceeds() async throws {
        let session = makeMockSession()
        let attempts = LockedInt(0)
        let sleeps = SleepSpy()

        MockURLProtocol.requestHandler = { _ in
            let attempt = attempts.increment()
            if attempt < 3 {
                return (
                    self.makeHTTPResponse(statusCode: 503),
                    Data(#"{"error":{"message":"busy"}}"#.utf8)
                )
            }
            return (self.makeHTTPResponse(statusCode: 200), self.makeChatCompletionData(text: "Recovered"))
        }

        let service = OpenRouterService(
            session: session,
            chatRetryPolicy: RetryPolicy(maxAttempts: 3, baseDelaySeconds: 0, maxDelaySeconds: 0, jitterRatio: 0),
            sleep: { nanoseconds in sleeps.record(nanoseconds) },
            randomUnit: { 0.5 }
        )

        let response = try await service.sendMessage(
            request: ModelCallRequest(
                messages: [(role: "user", content: "Retry test")],
                modelID: "openai/gpt-5-nano",
                parameters: ChatParameters(),
                apiKey: "test-key"
            )
        )

        #expect(response.content == "Recovered")
        #expect(attempts.value == 3)
        #expect(sleeps.values.count == 2)
    }

    @Test
    func retryAfterHeaderIsHonoredOverComputedBackoff() async throws {
        let session = makeMockSession()
        let attempts = LockedInt(0)
        let sleeps = SleepSpy()

        MockURLProtocol.requestHandler = { _ in
            let attempt = attempts.increment()
            if attempt == 1 {
                return (
                    self.makeHTTPResponse(statusCode: 429, headers: ["Retry-After": "7"]),
                    Data(#"{"error":{"message":"rate limited"}}"#.utf8)
                )
            }
            return (self.makeHTTPResponse(statusCode: 200), self.makeChatCompletionData(text: "Retried"))
        }

        let service = OpenRouterService(
            session: session,
            chatRetryPolicy: RetryPolicy(maxAttempts: 2, baseDelaySeconds: 0.1, maxDelaySeconds: 10, jitterRatio: 0),
            sleep: { nanoseconds in sleeps.record(nanoseconds) },
            randomUnit: { 0.5 }
        )

        _ = try await service.sendMessage(
            request: ModelCallRequest(
                messages: [(role: "user", content: "Retry-After test")],
                modelID: "openai/gpt-5-nano",
                parameters: ChatParameters(),
                apiKey: "test-key"
            )
        )

        #expect(attempts.value == 2)
        #expect(sleeps.values.first == 7000000000)
    }

    private func makeMockSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makeHTTPResponse(statusCode: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://openrouter.ai/api/v1/chat/completions")!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: headers
        )!
    }

    private func makeChatCompletionData(text: String) -> Data {
        Data(
            """
            {
              "choices": [
                {
                  "message": {
                    "role": "assistant",
                    "content": "\(text)"
                  }
                }
              ],
              "usage": {
                "prompt_tokens": 11,
                "completion_tokens": 7
              },
              "model": "openai/gpt-5-nano"
            }
            """.utf8
        )
    }

    private func extractBodyData(from request: URLRequest) throws -> Data {
        if let body = request.httpBody {
            return body
        }

        guard let stream = request.httpBodyStream else {
            throw URLError(.badServerResponse)
        }

        stream.open()
        defer { stream.close() }

        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)

        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            if read < 0 {
                throw stream.streamError ?? URLError(.cannotDecodeRawData)
            }
            if read == 0 {
                break
            }
            data.append(buffer, count: read)
        }

        return data
    }
}

private final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class LockedInt: @unchecked Sendable {
    private var storage: Int
    private let lock = NSLock()

    init(_ value: Int) {
        storage = value
    }

    @discardableResult
    func increment() -> Int {
        lock.lock()
        defer { lock.unlock() }
        storage += 1
        return storage
    }

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}

private final class SleepSpy: @unchecked Sendable {
    private var storage: [UInt64] = []
    private let lock = NSLock()

    func record(_ value: UInt64) {
        lock.lock()
        storage.append(value)
        lock.unlock()
    }

    var values: [UInt64] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }
}
