import SwiftUI

struct SettingsView: View {
    @Binding var apiKey: String
    @State private var tempApiKey: String = ""
    @Environment(\.presentationMode) var presentationMode
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isHoveringSave = false
    @State private var isHoveringCancel = false
    
    var body: some View {
        ZStack {
            // Full window glass background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .leading, spacing: 16) {
                // Header
                Text("Polish.It API Settings")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary.opacity(0.8))
                    .padding(.top, 8)
                
                // API Key input
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
                
                Spacer()
                
                // Buttons
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
            .padding(.horizontal, 12)
            .padding(.vertical, 20)
            .frame(width: 450, height: 200)
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
        }
    }
    
    private func saveAPIKey() {
        let trimmedKey = tempApiKey.trimmed
        
        if trimmedKey.isEmpty {
            if KeychainManager.shared.deleteAPIKey() {
                apiKey = ""
                alertMessage = "API key has been cleared."
                showingAlert = true
                Logger.log("API key cleared from keychain", level: .info)
            } else {
                alertMessage = "Failed to clear API key. Please try again."
                showingAlert = true
                Logger.log("Failed to clear API key", level: .error)
            }
        } else {
            if KeychainManager.shared.saveAPIKey(trimmedKey) {
                apiKey = trimmedKey
                alertMessage = "API key has been saved securely."
                showingAlert = true
                Logger.log("API key saved to keychain", level: .info)
            } else {
                alertMessage = "Failed to save API key. Please try again."
                showingAlert = true
                Logger.log("Failed to save API key", level: .error)
            }
        }
    }
}

#Preview {
    SettingsView(apiKey: .constant("sk-sample-key"))
}