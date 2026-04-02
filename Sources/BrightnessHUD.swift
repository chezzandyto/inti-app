import Cocoa
import SwiftUI

/// A macOS-style HUD overlay that appears when adjusting brightness via hotkeys,
/// similar to the native volume/brightness indicator.
class BrightnessHUD {
    static let shared = BrightnessHUD()
    
    private var panel: NSPanel?
    private var dismissTimer: Timer?
    private var hostingView: NSHostingView<HUDContentView>?
    
    private init() {}
    
    /// Show or update the HUD with the current brightness level
    func show(level: Double, isEnabled: Bool) {
        dismissTimer?.invalidate()
        
        if panel == nil {
            createPanel()
        }
        
        // Update content
        hostingView?.rootView = HUDContentView(level: level, isEnabled: isEnabled)
        
        // Position at center-bottom of main screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelSize = CGSize(width: 220, height: 60)
            let x = screenFrame.midX - panelSize.width / 2
            let y = screenFrame.minY + 80
            panel?.setFrame(NSRect(x: x, y: y, width: panelSize.width, height: panelSize.height), display: true)
        }
        
        panel?.alphaValue = 1.0
        panel?.orderFrontRegardless()
        
        // Auto-dismiss after 1.5 seconds
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.dismiss()
        }
    }
    
    private func dismiss() {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            panel?.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            self?.panel?.orderOut(nil)
        })
    }
    
    private func createPanel() {
        let contentView = HUDContentView(level: 0, isEnabled: false)
        let hosting = NSHostingView(rootView: contentView)
        hostingView = hosting
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 60),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = false
        panel.ignoresMouseEvents = true
        panel.contentView = hosting
        
        self.panel = panel
    }
}

// MARK: - HUD SwiftUI View

struct HUDContentView: View {
    let level: Double
    let isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isEnabled ? "sun.max.fill" : "sun.max")
                .font(.system(size: 18))
                .foregroundColor(isEnabled ? .yellow : .gray)
                .frame(width: 24)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 6)
                    
                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isEnabled ? Color.yellow : Color.gray)
                        .frame(width: max(0, geo.size.width * level), height: 6)
                }
                .frame(maxHeight: .infinity)
            }
            
            Text("\(Int(level * 100))%")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            VisualEffectBlur()
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}

// MARK: - NSVisualEffectView wrapper for dark blur

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.wantsLayer = true
        view.layer?.cornerRadius = 14
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}
