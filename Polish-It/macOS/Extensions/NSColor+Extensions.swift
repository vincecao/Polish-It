import AppKit

extension NSColor {
    static var accentColor: NSColor {
        return NSColor(named: "AccentColor") ?? NSColor.systemBlue
    }
    
    static var textEditorBackgroundColor: NSColor {
        return NSColor.controlBackgroundColor
    }
    
    static var secondaryBackgroundColor: NSColor {
        if #available(macOS 10.14, *) {
            return NSColor.controlBackgroundColor
        } else {
            return NSColor.lightGray.withAlphaComponent(0.1)
        }
    }
}