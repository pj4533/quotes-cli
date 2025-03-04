import Foundation
import os

struct AnthropicAIService: AIServiceProtocol {
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "AnthropicAIService")
    private let quoteGenerator = QuoteGenerator()
    private var messageHistory: [[String: String]] = []
    
    mutating func fetchQuote(theme: String?, verbose: Bool = false) async throws -> String {
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
        
        // Generate prompt using the shared generator
        let (prompt, _) = quoteGenerator.generatePrompt(theme: theme, verbose: verbose)
        
        // Add the new prompt to message history
        let newMessage = ["role": "user", "content": prompt]
        messageHistory.append(newMessage)
        
        if verbose {
            print("\n📝 Sending with \(messageHistory.count) messages in history")
        }
        
        let jsonBody: [String: Any] = [
            "model": "claude-3-haiku-20240307",
            "max_tokens": 100,
            "messages": messageHistory
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
            
            // Log headers using the shared method
            let anthropicRateLimitHeaders = [
                "x-ratelimit-limit",
                "x-ratelimit-remaining",
                "x-ratelimit-reset",
                "retry-after"
            ]
            
            QuoteGenerator.logResponseHeaders(
                httpResponse: httpResponse,
                rateLimitHeaders: anthropicRateLimitHeaders,
                verbose: verbose,
                logger: logger
            )
            
            // Log response body
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            logger.debug("--- Response Body ---\n\(responseBody)")
            
            if verbose {
                print("\n📄 Response Body (truncated):")
                let truncatedBody = responseBody.count > 500 ? responseBody.prefix(500) + "..." : responseBody
                print(truncatedBody)
                print("")
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("❌ Received HTTP \(httpResponse.statusCode). Response Body: \(responseBody)")
                throw NSError(domain: "AnthropicAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error: HTTP \(httpResponse.statusCode). \(responseBody)"])
            }
            
            do {
                let anthropicResponse = try JSONDecoder().decode(AnthropicResponse.self, from: data)
                logger.debug("Successfully decoded Anthropic response")
                
                if let content = anthropicResponse.content.first?.text {
                    let cleanedQuote = quoteGenerator.cleanQuote(content)
                    
                    // Add the assistant's response to message history
                    messageHistory.append(["role": "assistant", "content": content])
                    
                    logger.notice("✅ Successfully retrieved quote: \(cleanedQuote)")
                    if verbose {
                        print("📚 Message history now contains \(messageHistory.count) messages")
                    }
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
