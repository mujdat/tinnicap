# TinniCap

<div align="center">

![TinniCap Icon](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Build](https://img.shields.io/badge/build-passing-brightgreen.svg)

**A native macOS menubar application that limits audio volume on individual devices.**

[Features](#features) • [Installation](#installation) • [Usage](#usage) • [Contributing](#contributing) • [License](#license)

</div>

---

## Why TinniCap?

Protect your hearing by preventing accidentally loud audio. TinniCap sits in your menubar and automatically limits volume on all your audio devices - from built-in speakers to Bluetooth headphones to external monitors.

Perfect for:
- 🎧 Preventing hearing damage from accidentally loud volumes
- 🏢 Maintaining safe audio levels in shared spaces
- 👨‍💻 Setting different limits for different devices
- 🌙 Keeping late-night audio at reasonable levels

## Features

### Core Functionality
- 🔊 **Per-Device Volume Limits**: Set individual limits for each audio device
- 🎯 **Auto-Detection**: Automatically detects all audio output devices
  - Built-in speakers
  - Bluetooth headphones and speakers
  - USB audio interfaces
  - HDMI/DisplayPort/Thunderbolt monitor audio
- 💾 **Persistent Settings**: Limits saved across system restarts
- ⚡️ **Real-Time Monitoring**: Checks volume every 500ms

### Enforcement Modes
- **Hard Cap Mode** (default): Automatically reduces volume when limit is exceeded
- **Warning Only Mode**: Shows notification but allows manual override

### Native & Lightweight
- Native Swift/SwiftUI application
- Minimal memory footprint
- No background processes beyond the menubar app
- Uses Apple's CoreAudio framework directly

## Requirements
- macOS 13.0 (Ventura) or later
- Xcode 15.0+ (for building from source)

## Installation

### Option 1: Build from Source

```bash
# Clone the repository
git clone https://github.com/mujdat/tinnicap.git
cd tinnicap

# Open in Xcode
open TinniCap.xcodeproj

# Build and run (⌘+R)

# Or use the build script:
./build.sh

# Copy to Applications folder
cp -r ./build/Build/Products/Release/TinniCap.app /Applications/
```

### Option 2: Using Xcode Command Line

```bash
xcodebuild -project TinniCap.xcodeproj \
           -scheme TinniCap \
           -configuration Release \
           build
```

## Usage

### Quick Start

1. **Launch TinniCap** - The app appears as a speaker icon in your menubar
2. **Click the icon** - See all detected audio devices
3. **Set a limit** - Click a device → "Set Volume Limit..." → Enter percentage (0-100)
4. **Done!** - The limit is now active and will persist across restarts

### Setting Volume Limits

<details>
<summary>Step-by-step guide</summary>

1. Click the TinniCap menubar icon
2. You'll see all detected audio devices listed
3. Click on any device to open its submenu
4. Select "Set Volume Limit..."
5. Enter a percentage (0-100)
   - Example: 75 = volume won't exceed 75%
6. Click "Set"
7. You'll see a confirmation notification

</details>

### Switching Enforcement Modes

- **Hard Cap Mode**: Click TinniCap icon → Select "Hard Cap (Enforce Limit)"
  - Volume is automatically reduced when limit is exceeded
  - Notification shows when enforcement occurs

- **Warning Only Mode**: Click TinniCap icon → Select "Warning Only"
  - Notification appears when limit is exceeded
  - Volume can still be manually increased

### Removing Limits

1. Click the device in the menubar menu
2. Select "Remove Limit"
3. The device will return to unrestricted operation

## Technical Details

### Architecture

```
TinniCap/
├── TinniCapApp.swift          # App entry point & lifecycle
├── MenuBarController.swift    # UI and user interactions
├── AudioDeviceService.swift   # CoreAudio integration
├── AudioDevice.swift          # Data models
└── SettingsManager.swift      # Persistence layer
```

### How It Works

1. **Device Discovery**: Uses CoreAudio's `kAudioHardwarePropertyDevices` to enumerate output devices
2. **Transport Detection**: Identifies device types (Bluetooth, USB, etc.) via `kAudioDevicePropertyTransportType`
3. **Volume Monitoring**: Polls `kAudioHardwareServiceDeviceProperty_VirtualMainVolume` every 500ms
4. **Volume Control**: Sets volume via `AudioObjectSetPropertyData` when limits are exceeded
5. **Persistence**: Stores limits and preferences in `UserDefaults`

### Device Support

| Device Type | Detection | Volume Control | Notes |
|------------|-----------|----------------|-------|
| Built-in Speakers | ✅ | ✅ | Fully supported |
| Bluetooth | ✅ | ✅ | May have slight delay |
| USB Audio | ✅ | ✅ | Most devices supported |
| HDMI/DisplayPort | ✅ | ✅ | Monitor audio supported |
| Pro Audio Interfaces | ✅ | ⚠️ | Some don't support programmatic control |

## Troubleshooting

<details>
<summary><strong>App doesn't appear in menubar</strong></summary>

- Check Activity Monitor to see if TinniCap is running
- Try quitting and relaunching the app
- Check System Settings → Login Items
</details>

<details>
<summary><strong>Volume limits not working</strong></summary>

- Verify the device supports volume control (some pro interfaces don't)
- Ensure the device is set as the current output device
- Check that you're in Hard Cap mode (not Warning Only)
</details>

<details>
<summary><strong>Device not detected</strong></summary>

- Confirm the device is connected and showing in Sound settings
- Try disconnecting and reconnecting the device
- Restart TinniCap
- Some devices may take a moment to appear after connection
</details>

## Contributing

Awesome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Guide
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Roadmap

Future enhancements planned:

- [ ] Launch at login option
- [ ] Slider instead of percentage input
- [ ] Decibel-accurate measurements (vs. percentage)
- [ ] Per-app volume limiting

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 🐛 **Bug reports**: [Open an issue](https://github.com/mujdat/tinnicap/issues)
- 💡 **Feature requests**: [Open an issue](https://github.com/mujdat/tinnicap/issues)