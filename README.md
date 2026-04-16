# SpoolScan

An Android app that scans NFC tags on filament spools and assigns them to a print slot (T0–T3) on the **Snapmaker U1** via Moonraker + Spoolman.

**Available in English and German.**

---

## Features

- Scan NFC tags in SpoolCompanion format (`SPOOL:3`) or OpenSpool JSON
- Fetch filament details (brand, material, color, temperature) from Spoolman
- Assign spool to slot T0–T3 on the Snapmaker U1 via Moonraker API
- Language toggle: Deutsch / English
- Works fully offline for tag reading — only needs local network for Spoolman/Moonraker

## Requirements

- Android phone with NFC
- Snapmaker U1 with Moonraker running
- [Spoolman](https://github.com/Donkie/Spoolman) running on your local network
- Filament spools with NFC tags (SpoolCompanion or OpenSpool format)

## Installation

1. Download the latest `app-release.apk` from the [Releases](../../releases) page
2. On your Android phone: Settings → Security → allow installation from unknown sources
3. Open the APK file and install

## Setup

Open the app → tap the settings icon (top right):

| Setting | Example |
|---|---|
| Printer IP (Moonraker) | `192.168.1.179` |
| Spoolman URL | `192.168.1.181:7912` |

## Usage

1. Open SpoolScan
2. Hold your phone to a filament spool NFC tag
3. The app shows brand, material, color and temperature from Spoolman
4. Tap T0 / T1 / T2 / T3 to assign the spool to that slot

## Tech Stack

- Flutter 3.x (Dart)
- [nfc_manager](https://pub.dev/packages/nfc_manager) — NFC tag reading
- [http](https://pub.dev/packages/http) — Moonraker & Spoolman API
- [shared_preferences](https://pub.dev/packages/shared_preferences) — settings storage
- Moonraker REST API
- Spoolman REST API v1

## NFC Tag Formats

**SpoolCompanion:**
```
SPOOL:3
FILAMENT:3
```

**OpenSpool (JSON):**
```json
{"protocol":"openspool","spool_id":3,"brand":"Sunlu","type":"PETG","color_hex":"000000"}
```

## Build from Source

```bash
git clone https://github.com/YOUR_USERNAME/spoolscan.git
cd spoolscan
flutter pub get
flutter build apk --release
```

## License

This project is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE) for details.
