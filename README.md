# Inti

Inti is a macOS native utility that unlocks the full brightness potential of your Apple Silicon MacBook Pro's Liquid Retina XDR display or external HDR monitor. By bypassing macOS's software brightness limits, Inti pushes your screen's backlight into its Extended Dynamic Range (EDR) hardware headroom securely and stably.

## Features
- **True HDR Brightness**: Utilizes pure Native Metal compositing to maintain the EDR multiplier effect without washing out screen colors.
- **Robust Background Stability**: Features a 60Hz background enforcement timer to defeat macOS WindowServer optimization, ensuring your brightness stays locked even when the app loses focus.
- **Menu Bar Native**: Operates entirely from the macOS Menu Bar (no Dock clutter).
- **Safe Multi-Monitor Support**: Automatically handles display reconnections and only applies the overdrive to the main HDR-capable screen.
- **Settings Persistence**: Remembers your preferred intensity and calibration state between launches.

## Requirements
- macOS 13.0 (Ventura) or later
- An XDR-capable display (e.g., MacBook Pro 14"/16" with Liquid Retina XDR, or Pro Display XDR)
- Xcode 14+ or Swift 5.9+ command line tools

## Installation

### Option A: Build the `.app` bundle (recommended)
```bash
git clone https://github.com/chezzandyto/inti-app.git
cd inti-app
chmod +x scripts/build-app.sh
./scripts/build-app.sh
```
The compiled `Inti.app` will be at `build/Inti.app`. Drag it to your `/Applications` folder or run it directly with `open build/Inti.app`.

### Option B: Run from Xcode
1. Clone this repository.
2. Open `Package.swift` in Xcode 14 or newer.
3. Select the `Inti` scheme and run (`Cmd + R`).

### Option C: Run from terminal
```bash
swift build -c release
.build/release/Inti
```

## How it Works
Inti creates a full-screen, completely transparent, click-through `NSWindow` overlay. Instead of relying on fragile Core Animation compositing filters that macOS disables to save power, Inti uses an `MTKView` (Metal Kit) combined with a high-frequency `Timer`.

The Metal layer creates a `multiplyBlendMode` effect. When combined with values far beyond standard white (`> 1.0` in the `.extendedLinearSRGB` color space), it physically forces the monitor hardware to increase the LED backlight intensity, identical to how HDR videos are rendered system-wide.

## Known Limitations
- **Cursor appearance**: The macOS cursor may appear slightly darker (grey edges instead of white) while the HDR boost is active. This is an inherent limitation of the `multiplyBlendMode` compositing technique — it can only brighten content below the overlay, but the hardware cursor is rendered by the system at SDR levels and cannot be affected by any window-level compositing filter.

## Disclaimer
Running your display at maximum HDR brightness for extended periods will significantly reduce battery life and may accelerate hardware degradation (such as Mini-LED wear or typical OLED burn-in if applicable). Use responsibly.

## License
MIT License
