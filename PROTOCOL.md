# Cosmic Byte Firestorm USB Protocol Documentation

Complete reverse-engineered USB protocol for the Cosmic Byte Firestorm gaming mouse (VID: `0x04d9`, PID: `0xa09f`).

## Table of Contents

- [Overview](#overview)
- [USB Communication](#usb-communication)
- [Packet Structure](#packet-structure)
- [Color Control](#color-control)
- [DPI Configuration](#dpi-configuration)
- [LED Effects](#led-effects)
- [Complete Command Sequence](#complete-command-sequence)
- [Troubleshooting](#troubleshooting)

---

## Overview

Through USB packet capture and analysis, I've fully reverse-engineered how this mouse communicates with its official Windows driver. The mouse uses a proprietary protocol involving both USB control transfers and interrupt transfers to configure everything from RGB colors to DPI settings.

### What You Can Control

- **RGB LED Colors**: 8 individual colors that create the LED effect animations
- **DPI Levels**: 6 configurable DPI settings (100-25600 in 100 DPI increments)
- **Active DPI**: Which of the 6 levels is currently active
- **Per-DPI Colors**: Each DPI level gets its own indicator color
- **LED Effects**: Over 35 different animation effects with speed controls

### Device Information

| Property | Value |
|----------|-------|
| Vendor ID | `0x04d9` |
| Product ID | `0xa09f` |
| Interface | `2` |
| Endpoint (OUT) | `0x03` |

---

## USB Communication

I discovered the mouse uses two distinct communication methods:

### Control Transfers

These are commands that tell the mouse what to do. Every control command I captured uses these exact parameters:

```
bmRequestType: 0x21 (Host to Device, Class, Interface)
bRequest:      0x09 (SET_REPORT)
wValue:        0x0300 (Feature Report, Report ID 0)
wIndex:        2 (Interface 2)
wLength:       8 bytes
```

Each control command is always **8 bytes long**. I haven't figured out the exact meaning of each byte, but I know which commands do what based on testing.

### Interrupt Transfers

This is how the mouse receives bulk data like color values and DPI settings:

```
Endpoint:      0x03 (OUT)
Length:        32 bytes
Type:          Interrupt transfer
```

### Timing is Critical

I learned this the hard way: you **must** wait at least **20ms between each command**. Send commands too fast and the mouse freezes or disconnects. This delay gives the mouse's microcontroller time to process each command.

---

## Packet Structure

Here's the big picture of what happens when you configure the mouse. I found this by comparing hundreds of USB captures:

```
[8 Setup Commands - Control Transfers]
    ↓
[Color Data - Interrupt Transfer, 32 bytes]
    ↓
[Confirmation - Control Transfer]
    ↓
[DPI Indicator Colors - Interrupt Transfer, 32 bytes]
    ↓
[DPI Setup - Control Transfer]
    ↓
[DPI Values - Interrupt Transfer, 32 bytes]
    ↓
[Multiple Finalization Commands - Control + Interrupt]
```

### Why Every Command Matters

Early on, I tried to be smart and skip commands I thought were unnecessary. **Bad idea.** Every single time I skipped a command, the mouse either froze or disconnected. The firmware clearly expects this exact handshake sequence, even if I don't fully understand what every command does.

---

## Color Control

The mouse has a surprisingly sophisticated color system. There are actually **two separate color configurations** working together.

### Main LED Colors (Packet 31)

These are the 8 colors that cycle through your chosen LED effect. For example, if you set a rainbow and choose the "breathing" effect, these 8 colors fade in and out.

**Type**: Interrupt OUT transfer to endpoint `0x03`  
**Length**: 32 bytes  
**When**: Sent after the 8 setup commands

#### How the 32 Bytes Are Organized

```
Byte 0-2:   Color #1 [Red, Green, Blue]
Byte 3-5:   Color #2 [Red, Green, Blue]
Byte 6-8:   Color #3 [Red, Green, Blue]
Byte 9-11:  Color #4 [Red, Green, Blue]
Byte 12-14: Color #5 [Red, Green, Blue]
Byte 15-17: Color #6 [R, G, B]
Byte 18-20: Color #7 [R, G, B]
Byte 21-23: Color #8 [R, G, B]
Byte 24-31: Empty (just zeros)
```

Each RGB value goes from 0 to 255. Pretty standard stuff.

#### Example: Setting All LEDs to Red

```
FF 00 00 FF 00 00 FF 00 00 FF 00 00 
FF 00 00 FF 00 00 FF 00 00 FF 00 00 
00 00 00 00 00 00 00 00
```

#### Example: Rainbow Pattern

```
FF 00 00    # Color 1: Pure red
FF 7F 00    # Color 2: Orange (red + half green)
FF FF 00    # Color 3: Yellow (red + green)
00 FF 00    # Color 4: Pure green
00 00 FF    # Color 5: Pure blue
4B 00 82    # Color 6: Indigo (some blue, bit of red)
94 00 D3    # Color 7: Violet (more red, lots of blue)
FF 00 00    # Color 8: Back to red to loop smoothly
00 00 00 00 00 00 00 00
```

### Per-DPI Indicator Colors (Packet 35)

This was a cool discovery! Each of your 6 DPI levels can have its own color. When you press the DPI button on the mouse, it briefly flashes that level's color so you know which DPI you're on.

**Type**: Interrupt OUT transfer to endpoint `0x03`  
**Length**: 32 bytes  
**When**: Sent right after the color confirmation command

#### Structure

```
Byte 0-2:   DPI Level 1 indicator color [R, G, B]
Byte 3-5:   DPI Level 2 indicator color [R, G, B]
Byte 6-8:   DPI Level 3 indicator color [R, G, B]
Byte 9-11:  DPI Level 4 indicator color [R, G, B]
Byte 12-14: DPI Level 5 indicator color [R, G, B]
Byte 15-17: DPI Level 6 indicator color [R, G, B]
Byte 18-31: Empty (zeros)
```

#### Example: Rainbow DPI Indicators

This gives you visual feedback - low DPI is red, high DPI is blue:

```
FF 00 00    # Level 1: Red (low/precise)
FF 80 00    # Level 2: Orange
FF FF 00    # Level 3: Yellow
00 FF 00    # Level 4: Green
00 FF FF    # Level 5: Cyan
00 00 FF    # Level 6: Blue (high/fast)
00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

### How These Two Color Systems Work Together

This confused me at first, but here's how it works:

1. **Packet 31** (main colors) sets what you see during normal use. If you set breathing rainbow, those 8 colors breathe.
2. **Packet 35** (DPI colors) only appears briefly when you press the DPI button.
3. The **effect type** (Packet 27) determines how those 8 main colors animate.

So you could have a rainbow breathing effect normally, but flash solid red/green/blue when switching DPI levels. They're independent!

---

## DPI Configuration

The DPI system has two parts: the actual DPI values, and which one is active.

### DPI Values (Packet 39)

This packet tells the mouse what DPI values to use for each of its 6 levels.

**Type**: Interrupt OUT transfer to endpoint `0x03`  
**Length**: 32 bytes  
**When**: After the DPI setup command

#### Structure

```
Byte 0:    DPI Level 1 ÷ 100
Byte 1:    DPI Level 2 ÷ 100
Byte 2:    DPI Level 3 ÷ 100
Byte 3:    DPI Level 4 ÷ 100
Byte 4:    DPI Level 5 ÷ 100
Byte 5:    DPI Level 6 ÷ 100
Byte 6-7:  Always 0x63 0x68 (I don't know why)
Byte 8-31: Empty (zeros)
```

#### The Math

The mouse stores DPI divided by 100. So:

- 800 DPI = 8 = `0x08`
- 1600 DPI = 16 = `0x10`
- 2400 DPI = 24 = `0x18`

Valid range is 100 to 25600 DPI, in 100 DPI steps. I tested 50 DPI increments but the mouse rounds to the nearest 100.

#### Example: FPS Gaming Profile

For precise aiming with low DPI:

```
04 08 10 20 40 80 63 68 00 00 00 00 00 00 00 00 
00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
```

That's:
- Level 1: 400 DPI (4 × 100)
- Level 2: 800 DPI (8 × 100)
- Level 3: 1600 DPI (16 × 100)
- Level 4: 3200 DPI (32 × 100)
- Level 5: 6400 DPI (64 × 100)
- Level 6: 12800 DPI (128 × 100)

### Active DPI Level (Packet 23)

This command sets which DPI level you're currently using. It's like virtually pressing the DPI button.

**Type**: Control transfer  
**Length**: 8 bytes  
**When**: Command #5 in the setup sequence

#### Commands for Each Level

I captured these by changing the active DPI in the Windows software:

| Active Level | Command (hex) |
|--------------|---------------|
| 1 | `27 2b 6d ff f0 4d 9e 76` |
| 2 | `27 2b 65 ff f8 4d 9e 76` |
| 3 | `27 2b 7d ff 00 4d 9e 76` |
| 4 | `27 2b 75 ff c8 4d 9e 76` |
| 5 | `27 2b 4d ff d0 4d 9e 76` |
| 6 | `27 2b 45 ff d8 4d 9e 76` |

#### The Pattern

Byte 2 changes for each level (6d, 65, 7d, 75, 4d, 45), and bytes 4-5 also vary. I tried to find a formula but couldn't decode it. The safest approach is using these exact values.

#### How This Works

When you send one of these commands:
1. The mouse switches to that DPI level immediately
2. It briefly flashes the indicator color from Packet 35
3. The cursor speed changes to match the DPI from Packet 39

---

## LED Effects

The effect command tells the mouse **how** to animate those 8 colors. This was one of the more tedious parts to reverse engineer - I had to capture each effect at each speed level.

### Effect Command (Packet 27)

**Type**: Control transfer  
**Length**: 8 bytes  
**When**: Command #7 in the setup sequence

This single command determines both the effect type AND its speed. Different effects have different numbers of speed levels.

### Available Effects

#### Breathing Effects (5 speed levels)

The colors smoothly fade in and out. Very popular effect.

| Speed | Command | Notes |
|-------|---------|-------|
| 1 (fastest) | `27 2b 45 ff f8 1d 8e 76` | Quick pulse |
| 2 | `27 2b 5d ff f8 1d 8e 7e` | |
| 3 (medium) | `27 2b 55 ff f8 1d 8e 86` | Good default |
| 4 | `27 2b 2d ff f8 1d 8e 8e` | |
| 5 (slowest) | `27 2b 25 ff f8 1d 8e 96` | Slow, relaxing |

#### Wave Effects (5 speed levels)

Colors flow across the mouse like a wave. Looks great with rainbow.

| Speed | Command |
|-------|---------|
| 1 | `27 2b 4d ff c8 22 26 76` |
| 2 | `27 2b 45 ff c8 22 26 7e` |
| 3 | `27 2b 5d ff c8 22 26 86` |
| 4 | `27 2b 55 ff c8 22 26 8e` |
| 5 | `27 2b 2d ff c8 22 26 96` |

#### Neon Effects (5 speed levels)

A glowing pulse effect. More intense than breathing.

| Speed | Command |
|-------|---------|
| 1 | `27 2b 95 04 a0 15 9e 76` |
| 2 | `27 2b 4d ff 00 22 26 7e` |
| 3 | `27 2b 45 ff 00 22 26 86` |
| 4 | `27 2b 5d ff 00 22 26 8e` |
| 5 | `27 2b 55 ff 00 22 26 96` |

#### Static Effects

These don't have speed variations:

| Effect | Command | Description |
|--------|---------|-------------|
| Standard | `27 2b 75 ff f0 1d 95 6e` | Colors cycle but stay static. Default effect. |
| Slide | `27 2b 25 ff 28 1d 9d 6e` | Colors slide across the LEDs |
| Flying Star | `27 2b 05 ff 40 1d 95 6e` | A star-like animation |
| Key Reaction | `27 2b 55 ff d0 1d 95 6e` | LEDs react when you click buttons |

#### Advanced Effects (5 speeds each)

I captured these but honestly, some are hard to describe:

- **YoYo**: Colors bounce back and forth
- **Marbles**: Looks like rolling marbles
- **Drag**: Colors drag across
- **Trailing**: Colors leave a trail

Each has 5 speed levels. Commands follow similar patterns but with different byte values.

### How Effects Actually Work

The effect doesn't change your colors - it changes how they're displayed:

- **Standard**: Each LED shows one of your 8 colors, cycling through them
- **Breathing**: All LEDs fade through your 8 colors smoothly
- **Wave**: Your colors flow from one side to the other
- **Neon**: Similar to breathing but with more intensity changes

Some effects work better with certain color schemes. Rainbow looks great with wave, but solid red looks better with breathing.

---

## Complete Command Sequence

This is the full sequence I discovered through trial and error. Every command is necessary - skip one and the mouse freezes.

### Setup Phase (Commands 1-8)

These initialize the mouse for configuration. I don't know what each one does specifically, but they're required.

**Command 1-4**: Initial handshake
- `27 27 d5 ff ec 0d 9e 76`
- `25 2d ad ff e8 12 0e ee`
- `27 2b d5 ff f0 05 9e 76`
- `27 2b dd ff f0 fd 9e 76`

**Command 5**: Active DPI level (see [Active DPI Level](#active-dpi-level-packet-23))

**Command 6**: Unknown purpose
- `27 2b 95 04 a0 15 9e 76`

**Command 7**: Effect type (see [LED Effects](#led-effects))

**Command 8**: Prepare for color data
- `27 2a 8d ff e8 75 9e 36`

After this, the mouse expects color data next.

### Color Phase

**Packet 31**: Send your 8 RGB colors (32 bytes via interrupt transfer to 0x03)

**Packet 33**: Confirm colors received
- Control: `27 2a 85 ff f0 75 9e 36`

**Packet 35**: Send per-DPI indicator colors (32 bytes via interrupt transfer to 0x03)

### DPI Phase

**Packet 37**: Setup for DPI configuration
- Control: `27 2b f5 ff d8 7d 9e b6`

**Packet 39**: Send DPI values (32 bytes via interrupt transfer to 0x03)

### Finalization Phase

This is where it gets messy. Multiple commands that seem to finalize everything:

**Packet 41**: Control transfer
- `27 2d 55 ff f0 85 a0 76`

**Packets 43, 45**: Additional data via interrupt
- `01 00 f0 00 01 00 f1 00 01 00 f2 00 01 00 f4 00 01 00 f3 00 07 00 03 00 0b 00 00 00 0a f0 21 03`
- `0b 00 00 00 0b 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 04 00 01 00 04 00 02 00`

I have no idea what these packets do, but they're required.

**Packet 47**: Control transfer
- `27 2d 2d ff f8 85 a0 76`

**Packets 49, 51**: Empty padding
- Two 32-byte packets of all zeros via interrupt

**Packet 53**: Control transfer
- `27 2b f5 ff 00 75 9e d6`

**Packet 55**: More data via interrupt
- `ff 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00`

**Packet 57**: Final confirmation
- Control: `27 2c 6d 02 38 3a b4 d6`

### Important Notes

1. **20ms delay between EVERY command**. This is not optional.
2. The commands must be sent in this exact order.
3. Settings persist in the mouse's EEPROM - they survive unplugging.
4. The mouse expects this entire handshake even if you're only changing colors.

---

## Troubleshooting

### Mouse Freezes After Sending Commands

**What's happening**: You sent an incomplete sequence.

**Why**: The mouse firmware gets stuck waiting for commands that never arrive.

**Solution**: Always send the complete sequence, even if you only want to change one thing. You can't just send Packet 31 (colors) by itself.

### Mouse Disconnects and Reconnects

**What's happening**: Commands are being sent too fast.

**Why**: The microcontroller can't process commands that quickly.

**Solution**: Add 20ms delays between each command. I use `time.sleep(0.02)` in Python.

### Colors Don't Show Up

**What's happening**: The effect you chose doesn't support custom colors.

**Why**: Some effects have hardcoded colors or patterns.

**Solution**: Use `standard`, `breathing`, `wave`, or `neon` effects. These all respect your custom colors.

### DPI Changes But Shows Wrong Value

**What's happening**: You're not using multiples of 100.

**Why**: The mouse only supports 100 DPI increments.

**Solution**: Use 100, 200, 300... up to 25600. The mouse rounds anything else.

### Per-DPI Colors Not Appearing

**What's happening**: You might not be pressing the DPI button long enough.

**Why**: The indicator flash is brief (about 1 second).

**Solution**: Press the DPI button and watch carefully. The mouse will briefly flash that level's color before returning to the main effect.

---

## Contributing

Found something new? Here's how I'd appreciate contributions:

1. **Capture USB traffic** using Wireshark with USBPcap (Windows) or usbmon (Linux)
2. **Test on hardware** - Don't assume anything without testing
3. **Compare captures** - Change one setting at a time and diff the packets
4. **Document thoroughly** - Include what you changed and what packets changed

---

## Appendix: Mysteries Remaining

Despite extensive testing, some things remain unknown:

### Unknown Constants

- **Bytes 6-7 in DPI data**: Always `0x63 0x68`. I tried changing these and the mouse ignored DPI settings, so they're important. But why these specific values? No idea.

### Unknown Packets

- **Packets 43, 45**: These 32-byte interrupt packets are required but I don't know their purpose. They seem like configuration data but changing them breaks things.
- **Packets 49, 51**: Why send 32 bytes of zeros? Padding? Timing? Unknown.

### Command Structure

I can't decode the 8-byte control commands. I know:
- Byte 0 is often `0x27`
- Byte 1 varies by command type
- Bytes 2-5 seem to encode parameters
- Bytes 6-7 might be checksums

But I haven't cracked the formula. For now, I use the exact bytes captured from the Windows driver.

### Effect Parameters

Speed levels follow patterns (breathing_1 through breathing_5) but the actual byte changes don't follow obvious math. It's not as simple as incrementing a speed value.

### Future Work

- Decode the checksum algorithm
- Understand the finalization packets
- Discover if polling rate is configurable
- Check if button remapping is possible

If anyone figures these out, please contribute!

---

## License

This documentation is provided for educational and interoperability purposes.
