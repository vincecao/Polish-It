import SwiftUI

@main
struct PolishItApp: App {
    var body: some Scene {
        WindowGroup {
            #if os(macOS)
            MacContentView()
                .frame(minWidth: 600, minHeight: 400)
            #else
            ContentView()
            #endif
        }
        #if os(macOS)
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Polish.It") {
                    // Show a SwiftUI About dialog
                    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
                    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
                    
                    let aboutText = "Polish.It v\(version) (\(build))\n\nA simple app to polish text using OpenRouter API."
                    
                    let alert = NSAlert()
                    alert.messageText = "About Polish.It"
                    alert.informativeText = aboutText
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
            
            CommandGroup(replacing: .newItem) {}
            
            CommandMenu("Edit") {
                Button("Polish") {
                    NotificationCenter.default.post(name: NSNotification.Name("PolishText"), object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command])
                
                Button("Clear") {
                    NotificationCenter.default.post(name: NSNotification.Name("ClearText"), object: nil)
                }
                .keyboardShortcut("k", modifiers: [.command])
                
                Button("Copy Polished Text") {
                    NotificationCenter.default.post(name: NSNotification.Name("CopyText"), object: nil)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
            }
            
            CommandMenu("View") {
                Button("Settings") {
                    NotificationCenter.default.post(name: NSNotification.Name("OpenSettings"), object: nil)
                }
                .keyboardShortcut(",", modifiers: [.command])
            }
        }
        #endif
    }
}
