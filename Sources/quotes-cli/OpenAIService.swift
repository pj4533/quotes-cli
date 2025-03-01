import Foundation
import os

struct OpenAIService {
    private let logger = Logger(subsystem: "com.yourapp.quotes-cli", category: "OpenAIService")
    
    func fetchQuote(theme: String?) async throws -> String {
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
        
        let prompt: String
        if let theme = theme, !theme.isEmpty {
            prompt = "Provide a short, compelling quote that embodies the themes of \(theme). Keep it under 10 words. Only have one concept though, don't combine ideas"
        } else {
            prompt = "Provide a short, compelling quote that uses a random theme. Keep it under 10 words. Only have one concept though, don't combine ideas"
        }
        
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
            
            guard (200...299).contains(httpResponse.statusCode) else {
                let responseBody = String(data: data, encoding: .utf8) ?? "No response body"
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
