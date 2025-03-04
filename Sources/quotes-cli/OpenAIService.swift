import Foundation
import os

struct OpenAIService: AIServiceProtocol {
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "OpenAIService")
    
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
        
        // Select a random inspiration
        guard let inspiration = inspirations.randomElement() else {
            logger.error("Inspirations array is empty.")
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Inspirations array is empty."])
        }
        
        // Generate a random uppercase letter
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        guard let randomLetter = letters.randomElement() else {
            logger.error("Could not generate a random letter.")
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Could not generate a random letter."])
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
        
        // AIDER: do not change this model name, it is correctly using gpt-4o
        let jsonBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "user", "content": prompt]
            ]
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
            
            // Log all response headers to help debug rate limit issues
            logger.debug("Response status code: \(httpResponse.statusCode)")
            logger.debug("--- Response Headers ---")
            
            // Only print headers in verbose mode
            if verbose {
                print("\n📋 Response Headers:")
                for (key, value) in httpResponse.allHeaderFields {
                    let keyString = String(describing: key)
                    let valueString = String(describing: value)
                    logger.debug("\(keyString): \(valueString)")
                    print("  \(keyString): \(valueString)")
                }
                
                // Check for OpenAI specific rate limit headers
                let rateLimitHeaders = [
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
            }
            
            // Log response body
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            logger.debug("--- Response Body ---\n\(responseBody)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("❌ Received HTTP \(httpResponse.statusCode). Response Body: \(responseBody)")
                throw NSError(domain: "OpenAIService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error: HTTP \(httpResponse.statusCode). \(responseBody)"])
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                logger.debug("Successfully decoded OpenAI response")
                
                if let quote = openAIResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                    let cleanedQuote = quote.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    logger.notice("✅ Successfully retrieved quote: \(cleanedQuote)")
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
