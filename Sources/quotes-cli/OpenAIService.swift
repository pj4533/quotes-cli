import Foundation
import DotEnv

struct OpenAIService {
    func fetchQuote(theme: String) -> String {
        guard let apiKey = DotEnv.get("OPENAI_API_KEY") else {
            return "Error: OPENAI_API_KEY not set."
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: String = ""
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "Error: Invalid URL."
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = "Provide a short, compelling quote that embodies the themes of \(theme). Keep it under 20 words."
        let jsonBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 60
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        } catch {
            return "Error: Failed to serialize JSON body."
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                result = "Error: \(error.localizedDescription)"
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                result = "Error: Invalid response."
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                result = "Error: HTTP \(httpResponse.statusCode)."
                return
            }
            
            guard let data = data else {
                result = "Error: No data received."
                return
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let quote = openAIResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                    result = quote
                } else {
                    result = "Error: No quote found in response."
                }
            } catch {
                result = "Error: Failed to parse JSON response."
            }
        }
        
        task.resume()
        semaphore.wait()
        return result
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
