//
//  OpenRouterService.swift
//  JChat
//

import Foundation

actor OpenRouterService {
    static let shared = OpenRouterService()
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    // Pricing per 1M tokens (approximate, should be updated based on current OpenRouter pricing)
    private static let modelPricing: [String: (prompt: Double, completion: Double)] = [
        "anthropic/claude-3.5-sonnet": (3.0, 15.0),
        "anthropic/claude-3.5-haiku": (0.25, 1.25),
        "openai/gpt-4o": (5.0, 15.0),
        "openai/gpt-4o-mini": (0.15, 0.6),
        "anthropic/claude-3-opus": (15.0, 75.0),
        "meta-llama/llama-3.1-70b-instruct": (0.52, 0.75),
        "google/gemini-pro-1.5": (3.5, 10.5)
    ]
    
    struct ChatMessage: Codable {
        let role: String
        let content: String
    }
    
    struct ChatRequest: Codable {
        let model: String
        let messages: [ChatMessage]
        let temperature: Double
        let max_tokens: Int
        let top_p: Double
        let frequency_penalty: Double
        let presence_penalty: Double
    }
    
    struct ChatResponse: Codable {
        let choices: [Choice]
        let usage: Usage?
        let model: String?
    }
    
    struct Choice: Codable {
        let message: ChatMessage
        let finish_reason: String?
    }
    
    struct Usage: Codable {
        let prompt_tokens: Int
        let completion_tokens: Int
        let total_tokens: Int
    }
    
    enum ServiceError: Error {
        case invalidURL
        case invalidResponse
        case apiError(String)
        case noData
        case apiKeyNotConfigured
    }
    
    func sendMessage(
        messages: [(role: String, content: String)],
        settings: APISettings
    ) async throws -> (
        content: String,
        promptTokens: Int,
        completionTokens: Int,
        cost: Double
    ) {
        // Load API key directly from Keychain
        let apiKey: String
        do {
            apiKey = try await KeychainManager.shared.loadAPIKey()
        } catch KeychainError.itemNotFound {
            throw ServiceError.apiKeyNotConfigured
        } catch {
            throw ServiceError.apiError("Failed to access Keychain: \(error.localizedDescription)")
        }
        
        guard !apiKey.isEmpty else {
            throw ServiceError.apiKeyNotConfigured
        }
        
        guard let url = URL(string: baseURL) else {
            throw ServiceError.invalidURL
        }
        
        let chatMessages = messages.map { ChatMessage(role: $0.role, content: $0.content) }
        
        let requestBody = ChatRequest(
            model: settings.selectedModel,
            messages: chatMessages,
            temperature: settings.temperature,
            max_tokens: settings.maxTokens,
            top_p: settings.topP,
            frequency_penalty: settings.frequencyPenalty,
            presence_penalty: settings.presencePenalty
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("JChat/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("JChat", forHTTPHeaderField: "X-Title")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorString = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ServiceError.apiError("HTTP \(httpResponse.statusCode): \(errorString)")
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        
        guard let choice = chatResponse.choices.first else {
            throw ServiceError.noData
        }
        
        let usage = chatResponse.usage ?? Usage(prompt_tokens: 0, completion_tokens: 0, total_tokens: 0)
        let cost = calculateCost(
            model: settings.selectedModel,
            promptTokens: usage.prompt_tokens,
            completionTokens: usage.completion_tokens
        )
        
        return (
            content: choice.message.content,
            promptTokens: usage.prompt_tokens,
            completionTokens: usage.completion_tokens,
            cost: cost
        )
    }
    
    private func calculateCost(model: String, promptTokens: Int, completionTokens: Int) -> Double {
        guard let pricing = Self.modelPricing[model] else {
            // Default to claude-3.5-sonnet pricing if unknown
            let fallback = Self.modelPricing["anthropic/claude-3.5-sonnet"]!
            return calculateCostFromPricing(promptTokens: promptTokens, completionTokens: completionTokens, pricing: fallback)
        }
        return calculateCostFromPricing(promptTokens: promptTokens, completionTokens: completionTokens, pricing: pricing)
    }
    
    private func calculateCostFromPricing(promptTokens: Int, completionTokens: Int, pricing: (prompt: Double, completion: Double)) -> Double {
        let promptCost = Double(promptTokens) * (pricing.prompt / 1_000_000)
        let completionCost = Double(completionTokens) * (pricing.completion / 1_000_000)
        return promptCost + completionCost
    }
    
    func availableModels() async -> [String] {
        return Array(Self.modelPricing.keys).sorted()
    }
}
