# Inti

Inti is a macOS native utility that unlocks the full brightness potential of your Apple Silicon MacBook Pro's Liquid Retina XDR display or external HDR monitor. By bypassing macOS's software brightness limits, Inti pushes your screen's backlight into its Extended Dynamic Range (EDR) hardware headroom securely and stably.

## Features
- **True HDR Brightness**: Utilizes pure Native Metal compositing to maintain the EDR multiplier effect without washing out screen colors.
- **Robust Background Stability**: Features a 60Hz background enforcement timer to defeat macOS WindowServer optimization, ensuring your brightness stays locked even when the app loses focus.
- **Menu Bar Native**: Operates entirely from the macOS Menu Bar (no Dock clutter).
- **Safe Multi-Monitor Support**: Automatically handles display reconnections and only applies the overdrive to the main HDR-capable screen.
- **Settings Persistence**: Remembers your preferred intensity and calibration state between launches.

## Installation
Currently, Inti must be built from source using Xcode.

1. Clone this repository.
2. Open `Package.swift` in Xcode 14 or newer.
3. Select the `Inti` scheme and run (`Cmd + R`).

## How it Works
Inti creates a full-screen, completely transparent, click-through `NSWindow` overlay. Instead of relying on fragile Core Animation compositing filters that macOS disables to save power, Inti uses an `MTKView` (Metal Kit) combined with a high-frequency `Timer`.

The Metal layer creates a `multiplyBlendMode` effect. When combined with values far beyond standard white (`> 1.0` in the `.extendedLinearSRGB` color space), it physically forces the monitor hardware to increase the LED backlight intensity, identical to how HDR videos are rendered system-wide.

## Disclaimer
Running your display at maximum HDR brightness for extended periods will significantly reduce battery life and may accelerate hardware degradation (such as Mini-LED wear or typical OLED burn-in if applicable). Use responsibly.

## License
MIT License
