import Foundation
import os

struct AnthropicAIService: AIServiceProtocol {
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "AnthropicAIService")
    
    private let inspirations = [
        "science",
        "philosophy",
        "nature",
        "history",
        "mythology",
        "technology",
        "art",
        "literature",
        "music",
        "psychology",
        "astronomy",
        "economics",
        "engineering",
        "spirituality",
        "sociology",
        "biology",
        "geography",
        "politics",
        "architecture",
        "medicine"
    ]
    
    func fetchQuote(theme: String?, verbose: Bool = false) async throws -> String {
        logger.notice("🔍 Starting quote fetch process with Anthropic")
        guard let apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"] else {
            logger.error("ANTHROPIC_API_KEY not set.")
            throw NSError(domain: "AnthropicAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: ANTHROPIC_API_KEY not set."])
        }
        logger.debug("API key found")
        
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            logger.error("Invalid URL.")
            throw NSError(domain: "AnthropicAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Invalid URL."])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("\(apiKey)", forHTTPHeaderField: "x-api-key")
        
        // Select a random inspiration
        guard let inspiration = inspirations.randomElement() else {
            logger.error("Inspirations array is empty.")
            throw NSError(domain: "AnthropicAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Inspirations array is empty."])
        }
        
        // Generate a random uppercase letter
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        guard let randomLetter = letters.randomElement() else {
            logger.error("Could not generate a random letter.")
            throw NSError(domain: "AnthropicAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Could not generate a random letter."])
        }
        let randomLetterStr = String(randomLetter)
        
        let prompt: String
        if let theme = theme, !theme.isEmpty {
            prompt = """
            Provide a short, compelling quote that embodies the themes of \(theme). \
            Draw inspiration from \(inspiration). \
            The first word of the quote should start with the letter \(randomLetterStr). \
            Keep it under 5 words.
            """
        } else {
            prompt = """
            Provide a short, compelling quote that uses a random theme. \
            Draw inspiration from \(inspiration). \
            The first word of the quote should start with the letter \(randomLetterStr). \
            Keep it under 5 words.
            """
        }
        
        if verbose {
            print("Prompt used: \(prompt)")
        }
        
        let jsonBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 100,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        } catch {
            logger.error("Failed to serialize JSON body: \(error.localizedDescription)")
            throw NSError(domain: "AnthropicAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Failed to serialize JSON body."])
        }
        
        logger.notice("🌐 Sending request to Anthropic API")
        do {
            logger.debug("Request URL: \(url.absoluteString)")
            logger.debug("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "None")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            logger.notice("📥 Received response from Anthropic API")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type.")
                throw NSError(domain: "AnthropicAIService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Invalid response."])
            }
            
            // Log all response headers to help debug rate limit issues
            logger.debug("Response status code: \(httpResponse.statusCode)")
            logger.notice("--- Response Headers ---")
            
            // Print all headers to console for visibility
            print("\n📋 Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                let keyString = String(describing: key)
                let valueString = String(describing: value)
                logger.debug("\(keyString): \(valueString)")
                print("  \(keyString): \(valueString)")
            }
            
            // Check for Anthropic specific rate limit headers
            let rateLimitHeaders = [
                "x-ratelimit-limit",
                "x-ratelimit-remaining",
                "x-ratelimit-reset",
                "retry-after"
            ]
            
            print("\n⚠️ Rate Limit Information:")
            var foundRateLimitHeaders = false
            
            for header in rateLimitHeaders {
                if let value = httpResponse.allHeaderFields[header] {
                    let valueString = String(describing: value)
                    logger.notice("\(header): \(valueString)")
                    print("  \(header): \(valueString)")
                    foundRateLimitHeaders = true
                }
            }
            
            if !foundRateLimitHeaders {
                print("  No specific rate limit headers found")
            }
            print("")
            
            // Log response body
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            logger.debug("--- Response Body ---\n\(responseBody)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("❌ Received HTTP \(httpResponse.statusCode). Response Body: \(responseBody)")
                throw NSError(domain: "AnthropicAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error: HTTP \(httpResponse.statusCode). \(responseBody)"])
            }
            
            do {
                let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                logger.debug("Successfully decoded Anthropic response")
                
                if let content = anthropicResponse.content.first?.text {
                    let cleanedQuote = content.trimmingCharacters(in: .whitespacesAndNewlines)
                                             .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    logger.notice("✅ Successfully retrieved quote: \(cleanedQuote)")
                    return cleanedQuote
                } else {
                    logger.error("❌ No quote found in response")
                    throw NSError(domain: "AnthropicAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error: No quote found in response."])
                }
            } catch {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                logger.error("❌ Failed to parse JSON response: \(error.localizedDescription). Response Body: \(responseBody)")
                throw NSError(domain: "AnthropicAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Error: Failed to parse JSON response. \(error.localizedDescription)"])
            }
            
        } catch {
            logger.error("❌ Error fetching quote: \(error.localizedDescription)")
            if let nsError = error as NSError? {
                logger.error("Error domain: \(nsError.domain), code: \(nsError.code)")
                if let underlyingError = nsError.userInfo[NSUnderlyingErrorKey] as? Error {
                    logger.error("Underlying error: \(underlyingError)")
                }
            }
            throw error
        }
    }
}

struct AnthropicResponse: Decodable {
    let id: String
    let content: [ContentBlock]
    
    struct ContentBlock: Decodable {
        let type: String
        let text: String
    }
}
