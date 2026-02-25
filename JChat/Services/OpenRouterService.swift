//
//  OpenRouterService.swift
//  JChat
//

import Foundation

nonisolated struct ChatParameters: Sendable {
    var temperature: Double? = nil // nil = use default (1.0); omitted from API when nil
    var maxTokens: Int? = nil // nil = unlimited (omitted from API)
    var topP: Double? = nil // nil = use default (1.0); omitted from API when nil
    var topK: Int? = nil
    var frequencyPenalty: Double? = nil
    var presencePenalty: Double? = nil
    var repetitionPenalty: Double? = nil
    var minP: Double? = nil
    var topA: Double? = nil

    // Reasoning + Verbosity
    var reasoningEnabled: Bool = true
    var reasoningEffort: String = "medium"
    var reasoningMaxTokens: Int? = nil
    var reasoningExclude: Bool? = nil
    var verbosity: String? = nil // nil = omitted from API (OpenRouter default)
}

nonisolated struct ModelCallRequest: Sendable {
    var messages: [(role: String, content: String)]
    var modelID: String
    var parameters: ChatParameters
    var apiKey: String
    var stream: Bool

    init(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String,
        stream: Bool = true
    ) {
        self.messages = messages
        self.modelID = modelID
        self.parameters = parameters
        self.apiKey = apiKey
        self.stream = stream
    }

    func withStream(_ stream: Bool) -> ModelCallRequest {
        ModelCallRequest(
            messages: messages,
            modelID: modelID,
            parameters: parameters,
            apiKey: apiKey,
            stream: stream
        )
    }
}

