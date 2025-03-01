import Foundation

class ResultHolder {
    private var _value: String = ""
    private let queue = DispatchQueue(label: "resultHolderQueue")

    func set(_ value: String) {
        queue.sync {
            _value = value
        }
    }

    func get() -> String {
        return queue.sync {
            _value
        }
    }
}

struct OpenAIService {
    func fetchQuote(theme: String) throws -> String {
        guard let apiKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] else {
            print("Error: OPENAI_API_KEY not set.")
            return "Error: OPENAI_API_KEY not set."
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let resultHolder = ResultHolder()
        
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            return "Error: Invalid URL."
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let prompt = "Provide a short, compelling quote that embodies the themes of \(theme). Keep it under 10 words. Only have one concept though, dont combine ideas"
        let jsonBody: [String: Any] = [
            "model": "gpt-4",
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
                resultHolder.set("Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                resultHolder.set("Error: Invalid response.")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                resultHolder.set("Error: HTTP \(httpResponse.statusCode).")
                return
            }
            
            guard let data = data else {
                resultHolder.set("Error: No data received.")
                return
            }
            
            do {
                let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                if let quote = openAIResponse.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) {
                    resultHolder.set(quote.trimmingCharacters(in: CharacterSet(charactersIn: "\"")))
                } else {
                    resultHolder.set("Error: No quote found in response.")
                }
            } catch {
                resultHolder.set("Error: Failed to parse JSON response.")
            }
        }
        
        task.resume()
        semaphore.wait()
        return resultHolder.get()
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
