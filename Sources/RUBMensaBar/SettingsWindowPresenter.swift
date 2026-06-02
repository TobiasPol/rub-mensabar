import AppKit
import SwiftUI

enum SettingsWindowPresenter {
    private static var fallbackWindow: NSWindow?

    static func open() {
        NSApp.activate(ignoringOtherApps: true)
        openFallbackWindow()
    }

    private static func openFallbackWindow() {
        if fallbackWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 540, height: 380),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Einstellungen"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.isReleasedWhenClosed = false
            window.center()
            fallbackWindow = window
        }

        fallbackWindow?.makeKeyAndOrderFront(nil)
    }
}