nonisolated struct RetryPolicy: Sendable {
    var maxAttempts: Int
    var baseDelaySeconds: TimeInterval
    var maxDelaySeconds: TimeInterval
    var jitterRatio: Double
    var retryableStatusCodes: Set<Int>

    init(
        maxAttempts: Int = 3,
        baseDelaySeconds: TimeInterval = 0.5,
        maxDelaySeconds: TimeInterval = 8.0,
        jitterRatio: Double = 0.25,
        retryableStatusCodes: Set<Int> = [429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.baseDelaySeconds = max(0, baseDelaySeconds)
        self.maxDelaySeconds = max(0, maxDelaySeconds)
        self.jitterRatio = max(0, jitterRatio)
        self.retryableStatusCodes = retryableStatusCodes
    }

    static let chatDefault = RetryPolicy()
}

nonisolated struct ChatCompletionResult: Sendable {
    let content: String
    let promptTokens: Int
    let completionTokens: Int
    let modelID: String
}

/// Events emitted by the OpenRouter SSE stream as chunks arrive.
/// Each chunk from the API may produce one or more of these events.
nonisolated enum StreamEvent: Sendable {
    case delta(String)                                                  // A piece of the assistant's response text
    case usage(promptTokens: Int, completionTokens: Int, rawJSON: String) // Token counts (arrives once, near end of stream)
    case modelID(String)                                                // Which model actually served the request
    case generationID(String)                                           // OpenRouter's unique ID for this generation (e.g. "gen-abc123")
    case finishReason(String)                                           // Why the model stopped: "stop", "length", "content_filter", "tool_calls", or "error"
    case done                                                           // The [DONE] sentinel — stream is complete
    case error(JChatError)                                              // A mid-stream error from the provider
}

actor OpenRouterService {
    static let shared = OpenRouterService()

    private let baseURL: String
    private let session: URLSession
    private let chatRetryPolicy: RetryPolicy
    private let sleep: @Sendable (UInt64) async throws -> Void
    private let randomUnit: @Sendable () -> Double

    init(
        baseURL: String = "https://openrouter.ai/api/v1",
        session: URLSession = .shared,
        chatRetryPolicy: RetryPolicy = .chatDefault,
        sleep: @escaping @Sendable (UInt64) async throws -> Void = { try await Task.sleep(nanoseconds: $0) },
        randomUnit: @escaping @Sendable () -> Double = { Double.random(in: 0.0 ... 1.0) }
    ) {
        self.baseURL = baseURL
        self.session = session
        self.chatRetryPolicy = chatRetryPolicy
        self.sleep = sleep
        self.randomUnit = randomUnit
    }

    // MARK: - API Types

    struct ChatMessage: Codable, Sendable {
        let role: String
        let content: String
    }

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [ChatMessage]
        let stream: Bool
        var temperature: Double?
        var max_tokens: Int?
        var top_p: Double?
        var top_k: Int?
        var frequency_penalty: Double?
        var presence_penalty: Double?
        var repetition_penalty: Double?
        var min_p: Double?
        var top_a: Double?
        var stream_options: StreamOptions?
        var reasoning: ReasoningPayload?
        var verbosity: String?
    }

    private struct StreamOptions: Encodable {
        var include_usage: Bool = true
    }

    private struct ReasoningPayload: Encodable {
        var enabled: Bool?
        var effort: String?
        var max_tokens: Int?
        var exclude: Bool?
    }

    struct ChatResponse: Codable, Sendable {
        let id: String?
        let choices: [Choice]
        let usage: Usage?
        let model: String?
    }

    struct Choice: Codable, Sendable {
        let message: ChatMessage?
        let delta: Delta?
        let finish_reason: String?
    }

    struct Delta: Codable, Sendable {
        let content: String?
        let role: String?
    }

    struct Usage: Codable, Sendable {
        let prompt_tokens: Int?
        let completion_tokens: Int?
        let total_tokens: Int?
    }

    private struct StreamChunk: Codable, Sendable {
        let id: String?
        let choices: [Choice]?
        let usage: Usage?
        let model: String?
    }

    private struct APIErrorEnvelope: Decodable {
        struct APIErrorBody: Decodable {
            let message: String?
        }

        let error: APIErrorBody?
    }

    // MARK: - Models API Types

    struct OpenRouterModel: Codable, Sendable {
        let id: String
        let name: String
        let description: String?
        let context_length: Int?
        let pricing: OpenRouterPricing?
        let top_provider: TopProvider?
        let architecture: Architecture?

        struct OpenRouterPricing: Codable, Sendable {
            let prompt: String?
            let completion: String?
            let image: String?
            let request: String?
        }

        struct TopProvider: Codable, Sendable {
            let context_length: Int?
            let max_completion_tokens: Int?
            let is_moderated: Bool?
        }

        struct Architecture: Codable, Sendable {
            let tokenizer: String?
            let instruct_type: String?
            let modality: String?
            let input_modalities: [String]?
            let output_modalities: [String]?
        }
    }

    struct ModelsResponse: Codable, Sendable {
        let data: [OpenRouterModel]
    }

    // MARK: - Credits API Types

    struct CreditsResponse: Codable, Sendable {
        let data: CreditsData

        struct CreditsData: Codable, Sendable {
            let total_credits: Double?
            let total_usage: Double?
        }
    }

    // MARK: - Model Fetching

    func fetchModels(apiKey: String) async throws -> [OpenRouterModel] {
        guard let url = URL(string: "\(baseURL)/models") else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("JChat/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JChat", forHTTPHeaderField: "X-Title")

        let (data, httpResponse) = try await performDataRequest(request: request, retryPolicy: nil)
        try throwIfNotSuccess(httpResponse: httpResponse, data: data)
        let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return modelsResponse.data
    }

    // MARK: - Key Validation & Credits

    struct KeyValidationDiagnostics: Sendable {
        let endpoint: String
        let statusCode: Int
        let errorBody: String?
        let modelsCount: Int?
        let isValid: Bool
    }

    func validateAPIKeyWithDiagnostics(apiKey: String) async -> KeyValidationDiagnostics {
        let endpoint = "\(baseURL)/models"
        guard let url = URL(string: endpoint) else {
            return KeyValidationDiagnostics(endpoint: endpoint, statusCode: 0, errorBody: "Invalid URL", modelsCount: nil, isValid: false)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("JChat/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JChat", forHTTPHeaderField: "X-Title")

        do {
            let (data, httpResponse) = try await performDataRequest(request: request, retryPolicy: nil)
            if httpResponse.statusCode == 200 {
                let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
                return KeyValidationDiagnostics(
                    endpoint: endpoint,
                    statusCode: httpResponse.statusCode,
                    errorBody: nil,
                    modelsCount: modelsResponse.data.count,
                    isValid: true
                )
            }

            let message = Self.errorMessage(from: data)
            return KeyValidationDiagnostics(
                endpoint: endpoint,
                statusCode: httpResponse.statusCode,
                errorBody: message,
                modelsCount: nil,
                isValid: false
            )
        } catch {
            return KeyValidationDiagnostics(
                endpoint: endpoint,
                statusCode: 0,
                errorBody: error.localizedDescription,
                modelsCount: nil,
                isValid: false
            )
        }
    }

    func fetchCredits(apiKey: String) async throws -> CreditsResponse {
        guard let url = URL(string: "\(baseURL)/credits") else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("JChat/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JChat", forHTTPHeaderField: "X-Title")

        let (data, httpResponse) = try await performDataRequest(request: request, retryPolicy: nil)
        try throwIfNotSuccess(httpResponse: httpResponse, data: data)
        return try JSONDecoder().decode(CreditsResponse.self, from: data)
    }

    // MARK: - Non-Streaming Message Send

    func sendMessage(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String
    ) async throws -> ChatCompletionResult {
        let request = ModelCallRequest(
            messages: messages,
            modelID: modelID,
            parameters: parameters,
            apiKey: apiKey,
            stream: false
        )
        return try await sendMessage(request: request)
    }

    func sendMessage(request: ModelCallRequest) async throws -> ChatCompletionResult {
        let (data, httpResponse) = try await performChatRequest(request: request.withStream(false))
        try throwIfNotSuccess(httpResponse: httpResponse, data: data)

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let choice = chatResponse.choices.first, let message = choice.message else {
            throw JChatError.decodingError("No response content")
        }

        let usage = chatResponse.usage
        return ChatCompletionResult(
            content: message.content,
            promptTokens: usage?.prompt_tokens ?? 0,
            completionTokens: usage?.completion_tokens ?? 0,
            modelID: chatResponse.model ?? request.modelID
        )
    }

    // MARK: - Streaming Message Send

    func streamMessage(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        let request = ModelCallRequest(
            messages: messages,
            modelID: modelID,
            parameters: parameters,
            apiKey: apiKey
        )
        return streamMessage(request: request)
    }

    func streamMessage(request: ModelCallRequest) -> AsyncThrowingStream<StreamEvent, Error> {
        if !request.stream {
            return streamFromNonStreamingRequest(request: request)
        }

        let builtRequest: URLRequest
        do {
            builtRequest = try buildChatRequest(from: request.withStream(true))
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, _) = try await self.openStreamWithRetry(request: builtRequest, retryPolicy: self.chatRetryPolicy)
                    var eventDataLines: [String] = []
                    var receivedDone = false

                    for try await rawLine in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }

                        let line = rawLine.trimmingCharacters(in: .newlines)

                        if line.isEmpty {
                            if !eventDataLines.isEmpty {
                                let payload = eventDataLines.joined(separator: "\n")
                                eventDataLines.removeAll(keepingCapacity: true)
                                for event in Self.parseSSEPayload(payload) {
                                    if case .done = event { receivedDone = true }
                                    continuation.yield(event)
                                }
                            }
                            continue
                        }

                        if line.hasPrefix(":") {
                            continue // keepalive/comment line
                        }

                        if line.hasPrefix("data:") {
                            var dataLine = String(line.dropFirst(5))
                            if dataLine.first == " " {
                                dataLine.removeFirst()
                            }

                            // Fast path: many providers send one complete JSON payload per data line.
                            let singleEvents = Self.parseSSEPayload(dataLine)
                            if !singleEvents.isEmpty {
                                eventDataLines.removeAll(keepingCapacity: true)
                                for event in singleEvents {
                                    if case .done = event { receivedDone = true }
                                    continuation.yield(event)
                                }
                                continue
                            }

                            // Slow path: support multi-line payloads when providers split JSON across lines.
                            eventDataLines.append(dataLine)
                            let joinedPayload = eventDataLines.joined(separator: "\n")
                            let joinedEvents = Self.parseSSEPayload(joinedPayload)
                            if !joinedEvents.isEmpty {
                                eventDataLines.removeAll(keepingCapacity: true)
                                for event in joinedEvents {
                                    if case .done = event { receivedDone = true }
                                    continuation.yield(event)
                                }
                                continue
                            }

                            // If this looked like a complete one-line JSON object but did not decode,
                            // discard it so a malformed chunk doesn't poison subsequent valid chunks.
                            let trimmedDataLine = dataLine.trimmingCharacters(in: .whitespacesAndNewlines)
                            if Self.looksLikeCompleteSingleJSONPayload(trimmedDataLine) {
                                eventDataLines.removeAll(keepingCapacity: true)
                            }
                            continue
                        }
                    }

                    if !eventDataLines.isEmpty {
                        let payload = eventDataLines.joined(separator: "\n")
                        for event in Self.parseSSEPayload(payload) {
                            if case .done = event { receivedDone = true }
                            continuation.yield(event)
                        }
                    }

                    if !receivedDone {
                        continuation.yield(.done)
                    }
                    continuation.finish()
                } catch {
                    if !Task.isCancelled {
                        continuation.finish(throwing: Self.mapTransportError(error))
                    } else {
                        continuation.finish()
                    }
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Cost Calculation

    func calculateCost(
        promptTokens: Int,
        completionTokens: Int,
        promptPricePerToken: String,
        completionPricePerToken: String
    ) -> Double {
        let promptCost = Double(promptTokens) * (Double(promptPricePerToken) ?? 0.0)
        let completionCost = Double(completionTokens) * (Double(completionPricePerToken) ?? 0.0)
        return promptCost + completionCost
    }

    // MARK: - Private Helpers

    /// Build the `ChatRequest` body struct from a `ModelCallRequest`.
    /// Shared by both the network path and the pretty-print inspector path.
    private func buildRequestBody(from modelRequest: ModelCallRequest) -> ChatRequest {
        let chatMessages = modelRequest.messages.map { ChatMessage(role: $0.role, content: $0.content) }
        let parameters = modelRequest.parameters

        // stream is ALWAYS included — OpenRouter defaults to false, so omitting it
        // would silently disable streaming for every request.
        var body = ChatRequest(
            model: modelRequest.modelID,
            messages: chatMessages,
            stream: modelRequest.stream
        )

        // Core sampling — only sent when non-default
        if let temp = parameters.temperature, temp != 1.0 { body.temperature = temp }
        if let maxTok = parameters.maxTokens, maxTok > 0 { body.max_tokens = maxTok }
        if let topP = parameters.topP, topP != 1.0 { body.top_p = topP }

        // Optional sampling parameters
        if let topK = parameters.topK, topK > 0 { body.top_k = topK }
        if let fp = parameters.frequencyPenalty, fp != 0 { body.frequency_penalty = fp }
        if let pp = parameters.presencePenalty, pp != 0 { body.presence_penalty = pp }
        if let rp = parameters.repetitionPenalty, rp != 1.0 { body.repetition_penalty = rp }
        if let mp = parameters.minP, mp != 0 { body.min_p = mp }
        if let ta = parameters.topA, ta != 0 { body.top_a = ta }

        // Stream options - include usage for cost accounting
        if modelRequest.stream {
            body.stream_options = StreamOptions(include_usage: true)
        }

        // Reasoning payload
        var reasoning = ReasoningPayload()
        reasoning.enabled = parameters.reasoningEnabled

        // max_tokens and effort are mutually exclusive for Anthropic models
        if let reasoningMaxTokens = parameters.reasoningMaxTokens {
            reasoning.max_tokens = reasoningMaxTokens
        } else {
            reasoning.effort = parameters.reasoningEffort
        }

        if let exclude = parameters.reasoningExclude, exclude {
            reasoning.exclude = true
        }

        body.reasoning = reasoning

        // Verbosity (nil = OpenRouter default)
        if let verbosity = parameters.verbosity {
            body.verbosity = verbosity
        }

        return body
    }

    private func buildChatRequest(from modelRequest: ModelCallRequest) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid URL")
        }

        let requestBody = buildRequestBody(from: modelRequest)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(modelRequest.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("JChat/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JChat", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)
        return request
    }

    /// Serialize the exact POST body we'd send for this request, pretty-printed for the JSON inspector.
    func prettyRequestJSON(for modelRequest: ModelCallRequest) -> String? {
        let body = buildRequestBody(from: modelRequest)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        guard let data = try? encoder.encode(body) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private func performChatRequest(request: ModelCallRequest) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = try buildChatRequest(from: request)
        return try await performDataRequest(request: urlRequest, retryPolicy: chatRetryPolicy)
    }

    private func performDataRequest(
        request: URLRequest,
        retryPolicy: RetryPolicy?
    ) async throws -> (Data, HTTPURLResponse) {
        var attempt = 0

        while true {
            do {
                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw JChatError.serverError(statusCode: 0, message: "Invalid response")
                }

                if let policy = retryPolicy,
                   shouldRetry(statusCode: httpResponse.statusCode, policy: policy),
                   shouldAttemptRetry(attempt: attempt, policy: policy) {
                    let retryAfter = Self.retryAfter(from: httpResponse)
                    try await sleepForRetry(attempt: attempt, retryAfter: retryAfter, policy: policy)
                    attempt += 1
                    continue
                }

                return (data, httpResponse)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let mapped = Self.mapTransportError(error)

                if let policy = retryPolicy,
                   shouldRetry(transportError: error),
                   shouldAttemptRetry(attempt: attempt, policy: policy) {
                    try await sleepForRetry(attempt: attempt, retryAfter: nil, policy: policy)
                    attempt += 1
                    continue
                }

                throw mapped
            }
        }
    }

    private func openStreamWithRetry(
        request: URLRequest,
        retryPolicy: RetryPolicy
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        var attempt = 0

        while true {
            do {
                let (bytes, response) = try await session.bytes(for: request)
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw JChatError.serverError(statusCode: 0, message: "Invalid response")
                }

                guard httpResponse.statusCode == 200 else {
                    if shouldRetry(statusCode: httpResponse.statusCode, policy: retryPolicy),
                       shouldAttemptRetry(attempt: attempt, policy: retryPolicy) {
                        let retryAfter = Self.retryAfter(from: httpResponse)
                        try await sleepForRetry(attempt: attempt, retryAfter: retryAfter, policy: retryPolicy)
                        attempt += 1
                        continue
                    }

                    var body = ""
                    for try await line in bytes.lines {
                        body += line
                    }
                    throw JChatError.from(
                        statusCode: httpResponse.statusCode,
                        body: Self.normalizedErrorBody(from: body),
                        retryAfter: Self.retryAfter(from: httpResponse)
                    )
                }

                return (bytes, httpResponse)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                let mapped = Self.mapTransportError(error)
                if shouldRetry(transportError: error),
                   shouldAttemptRetry(attempt: attempt, policy: retryPolicy) {
                    try await sleepForRetry(attempt: attempt, retryAfter: nil, policy: retryPolicy)
                    attempt += 1
                    continue
                }
                throw mapped
            }
        }
    }

    private func streamFromNonStreamingRequest(request: ModelCallRequest) -> AsyncThrowingStream<StreamEvent, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (data, httpResponse) = try await self.performChatRequest(request: request.withStream(false))
                    try self.throwIfNotSuccess(httpResponse: httpResponse, data: data)

                    let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
                    guard let choice = chatResponse.choices.first, let message = choice.message else {
                        throw JChatError.decodingError("No response content")
                    }

                    // Emit metadata events first — mirrors the streaming path
                    // where generationID and modelID arrive on the first chunk.
                    if let id = chatResponse.id, !id.isEmpty {
                        continuation.yield(.generationID(id))
                    }
                    continuation.yield(.modelID(chatResponse.model ?? request.modelID))

                    if !message.content.isEmpty {
                        continuation.yield(.delta(message.content))
                    }

                    if let reason = choice.finish_reason, !reason.isEmpty {
                        continuation.yield(.finishReason(reason))
                    }

                    let usage = chatResponse.usage
                    let prettyJSON: String
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                       let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]) {
                        prettyJSON = String(data: prettyData, encoding: .utf8) ?? String(data: data, encoding: .utf8) ?? "{}"
                    } else {
                        prettyJSON = String(data: data, encoding: .utf8) ?? "{}"
                    }

                    continuation.yield(.usage(
                        promptTokens: usage?.prompt_tokens ?? 0,
                        completionTokens: usage?.completion_tokens ?? 0,
                        rawJSON: prettyJSON
                    ))
                    continuation.yield(.done)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.mapTransportError(error))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    private func throwIfNotSuccess(httpResponse: HTTPURLResponse, data: Data) throws {
        guard httpResponse.statusCode == 200 else {
            throw JChatError.from(
                statusCode: httpResponse.statusCode,
                body: Self.errorMessage(from: data),
                retryAfter: Self.retryAfter(from: httpResponse)
            )
        }
    }

    private func shouldRetry(statusCode: Int, policy: RetryPolicy) -> Bool {
        policy.retryableStatusCodes.contains(statusCode)
    }

    private func shouldRetry(transportError: Error) -> Bool {
        guard let urlError = transportError as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .notConnectedToInternet:
            return true
        default:
            return false
        }
    }

    private func shouldAttemptRetry(attempt: Int, policy: RetryPolicy) -> Bool {
        attempt + 1 < policy.maxAttempts
    }

    private func sleepForRetry(attempt: Int, retryAfter: TimeInterval?, policy: RetryPolicy) async throws {
        let delaySeconds = retryDelay(attempt: attempt, retryAfter: retryAfter, policy: policy)
        let nanoseconds = UInt64(max(0, delaySeconds) * 1000000000)
        try await sleep(nanoseconds)
    }

    private func retryDelay(attempt: Int, retryAfter: TimeInterval?, policy: RetryPolicy) -> TimeInterval {
        if let retryAfter, retryAfter > 0 {
            return retryAfter
        }

        let exponential = policy.baseDelaySeconds * pow(2.0, Double(attempt))
        let capped = min(policy.maxDelaySeconds, exponential)

        guard policy.jitterRatio > 0 else {
            return capped
        }

        let jitterAmplitude = capped * policy.jitterRatio
        let randomSigned = (randomUnit() * 2.0) - 1.0
        let jitter = jitterAmplitude * randomSigned
        return max(0, capped + jitter)
    }

    private static func parseSSEPayload(_ payload: String) -> [StreamEvent] {
        let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if trimmed == "[DONE]" {
            return [.done]
        }

        guard let jsonData = trimmed.data(using: .utf8) else {
            return []
        }

        if let streamError = extractStreamingError(from: jsonData) {
            return [.error(streamError)]
        }

        guard let chunk = try? JSONDecoder().decode(StreamChunk.self, from: jsonData) else {
            return []
        }

        var events: [StreamEvent] = []
        if let id = chunk.id, !id.isEmpty {
            events.append(.generationID(id))
        }
        if let model = chunk.model {
            events.append(.modelID(model))
        }

        if let choices = chunk.choices {
            for choice in choices {
                if let content = choice.delta?.content, !content.isEmpty {
                    events.append(.delta(content))
                }
                if let content = choice.message?.content, !content.isEmpty {
                    events.append(.delta(content))
                }
                if let reason = choice.finish_reason, !reason.isEmpty {
                    events.append(.finishReason(reason))
                }
            }
        }

        if let usage = chunk.usage,
           let promptTokens = usage.prompt_tokens,
           let completionTokens = usage.completion_tokens {
            let prettyJSON: String
            if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
               let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]) {
                prettyJSON = String(data: prettyData, encoding: .utf8) ?? trimmed
            } else {
                prettyJSON = trimmed
            }
            events.append(.usage(promptTokens: promptTokens, completionTokens: completionTokens, rawJSON: prettyJSON))
        }

        return events
    }

    static func parseSSEPayloadForTesting(_ payload: String) -> [StreamEvent] {
        parseSSEPayload(payload)
    }

    private static func looksLikeCompleteSingleJSONPayload(_ payload: String) -> Bool {
        guard !payload.isEmpty else { return false }
        if payload == "[DONE]" { return true }
        if payload.first == "{" && payload.last == "}" { return true }
        if payload.first == "[" && payload.last == "]" { return true }
        return false
    }

    private static func extractStreamingError(from data: Data) -> JChatError? {
        guard let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data),
              let message = envelope.error?.message,
              !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }

        return .streamingError(message)
    }

    private static func mapTransportError(_ error: Error) -> Error {
        if let jchatError = error as? JChatError {
            return jchatError
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed:
                return JChatError.networkUnavailable
            case .timedOut:
                return JChatError.serverError(statusCode: 0, message: "Request timed out")
            default:
                return JChatError.unknown(urlError)
            }
        }

        return JChatError.unknown(error)
    }

    private static func errorMessage(from data: Data) -> String {
        if let envelope = try? JSONDecoder().decode(APIErrorEnvelope.self, from: data),
           let message = envelope.error?.message,
           !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return message
        }

        let fallback = String(data: data, encoding: .utf8) ?? ""
        return normalizedErrorBody(from: fallback)
    }

    private static func normalizedErrorBody(from body: String) -> String {
        let trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Unknown server error" : trimmed
    }

    private static func retryAfter(from response: HTTPURLResponse) -> TimeInterval? {
        guard let raw = response.value(forHTTPHeaderField: "Retry-After") else {
            return nil
        }

        if let seconds = TimeInterval(raw.trimmingCharacters(in: .whitespacesAndNewlines)) {
            return max(0, seconds)
        }

        if let date = retryAfterDateFormatter.date(from: raw) {
            return max(0, date.timeIntervalSinceNow)
        }

        return nil
    }

    private static let retryAfterDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss zzz"
        return formatter
    }()
}
