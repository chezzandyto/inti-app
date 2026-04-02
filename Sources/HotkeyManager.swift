import Cocoa
import Carbon

/// Manages global keyboard shortcuts that work even when Inti is not focused.
/// Uses Carbon HotKey API for true system-wide hotkeys.
class HotkeyManager {
    static let shared = HotkeyManager()
    
    // Step size for brightness adjustments (10%)
    private let brightnessStep: Double = 0.1
    
    // Carbon hotkey references
    private var toggleHotkeyRef: EventHotKeyRef?
    private var brightnessUpHotkeyRef: EventHotKeyRef?
    private var brightnessDownHotkeyRef: EventHotKeyRef?
    
    // Unique hotkey IDs
    private let toggleHotkeyID = EventHotKeyID(signature: 0x494E5449, id: 1)     // "INTI" + 1
    private let brightnessUpHotkeyID = EventHotKeyID(signature: 0x494E5449, id: 2)
    private let brightnessDownHotkeyID = EventHotKeyID(signature: 0x494E5449, id: 3)
    
    private init() {}
    
    func register() {
        // Install the Carbon event handler once
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyHandler,
            1,
            &eventType,
            nil,
            nil
        )
        
        // ⌘⇧B → Toggle HDR boost
        let toggleID = toggleHotkeyID
        RegisterEventHotKey(
            UInt32(kVK_ANSI_B),                        // B key
            UInt32(cmdKey | shiftKey),                  // ⌘⇧
            toggleID,
            GetApplicationEventTarget(),
            0,
            &toggleHotkeyRef
        )
        
        // ⌘⇧↑ → Brightness up
        let upID = brightnessUpHotkeyID
        RegisterEventHotKey(
            UInt32(kVK_UpArrow),                       // ↑
            UInt32(cmdKey | shiftKey),                  // ⌘⇧
            upID,
            GetApplicationEventTarget(),
            0,
            &brightnessUpHotkeyRef
        )
        
        // ⌘⇧↓ → Brightness down
        let downID = brightnessDownHotkeyID
        RegisterEventHotKey(
            UInt32(kVK_DownArrow),                     // ↓
            UInt32(cmdKey | shiftKey),                  // ⌘⇧
            downID,
            GetApplicationEventTarget(),
            0,
            &brightnessDownHotkeyRef
        )
    }
    
    func unregister() {
        if let ref = toggleHotkeyRef { UnregisterEventHotKey(ref) }
        if let ref = brightnessUpHotkeyRef { UnregisterEventHotKey(ref) }
        if let ref = brightnessDownHotkeyRef { UnregisterEventHotKey(ref) }
    }
    
    // MARK: - Actions
    
    func toggleBrightness() {
        let manager = BrightnessManager.shared
        manager.isEnabled.toggle()
        BrightnessHUD.shared.show(level: manager.brightnessLevel, isEnabled: manager.isEnabled)
    }
    
    func increaseBrightness() {
        let manager = BrightnessManager.shared
        if !manager.isEnabled { manager.isEnabled = true }
        manager.brightnessLevel = min(1.0, manager.brightnessLevel + brightnessStep)
        BrightnessHUD.shared.show(level: manager.brightnessLevel, isEnabled: manager.isEnabled)
    }
    
    func decreaseBrightness() {
        let manager = BrightnessManager.shared
        manager.brightnessLevel = max(0.0, manager.brightnessLevel - brightnessStep)
        if manager.brightnessLevel <= 0.0 { manager.isEnabled = false }
        BrightnessHUD.shared.show(level: manager.brightnessLevel, isEnabled: manager.isEnabled)
    }
}

// MARK: - Carbon Event Handler (C function pointer)

private func hotkeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event = event else { return OSStatus(eventNotHandledErr) }
    
    var hotkeyID = EventHotKeyID()
    GetEventParameter(
        event,
        UInt32(kEventParamDirectObject),
        UInt32(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )
    
    let manager = HotkeyManager.shared
    switch hotkeyID.id {
    case 1: manager.toggleBrightness()
    case 2: manager.increaseBrightness()
    case 3: manager.decreaseBrightness()
    default: break
    }
    
    return noErr
}
