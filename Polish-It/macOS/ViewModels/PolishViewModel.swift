import SwiftUI
import Combine

class PolishViewModel: ObservableObject {
    @Published var originalText: String = ""
    @Published var polishedText: String = ""
    @Published var apiKey: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    private let openRouterClient = OpenRouterClient()
    private var currentTask: URLSessionDataTask?
    
    // MARK: - Public Methods
    
    func loadAPIKey() {
        if let savedKey = KeychainManager.shared.getAPIKey() {
            apiKey = savedKey
            Logger.log("API key loaded from keychain", level: .info)
        } else {
            Logger.log("No API key found in keychain", level: .warning)
        }
    }
    
    func polishText() {
        // Validate inputs
        guard validateInputs() else { return }
        
        // Prepare for new request
        prepareForNewRequest()
        
        // Start loading
        isLoading = true
        Logger.log("Starting rephrasing process", level: .info)
        
        // Send request
        currentTask = openRouterClient.polish(text: originalText, apiKey: apiKey) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                defer { self.finishRequest() }
                
                self.handlePolishResult(result)
            }
        }
    }
    
    func clearText() {
        originalText = ""
        polishedText = ""
        errorMessage = ""
        Logger.log("Text cleared", level: .info)
    }
    
    func copyPolisheddText() {
        guard !polishedText.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(polishedText, forType: .string)
        
        Logger.log("Polished text copied to clipboard", level: .info)
    }
    
    // MARK: - Private Methods
    
    private func validateInputs() -> Bool {
        guard !originalText.isEmpty else { return false }
        
        guard !apiKey.isEmpty else {
            errorMessage = "Please enter your OpenRouter API key in Settings"
            showError("Please enter your OpenRouter API key in Settings")
            return false
        }
        
        return true
    }
    
    private func prepareForNewRequest() {
        // Cancel any existing request
        currentTask?.cancel()
        
        // Reset state
        isLoading = false
        errorMessage = ""
        
        // Only clear polished text if we don't already have a successful result
        if polishedText.isEmpty || !errorMessage.isEmpty {
            polishedText = ""
        }
    }
    
    private func finishRequest() {
        isLoading = false
        currentTask = nil
    }
    
    private func handlePolishResult(_ result: Result<String, Error>) {
        switch result {
        case .success(let polished):
            polishedText = polished
            errorMessage = ""
            Logger.log("Text successfully polished", level: .info)
            
        case .failure(let error as NSError) where error.code == NSURLErrorCancelled:
            Logger.log("Request cancelled", level: .info)
            // Don't show error for cancelled requests
            
        case .failure(let error):
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        let errorMsg = error.localizedDescription
        errorMessage = "Error: \(errorMsg)"
        
        // Only show alert for critical errors
        let nsError = error as NSError
        if nsError.code == 401 {
            showError("Authentication failed: Please check your API key")
        } else if nsError.code >= 500 {
            showError("Server error: \(errorMsg)")
        }
        
        Logger.log("Rephrasing error: \(errorMsg)", level: .error)
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
