import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var overlayWindows: [OverlayWindow] = []
    private var screenObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupOverlays()
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.setupOverlays()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up observer and overlay resources
        if let observer = screenObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        for window in overlayWindows {
            (window.contentView as? EDRMetalView)?.cleanup()
            window.close()
        }
        overlayWindows.removeAll()
    }

    private func setupOverlays() {
        // Clean up existing overlays
        for window in overlayWindows {
            (window.contentView as? EDRMetalView)?.cleanup()
            window.close()
        }
        overlayWindows.removeAll()
        
        // Create an overlay only for the main screen
        guard let mainScreen = NSScreen.main else { return }
        
        let overlay = OverlayWindow(screen: mainScreen)
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
