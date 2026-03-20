import SwiftUI
import Combine

class BrightnessManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var brightnessLevel: Double {
        didSet { UserDefaults.standard.set(brightnessLevel, forKey: "brightnessLevel") }
    }
    
    // Calibration parameter
    @Published var intensityMultiplier: Double {
        didSet { UserDefaults.standard.set(intensityMultiplier, forKey: "intensityMultiplier") }
    }
    
    // Singleton instance for easy access across windows
    static let shared = BrightnessManager()
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "isEnabled")
        self.brightnessLevel = UserDefaults.standard.object(forKey: "brightnessLevel") as? Double ?? 0.6
        self.intensityMultiplier = UserDefaults.standard.object(forKey: "intensityMultiplier") as? Double ?? 3.4
    }
}
