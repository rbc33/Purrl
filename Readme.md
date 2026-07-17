# 🐾 Purrl

**Free, open-source haptic feedback for trackpad scrolling on macOS.**

Purrl turns your trackpad's Taptic Engine into a scroll wheel with texture — every scroll fires real haptic pulses through your Force Touch trackpad, spaced by scroll distance so it feels like a physical ratchet instead of a flat glass surface.

Lives quietly in your menu bar. No windows, no clutter, no data collection.

---

## Why Purrl?

Apps like [Snick](https://snick.vercel.app/) popularized this idea — but they're closed-source and paid. Purrl does the same core thing, for free, with code you can actually read.

| | Purrl | Snick |
|---|---|---|
| Price | Free | Paid |
| Open source | ✅ | ❌ |
| Trackpad haptics | ✅ | ✅ |
| Sound feedback | — | ✅ (7 voices) |
| Adjustable "tooth" texture | ✅ | ✅ |
| Accessibility permission | ✅ (auditable) | ✅ |
| macOS | 14+ | 14+ |

Purrl only reads global scroll events to time haptic pulses. It doesn't read screen content, doesn't log anything, and doesn't phone home — you can verify that yourself in [`ScrollHapticEngine.swift`](./Purrl/ScrollHapticEngine.swift).

*Purrl is an independent project, not affiliated with or endorsed by Snick.*

---

## How it works

Purrl treats your trackpad scroll like a mechanical ratchet wheel:

1. A global event monitor (via macOS Accessibility permission) tracks scroll distance across the whole system, not just Purrl's own window.
2. Scroll delta accumulates until it crosses a configurable **tooth size** (in points).
3. Each time a "tooth" is crossed, Purrl fires a real haptic pulse through `NSHapticFeedbackManager` on your trackpad's Taptic Engine.
4. Scroll slowly → distinct, spaced-out pulses. Scroll fast → pulses blur together into a continuous rumble.

No private APIs, no kernel extensions — just public AppKit frameworks (`NSEvent`, `NSHapticFeedbackManager`), the same building blocks documented in [Apple's own sample code](https://developer.apple.com/documentation/appkit/nshapticfeedbackmanager).

---

## Installation

### Homebrew (recommended)

```bash
brew tap rbc33/purrl
brew install --cask purrl
```

> **Note:** Homebrew may warn that this tap is untrusted the first time, since it's a third-party tap. This is expected — approve it with:
> ```bash
> brew trust --cask rbc33/purrl/purrl
> brew install --cask purrl
> ```

### Manual

1. Download the latest `Purrl.dmg` from [Releases](https://github.com/rbc33/Purrl/releases)
2. Open the dmg and drag **Purrl** into **Applications**
3. Launch Purrl. If macOS blocks it as unverified: go to **System Settings → Privacy & Security** and click **Open Anyway**
4. Grant **Accessibility** permission when prompted — this is required so Purrl can detect scroll events system-wide

---

## Usage

Purrl lives in your menu bar as a 🐾 icon.

- Click the icon to toggle Purrl on/off, or adjust the scroll texture (fine, medium, coarse).
- If the icon shows a ⚠️, Accessibility permission hasn't been granted yet — click it to re-check, or grant it manually in **System Settings → Privacy & Security → Accessibility**.

---

## Requirements

- macOS 14 or later
- A Mac with a Force Touch trackpad (MacBook Pro/Air 2015+, or a Magic Trackpad 2/3)

Haptics won't fire on a mouse or a non-Force-Touch trackpad — `NSHapticFeedbackManager` has nothing to actuate on that hardware.

---

## Building from source

```bash
git clone https://github.com/rbc33/Purrl.git
cd Purrl
xcodebuild -scheme Purrl -configuration Release -derivedDataPath build clean build
```

The built app will be in `build/Build/Products/Release/Purrl.app`.

---

## Privacy

Purrl requires macOS Accessibility permission to receive global scroll events — this is the same permission any system-wide scroll/gesture tool needs. Purrl:

- Reads scroll direction and magnitude only
- Does not read screen content, keystrokes, or clipboard
- Does not collect analytics or send any data off your Mac
- Has no network code at all

---

## Contributing

Issues and PRs welcome. If you're adding a feature, keep it in the spirit of the project: small, auditable, no telemetry.

---

## License

[MIT](./LICENSE)
