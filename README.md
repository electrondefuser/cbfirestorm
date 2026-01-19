# Cosmic Byte Firestorm Controller

> **Disclaimer:** This is an independent, community-developed tool created through reverse engineering. We are not affiliated with, endorsed by, or connected to Cosmic Byte or any of its parent companies. This tool is provided as-is for educational and interoperability purposes. Use at your own risk.

## Overview

An unofficial command-line controller for the Cosmic Byte Firestorm gaming mouse, enabling RGB effect customization and DPI configuration on Linux systems. This tool provides full control over your mouse's lighting effects, colors, and sensitivity settings without requiring the official Windows software.

### Features

- **RGB LED Control**: Configure 8 individual colors and choose from 35+ animation effects
- **DPI Configuration**: Set up to 6 custom DPI levels (100-25600 in 100 DPI increments)
- **Per-DPI Color Indicators**: Assign unique colors to each DPI level for visual feedback
- **Profile Management**: Save and restore your preferred settings
- **No Dependencies**: Available as a single standalone binary

### Supported Device

- **Product**: Cosmic Byte Firestorm Gaming Mouse
- **Vendor ID**: `0x04d9`
- **Product ID**: `0xa09f`

## Installation

### Quick Install (Recommended)

The simplest method is using the provided installation script, which installs a pre-built binary to `/usr/local/bin/cosmic-mouse`:
Make the installation script executable and run it.

### Alternative Installation Methods

**Method 1: System-wide Python Package**

Install directly via pip for system-wide access. Requires Python and pip to be installed.

**Method 2: Build Binary Yourself**

Build the binary from source using PyInstaller. Requires Python, pip, and the ability to create virtual environments.

**Method 3: Run from Source**

Run directly from the Python source without building. Requires Python and the ability to create virtual environments.

Detailed installation commands are available in the repository.

## Usage

### RGB Commands

Control LED effects and colors. Commands require sudo for USB device access:

- **Set Effect**: Apply animation effects like breathing, wave, neon, etc.
- **Set Colors**: Use predefined color profiles (rainbow, fire, ocean) or specify custom RGB values
- **List Options**: View all available effects and color profiles

### DPI Commands

Configure mouse sensitivity levels:

- **Set Mode**: Choose how many DPI levels to use (1-6)
- **Set Values**: Specify DPI values for each level and which level is active
- **Set Colors**: Assign indicator colors to each DPI level
- **List Options**: View current DPI configuration

### Profile Commands

Manage saved configurations. Most profile commands don't require sudo:

- **Show**: Display current profile settings
- **Reset**: Restore default settings
- **Apply**: Send saved profile to the device

## Profile System

The tool uses a persistent profile system stored at `~/.cosmic_profile.yaml`. Each command:

1. Loads the current profile from disk
2. Updates only the specified setting
3. Saves the updated profile
4. Sends the complete configuration to the device

This design allows you to modify individual settings (like changing just the effect) without affecting other configurations (like DPI or colors). The device firmware requires a complete configuration update with every change, but the profile system handles this automatically.

## Available Effects

### Speed-Adjustable Effects (5 speed levels each)
- **Breathing**: Smooth fade in/out animation
- **Neon**: Intense pulsing glow
- **Wave**: Colors flow across the mouse
- **YoYo**: Colors bounce back and forth
- **Marbles**: Rolling marble effect
- **Drag**: Colors drag across LEDs
- **Trailing**: Colors leave a trail
- **Wave**: Flowing water effect

### Static Effects
- **Standard**: Simple color cycling
- **Slide**: Colors slide across
- **Flying Star**: Star-like animation
- **Key Reaction**: LEDs react to button clicks

## Color Profiles

### LED Color Profiles
Predefined themes for RGB effects:
- **Basic**: red, green, blue, purple, cyan, yellow, white, orange
- **Special**: rainbow, fire, ocean
- **Utility**: off (turns LEDs off)

### DPI Indicator Profiles
Visual feedback when switching DPI levels:
- **Basic**: red, green, blue
- **Gradients**: rainbow (low=red, high=blue), warm (reds/oranges), cool (blues/cyans)
- **Utility**: off (no indicator)

Custom RGB values can also be specified manually for both LED effects and DPI indicators.

## Technical Details

This tool communicates with the mouse using a reverse-engineered USB protocol involving control transfers and interrupt transfers. The complete protocol documentation is available in `PROTOCOL.md`, which details:

- USB communication methods and timing requirements
- Complete packet structure and command sequences
- Color control systems (main LED and per-DPI indicators)
- DPI configuration format
- All 35+ LED effect commands

The protocol was discovered through USB packet capture and analysis of the official Windows driver.

## Uninstallation

Use the provided uninstall script to remove the binary from `/usr/local/bin/cosmic-mouse`.

## Project Structure

```
cosmic/
├── dist/cosmic-mouse         # Pre-built binary
├── cosmic/                   # Python package
│   ├── config.py            # Effects, colors, constants
│   ├── device.py            # USB communication
│   ├── profile.py           # YAML profile management
│   └── commands/            # Command handlers
├── cosmic-mouse             # Entry point script
├── setup.py                 # Package installer
├── install.sh               # Binary installer
├── uninstall.sh            # Uninstaller
└── PROTOCOL.md             # USB protocol documentation
```

## Requirements

- **Operating System**: Linux (tested on Arch Linux)
- **Permissions**: USB device access (typically requires sudo)
- **Dependencies**: None (when using pre-built binary)

For building from source:
- Python 3.x
- pyusb library
- pyyaml library
- pyinstaller (for building binary)

## Limitations

- **Platform**: Currently Linux-only (Windows driver conflicts with raw USB access)
- **Device Support**: Only tested with Cosmic Byte Firestorm (VID: 0x04d9, PID: 0xa09f)
- **Settings Persistence**: Settings are saved to mouse EEPROM and persist across reboots, but the profile file must be manually synced if the mouse is configured elsewhere

## Contributing

Contributions are welcome! Areas of interest include:

- Testing on different Linux distributions
- Protocol improvements and discoveries
- Additional color profile presets
- Bug fixes and error handling improvements

When contributing protocol discoveries, please include USB captures and detailed testing notes.

## License

This tool is provided for educational and interoperability purposes. The USB protocol documentation represents reverse-engineered information obtained through legal packet capture and analysis.

## Support

For issues, questions, or feature requests, please use the GitHub issue tracker. Note that this is a community project and not officially supported by the device manufacturer.
