//
//  JChatError.swift
//  JChat
//

import Foundation

enum JChatError: LocalizedError {
    case apiKeyNotConfigured
    case apiKeyInvalid
    case networkUnavailable
    case rateLimited(retryAfter: TimeInterval?)
    case insufficientCredits
    case modelNotAvailable(String)
    case serverError(statusCode: Int, message: String)
    case decodingError(String)
    case streamingError(String)
    case noModelSelected
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "API key not configured"
        case .apiKeyInvalid:
            return "Your API key is invalid"
        case .networkUnavailable:
            return "No internet connection"
        case .rateLimited:
            return "Rate limit reached"
        case .insufficientCredits:
            return "Insufficient credits"
        case let .modelNotAvailable(model):
            return "Model unavailable: \(model)"
        case let .serverError(code, _):
            return "Server error (\(code))"
        case .decodingError:
            return "Failed to read the response"
        case let .streamingError(detail):
            return "Streaming error: \(detail)"
        case .noModelSelected:
            return "No model selected"
        case let .unknown(error):
            return error.localizedDescription
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .apiKeyNotConfigured:
            return "Open Settings and enter your OpenRouter API key."
        case .apiKeyInvalid:
            return "Check your API key in Settings. It may have expired or been revoked."
        case .networkUnavailable:
            return "Check your internet connection and try again."
        case let .rateLimited(retryAfter):
            if let seconds = retryAfter {
                return "Please wait \(Int(seconds)) seconds before trying again."
            }
            return "Please wait a moment before trying again."
        case .insufficientCredits:
            return "Add credits to your OpenRouter account at openrouter.ai."
        case .modelNotAvailable:
            return "Try selecting a different model."
        case .serverError:
            return "This is a temporary issue. Please try again in a moment."
        case .decodingError:
            return "This may be a temporary API issue. Please try again."
        case .streamingError:
            return "Try sending your message again."
        case .noModelSelected:
            return "Choose a model using the model picker above the chat."
        case .unknown:
            return "Please try again. If the problem persists, check your API key and internet connection."
        }
    }

    static func from(statusCode: Int, body: String) -> JChatError {
        from(statusCode: statusCode, body: body, retryAfter: nil)
    }

    static func from(statusCode: Int, body: String, retryAfter: TimeInterval?) -> JChatError {
        switch statusCode {
        case 401:
            return .apiKeyInvalid
        case 402:
            return .insufficientCredits
        case 429:
            return .rateLimited(retryAfter: retryAfter)
        case 503:
            return .modelNotAvailable(body)
        default:
            return .serverError(statusCode: statusCode, message: body)
        }
    }
}
