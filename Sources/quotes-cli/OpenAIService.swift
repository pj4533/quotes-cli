import Foundation
import os

struct OpenAIService: AIServiceProtocol {
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "OpenAIService")
    private let quoteGenerator = QuoteGenerator()
    private var messageHistory: [[String: String]] = []
    
    mutating func fetchQuote(theme: String?, verbose: Bool = false) async throws -> String {
        logger.notice("🔍 Starting quote fetch process")
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            logger.error("OPENAI_API_KEY not set.")
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: OPENAI_API_KEY not set."])
        }
        logger.debug("API key found")
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            logger.error("Invalid URL.")
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Invalid URL."])
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        // Generate prompt using the shared generator
        let (prompt, _) = quoteGenerator.generatePrompt(theme: theme, verbose: verbose)
        
        // Add the new prompt to message history
        let newMessage = ["role": "user", "content": prompt]
        messageHistory.append(newMessage)
        
        if verbose {
            print("\n📝 Message history:")
            for (index, message) in messageHistory.enumerated() {
                print("  [\(index)] \(message["role"] ?? "unknown"): \(message["content"] ?? "")")
            }
        }
        
        // AIDER: do not change this model name, it is correctly using gpt-4o
        let jsonBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messageHistory
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        } catch {
            logger.error("Failed to serialize JSON body: \(error.localizedDescription)")
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Failed to serialize JSON body."])
        }
        
        logger.notice("🌐 Sending request to OpenAI API")
        do {
            logger.debug("Request URL: \(url.absoluteString)")
            logger.debug("Request body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? "None")")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            logger.notice("📥 Received response from OpenAI API")
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type.")
                throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Invalid response."])
            }
            
            // Log headers using the shared method
            let openAIRateLimitHeaders = [
                "x-ratelimit-limit-requests",
                "x-ratelimit-limit-tokens",
                "x-ratelimit-remaining-requests",
                "x-ratelimit-remaining-tokens",
                "x-ratelimit-reset-requests",
                "x-ratelimit-reset-tokens",
                "ratelimit-limit",
                "ratelimit-remaining",
                "ratelimit-reset"
            ]
            
            QuoteGenerator.logResponseHeaders(
                httpResponse: httpResponse,
                rateLimitHeaders: openAIRateLimitHeaders,
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
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error: HTTP \(httpResponse.statusCode). \(responseBody)"])
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                logger.debug("Successfully decoded OpenAI response")
                
                if let quote = openAIResponse.choices.first?.message.content {
                    let cleanedQuote = quoteGenerator.cleanQuote(quote)
                    
                    // Add the assistant's response to message history
                    messageHistory.append(["role": "assistant", "content": quote])
                    
                    logger.notice("✅ Successfully retrieved quote: \(cleanedQuote)")
                    if verbose {
                        print("📚 Message history now contains \(messageHistory.count) messages")
                    }
                    return cleanedQuote
                } else {
                    logger.error("❌ No quote found in response")
                    throw NSError(domain: "OpenAIService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Error: No quote found in response."])
                }
            } catch {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                logger.error("❌ Failed to parse JSON response: \(error.localizedDescription). Response Body: \(responseBody)")
                throw NSError(domain: "OpenAIService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Error: Failed to parse JSON response. \(error.localizedDescription)"])
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

struct OpenAIResponse: Decodable {
    let choices: [Choice]
}

struct Choice: Decodable {
    let message: Message
}

struct Message: Decodable {
    let content: String
}
