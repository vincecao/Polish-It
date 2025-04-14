import SwiftUI

struct MacContentView: View {
    @StateObject private var viewModel = PolishViewModel()
    @State private var showSettings = false
    @State private var isHoveringPolish = false
    @State private var isHoveringCopy = false
    @State private var isHoveringClear = false
    
    var body: some View {
        ZStack {
            // Full window glass background
            VisualEffectView(material: .underWindowBackground, blendingMode: .behindWindow)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Toolbar with glass effect
                VisualEffectView(material: .titlebar, blendingMode: .withinWindow)
                    .frame(height: 44)
                    .overlay(
                        HStack {
                            Text("Polish.It")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary.opacity(0.8))
                            
                            Spacer()
                            
                            // Model indicator
                            HStack(spacing: 4) {
                                Text(viewModel.selectedModel.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary.opacity(0.7))
                                
                                if viewModel.selectedModel.isFree {
                                    Text("Free")
                                        .font(.system(size: 10))
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.green.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.05))
                            .cornerRadius(6)
                            
                            Button(action: { showSettings.toggle() }) {
                                Image(systemName: "gear")
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary.opacity(0.7))
                                    .frame(width: 28, height: 28)
                                    .background(
                                        Circle()
                                            .fill(Color.primary.opacity(0.1))
                                    )
                                    .contentShape(Circle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                        .padding(.horizontal, 16)
                    )
                
                // Main content area
                HSplitView {
                    // Input section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $viewModel.originalText)
                            .font(.system(size: 13))
                            .padding(10)
                            .background(
                                VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
                                    .cornerRadius(8)
                                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                            )
                            .frame(minHeight: 120)
                    }
                    .padding(12)
                    
                    // Output section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Polished")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        ZStack {
                            TextEditor(text: $viewModel.polishedText)
                                .font(.system(size: 13))
                                .disabled(viewModel.isLoading)
                                .padding(10)
                                .background(
                                    VisualEffectView(material: .contentBackground, blendingMode: .withinWindow)
                                        .cornerRadius(8)
                                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                        .frame(minHeight: 120)
                    }
                    .padding(12)
                }
                
                // Action bar with glass effect
                VisualEffectView(material: .titlebar, blendingMode: .withinWindow)
                    .frame(height: 52)
                    .overlay(
                        HStack(spacing: 12) {
                            Button("Clear") {
                                viewModel.clearText()
                            }
                            .buttonStyle(GlassButtonStyle(isHovering: $isHoveringClear))
                            .keyboardShortcut("k", modifiers: [.command])
                            
                            Spacer()
                            
                            Button("Copy") {
                                viewModel.copyPolisheddText()
                            }
                            .buttonStyle(GlassButtonStyle(isHovering: $isHoveringCopy))
                            .disabled(viewModel.polishedText.isEmpty)
                            
                            Button("Polish") {
                                viewModel.polishText()
                            }
                            .buttonStyle(GlassPrimaryButtonStyle(isHovering: $isHoveringPolish))
                            .disabled(viewModel.originalText.isEmpty)
                        }
                        .padding(.horizontal, 16)
                    )
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            viewModel.loadAPIKey()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(apiKey: $viewModel.apiKey, selectedModel: $viewModel.selectedModel)
        }
    }
}

struct GlassButtonStyle: ButtonStyle {
    @Binding var isHovering: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.primary.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                VisualEffectView(material: isHovering ? .selection : .underPageBackground, blendingMode: .withinWindow)
                    .cornerRadius(6)
            )
            .onHover { hovering in
                withAnimation { isHovering = hovering }
            }
    }
}

struct GlassPrimaryButtonStyle: ButtonStyle {
    @Binding var isHovering: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                VisualEffectView(material: isHovering ? .selection : .titlebar, blendingMode: .withinWindow)
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(isHovering ? Color.blue.opacity(0.3) : Color.blue.opacity(0.2))
                    )
            )
            .onHover { hovering in
                withAnimation { isHovering = hovering }
            }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}