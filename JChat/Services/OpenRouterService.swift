//
//  OpenRouterService.swift
//  JChat
//

import Foundation

struct ChatParameters: Sendable {
    var temperature: Double = 0.7
    var maxTokens: Int = 4096
    var topP: Double = 1.0
    var topK: Int? = nil
    var frequencyPenalty: Double? = nil
    var presencePenalty: Double? = nil
    var repetitionPenalty: Double? = nil
    var minP: Double? = nil
    var topA: Double? = nil
}

struct ChatCompletionResult: Sendable {
    let content: String
    let promptTokens: Int
    let completionTokens: Int
    let modelID: String
}

enum StreamEvent: Sendable {
    case delta(String)
    case usage(promptTokens: Int, completionTokens: Int)
    case modelID(String)
    case done
    case error(JChatError)
}

actor OpenRouterService {
    static let shared = OpenRouterService()

    private let baseURL = "https://openrouter.ai/api/v1"

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
    }

    struct ChatResponse: Codable, Sendable {
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

    // MARK: - Models API Types

    struct OpenRouterModel: Codable, Sendable {
        let id: String
        let name: String
        let description: String?
        let context_length: Int?
        let pricing: OpenRouterPricing?

        struct OpenRouterPricing: Codable, Sendable {
            let prompt: String?
            let completion: String?
            let image: String?
            let request: String?
        }
    }

    struct ModelsResponse: Codable, Sendable {
        let data: [OpenRouterModel]
    }

    // MARK: - Key/Credits API Types

    struct KeyResponse: Codable, Sendable {
        let data: KeyData

        struct KeyData: Codable, Sendable {
            let label: String?
            let limit: Double?
            let usage: Double?
            let limit_remaining: Double?
        }
    }

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
        request.setValue("JChat", forHTTPHeaderField: "X-Title")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw JChatError.from(statusCode: httpResponse.statusCode, body: body)
        }

        let modelsResponse = try JSONDecoder().decode(ModelsResponse.self, from: data)
        return modelsResponse.data
    }

    // MARK: - Key Validation & Credits

    func validateAPIKey(apiKey: String) async throws -> KeyResponse {
        guard let url = URL(string: "\(baseURL)/auth/key") else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw JChatError.from(statusCode: httpResponse.statusCode, body: body)
        }

        return try JSONDecoder().decode(KeyResponse.self, from: data)
    }

    func fetchCredits(apiKey: String) async throws -> CreditsResponse {
        guard let url = URL(string: "\(baseURL)/credits") else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw JChatError.from(statusCode: httpResponse.statusCode, body: body)
        }

        return try JSONDecoder().decode(CreditsResponse.self, from: data)
    }

    // MARK: - Non-Streaming Message Send

    func sendMessage(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String
    ) async throws -> ChatCompletionResult {
        let (data, httpResponse) = try await performChatRequest(
            messages: messages,
            modelID: modelID,
            parameters: parameters,
            apiKey: apiKey,
            stream: false
        )

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw JChatError.from(statusCode: httpResponse.statusCode, body: body)
        }

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)

        guard let choice = chatResponse.choices.first, let message = choice.message else {
            throw JChatError.decodingError("No response content")
        }

        let usage = chatResponse.usage
        return ChatCompletionResult(
            content: message.content,
            promptTokens: usage?.prompt_tokens ?? 0,
            completionTokens: usage?.completion_tokens ?? 0,
            modelID: chatResponse.model ?? modelID
        )
    }

    // MARK: - Streaming Message Send

    func streamMessage(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String
    ) -> AsyncThrowingStream<StreamEvent, Error> {
        // Capture values needed for the closure
        let builtRequest: URLRequest
        do {
            builtRequest = try buildChatRequest(
                messages: messages,
                modelID: modelID,
                parameters: parameters,
                apiKey: apiKey,
                stream: true
            )
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: builtRequest)

                    guard let httpResponse = response as? HTTPURLResponse else {
                        continuation.yield(.error(JChatError.serverError(statusCode: 0, message: "Invalid response")))
                        continuation.finish()
                        return
                    }

                    guard httpResponse.statusCode == 200 else {
                        var body = ""
                        for try await line in bytes.lines {
                            body += line
                        }
                        let error = JChatError.from(statusCode: httpResponse.statusCode, body: body)
                        continuation.yield(.error(error))
                        continuation.finish()
                        return
                    }

                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            continuation.finish()
                            return
                        }

                        guard line.hasPrefix("data: ") else { continue }
                        let jsonString = String(line.dropFirst(6))

                        if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                            continuation.yield(.done)
                            break
                        }

                        guard let jsonData = jsonString.data(using: .utf8) else { continue }

                        if let chunk = try? JSONDecoder().decode(ChatResponse.self, from: jsonData) {
                            if let delta = chunk.choices.first?.delta, let content = delta.content {
                                continuation.yield(.delta(content))
                            }
                            if let model = chunk.model {
                                continuation.yield(.modelID(model))
                            }
                            if let usage = chunk.usage,
                               let prompt = usage.prompt_tokens,
                               let completion = usage.completion_tokens {
                                continuation.yield(.usage(promptTokens: prompt, completionTokens: completion))
                            }
                        }
                    }

                    continuation.finish()
                } catch {
                    if !Task.isCancelled {
                        continuation.finish(throwing: error)
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

    private func buildChatRequest(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String,
        stream: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid URL")
        }

        let chatMessages = messages.map { ChatMessage(role: $0.role, content: $0.content) }

        var requestBody = ChatRequest(
            model: modelID,
            messages: chatMessages,
            stream: stream,
            temperature: parameters.temperature,
            max_tokens: parameters.maxTokens,
            top_p: parameters.topP
        )

        if let topK = parameters.topK, topK > 0 { requestBody.top_k = topK }
        if let fp = parameters.frequencyPenalty, fp != 0 { requestBody.frequency_penalty = fp }
        if let pp = parameters.presencePenalty, pp != 0 { requestBody.presence_penalty = pp }
        if let rp = parameters.repetitionPenalty, rp != 1.0 { requestBody.repetition_penalty = rp }
        if let mp = parameters.minP, mp != 0 { requestBody.min_p = mp }
        if let ta = parameters.topA, ta != 0 { requestBody.top_a = ta }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("JChat/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JChat", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONEncoder().encode(requestBody)

        return request
    }

    private func performChatRequest(
        messages: [(role: String, content: String)],
        modelID: String,
        parameters: ChatParameters,
        apiKey: String,
        stream: Bool
    ) async throws -> (Data, HTTPURLResponse) {
        let request = try buildChatRequest(
            messages: messages,
            modelID: modelID,
            parameters: parameters,
            apiKey: apiKey,
            stream: stream
        )

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw JChatError.serverError(statusCode: 0, message: "Invalid response")
        }

        return (data, httpResponse)
    }
}
