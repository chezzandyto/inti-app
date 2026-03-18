import SwiftUI
import Combine

class BrightnessManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var brightnessLevel: Double {
        didSet { UserDefaults.standard.set(brightnessLevel, forKey: "brightnessLevel") }
    }
    
    // Calibration parameters
    // For multiplyBlendMode, alpha should be 1.0 (fully active)
    @Published var alphaValue: Double {
        didSet { UserDefaults.standard.set(alphaValue, forKey: "alphaValue") }
    }
    @Published var intensityMultiplier: Double {
        didSet { UserDefaults.standard.set(intensityMultiplier, forKey: "intensityMultiplier") }
    }
    
    // Singleton instance for easy access across windows
    static let shared = BrightnessManager()
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")
        self.brightnessLevel = UserDefaults.standard.object(forKey: "brightnessLevel") as? Double ?? 0.0
        self.alphaValue = UserDefaults.standard.object(forKey: "alphaValue") as? Double ?? 1.0
        self.intensityMultiplier = UserDefaults.standard.object(forKey: "intensityMultiplier") as? Double ?? 1.0
    }
}
