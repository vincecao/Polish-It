import Foundation

struct AIModel: Identifiable, Hashable, Equatable, Codable {
    let id: String
    let name: String
    let isFree: Bool
    
    static let availableModels: [AIModel] = [
        AIModel(id: "google/gemini-2.0-flash-thinking-exp:free", name: "Gemini 2.0 Flash (Free)", isFree: true),
        AIModel(id: "google/gemini-2.0-flash-thinking-exp-1219:free", name: "Gemini 2.0 Flash 1219 (Free)", isFree: true),
        AIModel(id: "nvidia/llama-3.1-nemotron-ultra-253b-v1:free", name: "Llama 3.1 Nemotron Ultra (Free)", isFree: true),
        AIModel(id: "featherless/qwerky-72b:free", name: "Qwerky 72B (Free)", isFree: true),
        AIModel(id: "meta-llama/llama-4-scout:free", name: "Llama 4 Scout (Free)", isFree: true),
        AIModel(id: "deepseek/deepseek-chat-v3-0324:free", name: "DeepSeek Chat v3 (Free)", isFree: true),
        AIModel(id: "google/gemini-2.0-flash-001", name: "Gemini 2.0 Flash", isFree: false),
        AIModel(id: "openai/gpt-4o-mini", name: "GPT-4o Mini", isFree: false),
        AIModel(id: "openrouter/optimus-alpha", name: "Optimus Alpha", isFree: false),
        AIModel(id: "meta-llama/llama-3.3-70b-instruct", name: "Llama 3.3 70B", isFree: false)
    ]
    
    static let defaultModel = availableModels.first(where: { $0.id == "deepseek/deepseek-chat-v3-0324:free" }) ?? availableModels[0]
    static let freeModelApiKey = "sk-or-v1-free-model-key" // Will be replaced during compilation
}

class OpenRouterClient {
    private let baseURL = "https://openrouter.ai/api/v1/chat/completions"
    
    func polish(text: String, apiKey: String, model: AIModel, completion: @escaping (Result<String, Error>) -> Void) -> URLSessionDataTask? {
        // Validate inputs
        guard !text.isEmpty else {
            completion(.failure(createError(code: 400, message: "Text cannot be empty")))
            return nil
        }
        
        guard let url = URL(string: baseURL) else {
            completion(.failure(createError(code: 400, message: "Invalid URL")))
            return nil
        }
        
        // Create request
        let request = createRequest(url: url, text: text, apiKey: apiKey, model: model)
        
        // Send request
        Logger.log("Sending request to OpenRouter API with model: \(model.name)", level: .info)
        
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
    
    private func createRequest(url: URL, text: String, apiKey: String, model: AIModel) -> URLRequest {
        let prompt = """
        Polish the following text while preserving its meaning.
        Improve clarity, flow, and readability. Keep the same tone and intent.
        Return only the polished text without any additional comments.
        
        Text: \(text)
        """
        
        let requestBody: [String: Any] = [
            "model": model.id,
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
    
    private func createError(code: Int, message: String) -> NSError {
        return NSError(domain: "com.polish.it", code: code, userInfo: [NSLocalizedDescriptionKey: message])
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
