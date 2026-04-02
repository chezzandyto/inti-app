import Cocoa
import Combine
import MetalKit

class OverlayWindow: NSWindow {
    private var cancellables = Set<AnyCancellable>()
    
    init(screen: NSScreen) {
        var contentRect = screen.frame
        // HACK: Defeat macOS "Direct Display" / Hardware Overlay promotion.
        // If the window is perfectly full-screen, macOS promotes it. When the app loses
        // focus, WindowServer strips the compositingFilter, resulting in a solid white screen.
        // Making the window 1 point larger bypasses this buggy optimization.
        contentRect.size.width += 1.0
        contentRect.size.height += 1.0
        
        super.init(contentRect: contentRect,
                   styleMask: [.borderless, .fullSizeContentView],
                   backing: .buffered,
                   defer: false)
                   
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .transient, .ignoresCycle, .fullScreenAuxiliary]
        self.animationBehavior = .none // Prevent fade animations that might reveal the filter dropping
        self.sharingType = .none // Hides from screen capture
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = true
        self.isReleasedWhenClosed = false // Fix EXC_BAD_ACCESS on display disconnect
        
        // Create the EDR view
        let edrView = EDRMetalView(frame: contentRect)
        self.contentView = edrView
        
        // Subscribe to all relevant changes
        BrightnessManager.shared.$isEnabled
            .combineLatest(BrightnessManager.shared.$brightnessLevel,
                           BrightnessManager.shared.$intensityMultiplier)
            .debounce(for: .milliseconds(16), scheduler: RunLoop.main) // Limit to ~60fps
            .sink { [weak self] isEnabled, level, intensityMult in
                self?.updateBrightness(isEnabled: isEnabled, level: level, intensityMult: intensityMult)
            }
            .store(in: &cancellables)
    }
    
    private func updateBrightness(isEnabled: Bool, level: Double, intensityMult: Double) {
        guard let edrView = self.contentView as? EDRMetalView else { return }
        
        if !isEnabled {
            edrView.setBrightness(0.0)
        } else {
            // Clamp intensity to a safe max to prevent white screen instability
            let safeMult = min(intensityMult, 5.0)
            
            // Map 0.0 - 1.0 to a brightness multiplier.
            let boost = 1.0 + (level * (safeMult - 1.0))
            edrView.setBrightness(boost)
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
    private var enforcementTimer: Timer?
    
    override init(frame frameRect: NSRect, device: MTLDevice?) {
        let defaultDevice = device ?? MTLCreateSystemDefaultDevice()
        super.init(frame: frameRect, device: defaultDevice)
        setupMetal()
        // Timer starts lazily via setBrightness() when effect is enabled
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.device = MTLCreateSystemDefaultDevice()
        setupMetal()
    }
    
    deinit {
        enforcementTimer?.invalidate()
    }
    
    private func setupMetal() {
        guard let device = self.device else { return }
        self.commandQueue = device.makeCommandQueue()
        
        self.delegate = self
        
        // MTKView configuration
        self.colorPixelFormat = .rgba16Float // 16-bit float for HDR
        self.colorspace = CGColorSpace(name: CGColorSpace.extendedLinearSRGB)
        self.clearColor = MTLClearColorMake(0, 0, 0, 0)
        
        // Performance: limit frame rate to save GPU/CPU
        self.enableSetNeedsDisplay = true
        self.isPaused = true
        self.preferredFramesPerSecond = 15 // Limit to 15fps when unpaused
        
        // Layer configuration
        guard let metalLayer = self.layer as? CAMetalLayer else { return }
        metalLayer.wantsExtendedDynamicRangeContent = true
        metalLayer.isOpaque = false // crucial for overlay
        metalLayer.backgroundColor = NSColor.clear.cgColor
        metalLayer.compositingFilter = "multiplyBlendMode"
        
        // Memory: reduce from 3 drawables (default) to 2
        // We only draw once when values change, so no need for triple-buffering
        metalLayer.maximumDrawableCount = 2
    }
    
    private func startEnforcementTimer() {
        guard enforcementTimer == nil else { return }
        // We MUST run this at 60Hz. Changing this to lower frequencies causes a white screen
        // because macOS extremely aggressively strips the filter from unfocused windows.
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.enforceBlendMode()
        }
        RunLoop.main.add(timer, forMode: .common)
        enforcementTimer = timer
    }
    
    private func stopEnforcementTimer() {
        enforcementTimer?.invalidate()
        enforcementTimer = nil
    }
    
    private func enforceBlendMode() {
        // Only re-apply if macOS actually stripped it — avoids unnecessary GPU work
        let currentFilter = self.layer?.compositingFilter as? String
        if currentFilter != "multiplyBlendMode" {
            print("Filter stripped by OS! Current is: \(String(describing: currentFilter))")
            self.layer?.compositingFilter = "multiplyBlendMode"
            self.needsDisplay = true
        }
    }
    
    /// Call before closing the parent window to ensure clean teardown
    func cleanup() {
        stopEnforcementTimer()
    }
    
    func setBrightness(_ value: Double) {
        if value <= 1.01 {
            self.currentComponent = 0.0
            self.currentAlpha = 0.0
            self.layer?.compositingFilter = nil
            self.isPaused = true
            stopEnforcementTimer() // Save battery when disabled
        } else {
            self.currentComponent = value
            self.currentAlpha = 1.0 // Always full opacity for multiplyBlendMode
            self.layer?.compositingFilter = "multiplyBlendMode"
            self.isPaused = false // Must not be paused or macOS drops the filter
            startEnforcementTimer()
        }
        
        self.needsDisplay = true
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor,
              let commandQueue = self.commandQueue,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        if currentComponent <= 0.0 {
            // Disabled
            renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        } else {
            // Multiplication overlay. We fill the screen with the multiplier value.
            // If pixel is 0.5 and we clear with 2.0, result is 1.0.
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
