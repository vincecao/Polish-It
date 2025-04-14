import SwiftUI

struct SettingsView: View {
    @Binding var apiKey: String
    @Binding var selectedModel: AIModel
    @State private var tempApiKey: String = ""
    @State private var tempSelectedModel: AIModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isHoveringSave = false
    @State private var isHoveringCancel = false
    @State private var showingApiKeyWarning = false
    
    init(apiKey: Binding<String>, selectedModel: Binding<AIModel>) {
        self._apiKey = apiKey
        self._selectedModel = selectedModel
        self._tempSelectedModel = State(initialValue: selectedModel.wrappedValue)
        self._tempApiKey = State(initialValue: "")
    }
    
    var body: some View {
        ZStack {
            // Full window glass background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 16) {
                headerView
                modelSelectionView
                apiKeyInputView
                Spacer()
                actionButtonsView
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .frame(width: 450, height: 280)
            .background(
                VisualEffectView(material: .popover, blendingMode: .withinWindow)
                    .cornerRadius(10)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 2)
            )
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("API Key"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"), action: {
                    presentationMode.wrappedValue.dismiss()
                })
            )
        }
        .onAppear {
            tempApiKey = apiKey
            tempSelectedModel = selectedModel
        }
    }
    
    // MARK: - Private Views
    
    private var headerView: some View {
        Text("Polish.It Settings")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.primary.opacity(0.8))
            .padding(.top, 8)
    }
    
    private var modelSelectionView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AI Model")
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.7))
            
            ModelPickerView(
                selectedModel: $tempSelectedModel,
                showingApiKeyWarning: $showingApiKeyWarning,
                apiKey: apiKey
            )
            
            ModelStatusView(
                showingApiKeyWarning: showingApiKeyWarning,
                isFreeModel: tempSelectedModel.isFree
            )
        }
    }
    
    private struct ModelPickerView: View {
        @Binding var selectedModel: AIModel
        @Binding var showingApiKeyWarning: Bool
        let apiKey: String
        
        var body: some View {
            ZStack {
                VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Picker("Model", selection: $selectedModel) {
                    ForEach(AIModel.availableModels) { model in
                        ModelPickerRow(model: model)
                            .tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(6)
                .onChange(of: selectedModel) { newModel in
                    if !newModel.isFree && apiKey.isEmpty {
                        showingApiKeyWarning = true
                    }
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .frame(height: 32)
        }
    }
    
    private struct ModelPickerRow: View {
        let model: AIModel
        
        var body: some View {
            HStack {
                Text(model.name)
                if model.isFree {
                    Text("Free")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
    }
    
    private struct ModelStatusView: View {
        let showingApiKeyWarning: Bool
        let isFreeModel: Bool
        
        var body: some View {
            if showingApiKeyWarning {
                Text("This model requires an API key")
                    .font(.system(size: 11))
                    .foregroundColor(.orange)
            } else if isFreeModel {
                Text("Free model - no API key required")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            }
        }
    }
    
    private var apiKeyInputView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("API Key")
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.7))
            
            ZStack(alignment: .leading) {
                VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
                    .cornerRadius(6)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                SecureField("sk-...", text: $tempApiKey)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .padding(8)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .frame(height: 32)
            
            Text("Your API key is stored securely in the Keychain")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
    
    private var actionButtonsView: some View {
        HStack {
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Cancel")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary.opacity(0.8))
                    .frame(width: 80)
                    .padding(.vertical, 6)
                    .background(
                        VisualEffectView(material: isHoveringCancel ? .selection : .underPageBackground, blendingMode: .withinWindow)
                            .cornerRadius(6)
                    )
                    .onHover { hovering in
                        withAnimation { isHoveringCancel = hovering }
                    }
            }
            .buttonStyle(BorderlessButtonStyle())
            .keyboardShortcut(.escape, modifiers: [])
            
            Button(action: {
                saveAPIKey()
            }) {
                Text("Save")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 80)
                    .padding(.vertical, 6)
                    .background(
                        VisualEffectView(material: isHoveringSave ? .selection : .titlebar, blendingMode: .withinWindow)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(isHoveringSave ? Color.blue.opacity(0.3) : Color.blue.opacity(0.2))
                            )
                    )
                    .onHover { hovering in
                        withAnimation { isHoveringSave = hovering }
                    }
            }
            .buttonStyle(BorderlessButtonStyle())
            .keyboardShortcut(.return, modifiers: [])
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Private Methods
    
    private func saveAPIKey() {
        let trimmedKey = tempApiKey.trimmed
        
        // Save API key if provided or clear it if empty
        if trimmedKey.isEmpty {
            if KeychainManager.shared.deleteAPIKey() {
                apiKey = ""
                Logger.log("API key cleared from keychain", level: .info)
            } else {
                Logger.log("Failed to clear API key", level: .error)
            }
        } else {
            if KeychainManager.shared.saveAPIKey(trimmedKey) {
                apiKey = trimmedKey
                Logger.log("API key saved to keychain", level: .info)
            } else {
                Logger.log("Failed to save API key", level: .error)
            }
        }
        
        // Save selected model
        if KeychainManager.shared.saveSelectedModel(tempSelectedModel.id) {
            selectedModel = tempSelectedModel
            Logger.log("Model saved: \(tempSelectedModel.name)", level: .info)
        } else {
            Logger.log("Failed to save model", level: .error)
        }
        
        // Show confirmation
        if !tempSelectedModel.isFree && trimmedKey.isEmpty {
            alertMessage = "Warning: You selected a paid model but didn't provide an API key."
        } else {
            alertMessage = "Settings saved successfully."
        }
        showingAlert = true
    }
}

#Preview {
    SettingsView(apiKey: .constant("sk-sample-key"), selectedModel: .constant(AIModel(id: "deepseek/deepseek-chat-v3-0324:free", name: "DeepSeek Chat v3 (Free)", isFree: true)))
}
