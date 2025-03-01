import Foundation

struct OpenAIService {
    func fetchQuote(theme: String) throws -> String {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("Error: OPENAI_API_KEY not set.")
            return "Error: OPENAI_API_KEY not set."
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        var result: String = ""
        let resultQueue = DispatchQueue(label: "resultQueue")
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "Error: Invalid URL."
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = "Provide a short, compelling quote that embodies the themes of \(theme). Keep it under 10 words. Only have one concept though, dont combine ideas"
        let jsonBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        } catch {
            return "Error: Failed to serialize JSON body."
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                resultQueue.sync {
                    result = "Error: \(error.localizedDescription)"
                }
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                resultQueue.sync {
                    result = "Error: Invalid response."
                }
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                resultQueue.sync {
                    result = "Error: HTTP \(httpResponse.statusCode)."
                }
                return
            }
            
            guard let data = data else {
                resultQueue.sync {
                    result = "Error: No data received."
                }
                return
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let quote = openAIResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                    resultQueue.sync {
                        result = quote.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    }
                } else {
                    resultQueue.sync {
                        result = "Error: No quote found in response."
                    }
                }
            } catch {
                resultQueue.sync {
                    result = "Error: Failed to parse JSON response."
                }
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
