import Cocoa
import SwiftUI
import Combine
import MetalKit

class OverlayWindow: NSWindow {
    private var cancellables = Set<AnyCancellable>()
    
    init(screen: NSScreen) {
        let contentRect = screen.frame
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
        
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        
        // Create the EDR view
        let edrView = EDRMetalView(frame: contentRect)
        self.contentView = edrView
        
        // Subscribe to all relevant changes
        BrightnessManager.shared.$isEnabled
            .combineLatest(BrightnessManager.shared.$brightnessLevel,
                           BrightnessManager.shared.$alphaValue,
                           BrightnessManager.shared.$intensityMultiplier)
            .debounce(for: .milliseconds(16), scheduler: RunLoop.main) // Limit to ~60fps
            .sink { [weak self] isEnabled, level, alphaVal, intensityMult in
                self?.updateBrightness(isEnabled: isEnabled, level: level, alphaVal: alphaVal, intensityMult: intensityMult)
            }
            .store(in: &cancellables)
    }
    
    private func updateBrightness(isEnabled: Bool, level: Double, alphaVal: Double, intensityMult: Double) {
        guard let edrView = self.contentView as? EDRMetalView else { return }
        
        if !isEnabled {
            edrView.setBrightness(0.0, alphaVal: alphaVal)
        } else {
            // Clamp intensity to a safe max to prevent white screen instability
            let safeMult = min(intensityMult, 5.0)
            
            // Map 0.0 - 1.0 to a brightness multiplier.
            let boost = 1.0 + (level * (safeMult - 1.0))
            edrView.setBrightness(boost, alphaVal: alphaVal)
        }
    }
    
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect {
        return screen?.frame ?? frameRect
    }
    
    // Prevent the window from ever becoming key or main.
    // This stops macOS from sending activation/deactivation events to this window
    // when the user clicks elsewhere, which can cause CoreAnimation to strip the 
    // compositingFilter and cause the "solid white" screen bug.
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}

class EDRMetalView: MTKView, MTKViewDelegate {
    
    private var commandQueue: MTLCommandQueue?
    private var currentComponent: Double = 0.0
    private var currentAlpha: Double = 1.0
    
    override init(frame frameRect: NSRect, device: MTLDevice?) {
        let defaultDevice = device ?? MTLCreateSystemDefaultDevice()
        super.init(frame: frameRect, device: defaultDevice)
        setupMetal()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        setupMetal()
    }
    
    private func setupMetal() {
        guard let device = self.device else { return }
        self.commandQueue = device.makeCommandQueue()
        
        self.delegate = self
        
        // MTKView configuration
        self.colorPixelFormat = .rgba16Float // 16-bit float for HDR
        self.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        self.clearColor = MTLClearColorMake(0, 0, 0, 0)
        
        // Performance: only draw when we say so
        self.enableSetNeedsDisplay = true
        self.isPaused = true
        
        // Layer configuration
        guard let metalLayer = self.layer as? CAMetalLayer else { return }
        metalLayer.wantsExtendedDynamicRangeContent = true
        metalLayer.isOpaque = false // crucial for overlay
        metalLayer.backgroundColor = NSColor.clear.cgColor
        metalLayer.compositingFilter = "multiplyBlendMode"
    }
    
    func setBrightness(_ value: Double, alphaVal: Double) {
        if value <= 1.01 {
            self.currentComponent = 0.0
            self.currentAlpha = 0.0
            self.layer?.compositingFilter = nil // Remove filter when disabled to save power
        } else {
            self.currentComponent = value
            self.currentAlpha = alphaVal
            self.layer?.compositingFilter = "multiplyBlendMode"
        }
        
        // Trigger a redraw
        DispatchQueue.main.async {
            self.needsDisplay = true
        }
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if necessary, usually handled by MTKView itself
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandQueue = self.commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        if currentComponent == 0.0 {
            // If disabled, just clear to transparent
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        } else {
            // For multiplyBlendMode, we just fill the screen with the multiplier color.
            let c = currentComponent
            let a = currentAlpha
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(c, c, c, a)
        }
        
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
