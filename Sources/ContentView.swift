import SwiftUI

struct ContentView: View {
    @ObservedObject private var manager = BrightnessManager.shared
    @State private var showAdvanced = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Inti")
                    .font(.headline)
                Spacer()
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Quit")
            }
            
            Toggle(isOn: $manager.isEnabled) {
                Label("Enable HDR Boost", systemImage: manager.isEnabled ? "sun.max.fill" : "sun.max")
            }
            .toggleStyle(.switch)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sun.min")
                        .foregroundColor(.secondary)
                    Slider(value: $manager.brightnessLevel, in: 0.0...1.0)
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            DisclosureGroup("Advanced Calibration", isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Alpha: \(manager.alphaValue, specifier: "%.2f")")
                        Slider(value: $manager.alphaValue, in: 0.0...1.0)
                    }
                    VStack(alignment: .leading) {
                        Text("Intensity: \(manager.intensityMultiplier, specifier: "%.1f")x")
                        Slider(value: $manager.intensityMultiplier, in: 1.0...5.0)
                    }
                }
                .padding(.top, 8)
            }
            .font(.caption)
            
            Text("High brightness consumes more battery.")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(width: 250)
    }
}
