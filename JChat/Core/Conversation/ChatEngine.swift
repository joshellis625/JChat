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

enum ChatEngineEvent: Sendable {
    case delta(String)
    case usage(promptTokens: Int, completionTokens: Int)
    case modelID(String)
    case done
}

protocol ChatEngineProtocol: Sendable {
    func streamAssistantResponse(request: ChatEngineRequest) async -> AsyncThrowingStream<ChatEngineEvent, Error>
}

actor OpenRouterChatEngine: ChatEngineProtocol {
    private let service: OpenRouterService

    init(service: OpenRouterService = .shared) {
        self.service = service
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
                        case .delta(let text):
                            continuation.yield(.delta(text))
                        case .usage(let prompt, let completion):
                            continuation.yield(.usage(promptTokens: prompt, completionTokens: completion))
                        case .modelID(let modelID):
                            continuation.yield(.modelID(modelID))
                        case .done:
                            continuation.yield(.done)
                        case .error(let error):
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
