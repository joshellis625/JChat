//
//  ChatEngine.swift
//  JChat
//

import Foundation

struct ChatEngineRequest: Sendable {
    let messages: [(role: String, content: String)]
    let modelID: String
    let parameters: ChatParameters
    let apiKey: String
}

/// Events consumed by ConversationStore during streaming.
/// These mirror StreamEvent but without the error case (errors are thrown instead).
enum ChatEngineEvent: Sendable {
    case delta(String)
    case usage(promptTokens: Int, completionTokens: Int, rawJSON: String)
    case modelID(String)
    case generationID(String)
    case finishReason(String)
    case done
}

protocol ChatEngineProtocol: Sendable {
    func streamAssistantResponse(request: ChatEngineRequest) async -> AsyncThrowingStream<ChatEngineEvent, Error>
    func prettyRequestJSON(for request: ChatEngineRequest) async -> String?
}

actor OpenRouterChatEngine: ChatEngineProtocol {
    private let service: OpenRouterService

    init(service: OpenRouterService = .shared) {
        self.service = service
    }

    func prettyRequestJSON(for request: ChatEngineRequest) async -> String? {
        let modelRequest = ModelCallRequest(
            messages: request.messages,
            modelID: request.modelID,
            parameters: request.parameters,
            apiKey: request.apiKey
        )
        return await service.prettyRequestJSON(for: modelRequest)
    }

    func streamAssistantResponse(request: ChatEngineRequest) async -> AsyncThrowingStream<ChatEngineEvent, Error> {
        let modelRequest = ModelCallRequest(
            messages: request.messages,
            modelID: request.modelID,
            parameters: request.parameters,
            apiKey: request.apiKey,
            stream: true
        )

        let upstream = await service.streamMessage(request: modelRequest)

        return AsyncThrowingStream { continuation in
            let relayTask = Task {
                do {
                    for try await event in upstream {
                        switch event {
                        case let .delta(text):
                            continuation.yield(.delta(text))
                        case let .usage(prompt, completion, rawJSON):
                            continuation.yield(.usage(promptTokens: prompt, completionTokens: completion, rawJSON: rawJSON))
                        case let .modelID(modelID):
                            continuation.yield(.modelID(modelID))
                        case let .generationID(id):
                            continuation.yield(.generationID(id))
                        case let .finishReason(reason):
                            continuation.yield(.finishReason(reason))
                        case .done:
                            continuation.yield(.done)
                        case let .error(error):
                            throw error
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { _ in
                relayTask.cancel()
            }
        }
    }
}
