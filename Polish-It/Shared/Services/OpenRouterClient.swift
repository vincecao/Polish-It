import Foundation

class OpenRouterClient {
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    private let model = "deepseek/deepseek-chat-v3-0324:free"
    
    func polish(text: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask? {
        // Validate inputs
        guard !apiKey.isEmpty else {
            completion(.failure(createError(code: 401, message: "API key is missing")))
            return nil
        }
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(createError(code: 400, message: "Invalid URL")))
            return nil
        }
        
        // Create request
        let request = createRequest(url: url, text: text, apiKey: apiKey)
        
        // Send request
        Logger.log("Sending request to OpenRouter API", level: .info)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                Logger.log("Network error: \(error.localizedDescription)", level: .error)
                completion(.failure(error))
                return
            }
            
            self.handleResponse(data: data, response: response, completion: completion)
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Helper Methods
    
    private func createError(code: Int, message: String) -> NSError {
        return NSError(domain: "com.polish.it", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
    
    private func createRequest(url: URL, text: String, apiKey: String) -> URLRequest {
        let prompt = """
        Polish the following text while preserving its meaning.
        Improve clarity, flow, and readability. Keep the same tone and intent.
        Return only the polished text without any additional comments.
        
        Text: \(text)
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("Polish.It/1.0", forHTTPHeaderField: "HTTP-Referer")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            Logger.log("Failed to serialize request body: \(error.localizedDescription)", level: .error)
        }
        
        return request
    }
    
    private func handleResponse(data: Data?, response: URLResponse?, completion: @escaping (Result<String, Error>) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completion(.failure(createError(code: 0, message: "Invalid response")))
            return
        }
        
        Logger.log("Received response with status code: \(httpResponse.statusCode)", level: .info)
        
        guard let data = data else {
            completion(.failure(createError(code: 0, message: "No data received")))
            return
        }
        
        // Log response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            Logger.log("Response: \(responseString.truncated(to: 200))", level: .debug)
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if httpResponse.statusCode >= 400 {
                    handleErrorResponse(json: json, statusCode: httpResponse.statusCode, completion: completion)
                    return
                }
                
                handleSuccessResponse(json: json, completion: completion)
            } else {
                Logger.log("Failed to parse JSON response", level: .error)
                completion(.failure(createError(code: 0, message: "Failed to parse response")))
            }
        } catch {
            Logger.log("JSON parsing error: \(error.localizedDescription)", level: .error)
            completion(.failure(error))
        }
    }
    
    private func handleErrorResponse(json: [String: Any], statusCode: Int, completion: @escaping (Result<String, Error>) -> Void) {
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            Logger.log("API error: \(message)", level: .error)
            completion(.failure(createError(code: statusCode, message: message)))
        } else {
            completion(.failure(createError(code: statusCode, message: "API error: \(statusCode)")))
        }
    }
    
    private func handleSuccessResponse(json: [String: Any], completion: @escaping (Result<String, Error>) -> Void) {
        if let choices = json["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            Logger.log("Successfully received polished text", level: .info)
            completion(.success(content.trimmed))
        } else {
            Logger.log("Failed to parse response structure", level: .error)
            completion(.failure(createError(code: 0, message: "Failed to parse response")))
        }
    }
}
