import SwiftUI

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindows: [OverlayWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupOverlays()
        NotificationCenter.default.addObserver(self, selector: #selector(setupOverlays), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc func setupOverlays() {
        // Clear existing overlays
        for window in overlayWindows {
            window.close()
        }
        overlayWindows.removeAll()
        
        // Create an overlay only for the main screen
        guard let mainScreen = NSScreen.main else { return }
        
        let overlay = OverlayWindow(screen: mainScreen)
        // Order front without making it key to avoid focus changes
        overlay.orderFront(nil)
        overlay.orderFrontRegardless()
        overlayWindows.append(overlay)
    }
}

@main
struct IntiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("Inti", systemImage: "sun.max.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
