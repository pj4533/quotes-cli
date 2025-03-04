import Foundation
import os

enum AIServiceType: String, CaseIterable {
    case openAI = "openai"
    case anthropic = "anthropic"
    
    static func fromString(_ string: String?) -> AIServiceType {
        guard let string = string,
              let type = AIServiceType(rawValue: string.lowercased()) else {
            return .openAI // Default to OpenAI
        }
        return type
    }
}

protocol AIServiceProtocol {
    mutating func fetchQuote(theme: String?, verbose: Bool) async throws -> String
}

struct AIServiceFactory {
    static func createService(type: AIServiceType, quoteGenerator: QuoteGenerator = QuoteGenerator()) -> AIServiceProtocol {
        switch type {
        case .openAI:
            return OpenAIService(quoteGenerator: quoteGenerator)
        case .anthropic:
            return AnthropicAIService(quoteGenerator: quoteGenerator)
        }
    }
}
