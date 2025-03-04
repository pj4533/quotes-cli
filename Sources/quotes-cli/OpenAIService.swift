import Foundation
import os

struct OpenAIService {
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
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            logger.error("OPENAI_API_KEY not set.")
            throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: OPENAI_API_KEY not set."])
        }
        
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
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                logger.error("Invalid response type.")
                throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Invalid response."])
            }
            
            // Log all response headers to help debug rate limit issues
            logger.debug("Response status code: \(httpResponse.statusCode)")
            logger.debug("--- Response Headers ---")
            for (key, value) in httpResponse.allHeaderFields {
                let keyString = String(describing: key)
                let valueString = String(describing: value)
                logger.debug("\(keyString): \(valueString)")
            }
            
            // Log specific rate limit headers if they exist
            if let rateLimit = httpResponse.allHeaderFields["x-ratelimit-limit"] {
                let rateLimitString = String(describing: rateLimit)
                logger.notice("Rate Limit: \(rateLimitString)")
            }
            if let rateLimitRemaining = httpResponse.allHeaderFields["x-ratelimit-remaining"] {
                let remainingString = String(describing: rateLimitRemaining)
                logger.notice("Rate Limit Remaining: \(remainingString)")
            }
            if let rateLimitReset = httpResponse.allHeaderFields["x-ratelimit-reset"] {
                let resetString = String(describing: rateLimitReset)
                logger.notice("Rate Limit Reset: \(resetString)")
            }
            
            // Log response body
            let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
            logger.debug("--- Response Body ---\n\(responseBody)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                logger.error("Received HTTP \(httpResponse.statusCode). Response Body: \(responseBody)")
                throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: HTTP \(httpResponse.statusCode)."])
            }
            
            guard let openAIResponse = try? JSONDecoder().decode(OpenAIResponse.self, from: data) else {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
                logger.error("Failed to parse JSON response. Response Body: \(responseBody)")
                throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: Failed to parse JSON response."])
            }
            
            if let quote = openAIResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                return quote.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            } else {
                logger.error("No quote found in response.")
                throw NSError(domain: "", code: 1, userInfo: [NSLocalizedDescriptionKey: "Error: No quote found in response."])
            }
        } catch {
            logger.error("Error fetching quote: \(error.localizedDescription)")
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
