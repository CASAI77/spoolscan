# SpoolScan

An Android app that scans NFC tags on filament spools and assigns them to a print
slot (T0–T3) on the **Snapmaker U1** via Moonraker + Spoolman.

Now with **OpenPrintTag** support, **automatic spool registration** in Spoolman,
and **consumption tracking** out of the box.

**Available in English and German.**

---

## Features

- **Reads three NFC tag formats:**
  SpoolCompanion (`SPOOL:3`), OpenSpool (JSON), and OpenPrintTag (Prusa's new
  open standard, [openprinttag.org](https://openprinttag.org/))
- **Three-stage spool lookup:**
  Spoolman ID → NFC hardware UID → unknown (then auto-create)
- **Self-healing UID linking:**
  After the first scan, the chip's NFC UID is stored in Spoolman
  (`extra.nfc_uid`). Future scans of the same physical tag are matched instantly,
  regardless of tag format.
- **Automatic spool registration:**
  Unknown spools are created in Spoolman on the spot — vendor, filament and
  spool entries are added automatically when needed.
- **Hybrid create flow:**
  - OpenPrintTag/OpenSpool with data → confirmation dialog with prefilled values
  - SpoolCompanion / blank NTAG → manual entry form prefilled with what was on
    the tag
- **Consumption tracking** via Moonraker's `[spoolman]` integration — the app
  sets the active spool, Moonraker reports usage, the DetailScreen shows the
  current remaining weight on every scan.
- **Spoolman stays unmodified** — uses only the official REST endpoints plus
  the standard `extra` field schema. Update Spoolman freely without breaking
  the app.
- **Language toggle:** Deutsch / English
- **Works fully offline for tag reading** — only needs your local network for
  Spoolman/Moonraker calls.

## Requirements

- Android phone with NFC
- Snapmaker U1 with Moonraker running
- [Spoolman](https://github.com/Donkie/Spoolman) reachable on your local network
- NFC tags on your spools (any of the three supported formats — or even blank
  NTAGs, which the app will register on first scan)

## Installation

1. Download the latest `app-release.apk` from the [Releases](../../releases) page
2. On your Android phone: Settings → Security → allow installation from unknown
   sources
3. Open the APK file and install

## Setup

Open the app → tap the settings icon (top right):

| Setting | Example |
|---|---|
| Printer IP (Moonraker) | `192.168.1.179` |
| Spoolman URL | `192.168.1.181:7912` |

### Enable consumption tracking (one-time)

For Spoolman to receive filament usage automatically from Moonraker, add this
block to `~/printer_data/config/moonraker.conf` on the Snapmaker U1:

```ini
[spoolman]
server: http://192.168.1.181:7912
sync_rate: 5
```

(Adjust the URL for your environment.) Then restart Moonraker:

```bash
sudo systemctl restart moonraker
```

Once active spool is set via SpoolScan, Moonraker will reduce `remaining_weight`
in Spoolman during prints. The DetailScreen displays the live remaining weight
on every scan.

## Usage

1. Open SpoolScan
2. Hold the phone to a spool's NFC tag
3. **Known spool:** brand, material, color and remaining weight from Spoolman
   are shown immediately
4. **Unknown spool:** confirmation dialog (auto-fill) or entry form opens —
   confirm/save and the spool is registered
5. Tap T0 / T1 / T2 / T3 to assign the spool to that slot

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

**OpenPrintTag (JSON):**
```json
{"standard":"openprinttag","brand":"Prusament","material":"PETG","color_hex":"1a1a1a","weight_total":1000,"weight_remaining":850,"print_temp":240}
```

Spec: <https://openprinttag.org/>

## How it works (short)

```
Scan ─► UID + payload extracted
       │
       ├─► Stage 1: tag carries a Spoolman ID? → fetch /spool/{id}
       ├─► Stage 2: search /spool list for extra.nfc_uid match
       └─► Stage 3: create new spool (auto from tag data, or manual form)

Found ─► Self-heal: store the chip UID on the matched spool if missing
       ─► Show details + remaining weight
       ─► Pick slot → Moonraker SET_ACTIVE_SPOOL
       ─► Print → Moonraker reports usage → Spoolman updates remaining_weight
```

## Tech Stack

- Flutter 3.x (Dart)
- [nfc_manager](https://pub.dev/packages/nfc_manager) — NFC tag reading
- [http](https://pub.dev/packages/http) — Moonraker & Spoolman API
- [shared_preferences](https://pub.dev/packages/shared_preferences) — settings storage
- [mockito](https://pub.dev/packages/mockito) — test mocks
- Moonraker REST API + `[spoolman]` integration
- Spoolman REST API v1

## Build from Source

```bash
git clone https://github.com/YOUR_USERNAME/spoolscan.git
cd spoolscan
flutter pub get
flutter build apk --release
```

## License

This project is licensed under the **GNU General Public License v3.0** —
see [LICENSE](LICENSE) for details.

---

## Support

If you find this project useful, consider buying me a coffee! ☕

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/casai)
