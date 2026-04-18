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

## Verbrauchstracking aktivieren (einmalig)

Damit Spoolman den Filamentverbrauch automatisch von Moonraker erhält, muss
am Snapmaker U1 in `~/printer_data/config/moonraker.conf` folgender Block stehen:

```ini
[spoolman]
server: http://192.168.1.181:7912
sync_rate: 5
```

(Spoolman-URL ggf. an deine Umgebung anpassen.)

Danach Moonraker neu starten:

```bash
sudo systemctl restart moonraker
```

Die App setzt beim Slot-Tippen die "active spool" — Moonraker reduziert dann das
`remaining_weight` in Spoolman, während gedruckt wird. Der DetailScreen zeigt
die aktuelle Restmenge bei jedem Scan.

## Usage

1. Open SpoolScan
2. Hold your phone to a filament spool NFC tag
3. The app shows brand, material, color and temperature from Spoolman
4. Tap T0 / T1 / T2 / T3 to assign the spool to that slot

## Automatische Spulen-Anlage

Wird ein Tag gescannt, dessen Spule **noch nicht in Spoolman existiert**, legt
SpoolScan sie automatisch an:

- **OpenPrintTag/OpenSpool mit Daten:** Bestätigungsdialog mit Marke/Material/Farbe → "Anlegen & Weiter".
- **SpoolCompanion oder leerer NTAG:** Eingabe-Maske mit Vorbefüllung (was vom Tag kam).

Beim ersten Match einer SpoolCompanion-Spule wird die NFC-Hardware-UID
nachträglich in Spoolman als `extra.nfc_uid` gespeichert. Beim nächsten Scan
wird die Spule sofort über die UID gefunden — unabhängig vom Tag-Format.

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

**OpenPrintTag (JSON):**
```json
{"standard":"openprinttag","brand":"Prusament","material":"PETG","color_hex":"1a1a1a","weight_total":1000,"weight_remaining":850,"print_temp":240}
```

Spec: <https://openprinttag.org/>

## Build from Source

```bash
git clone https://github.com/YOUR_USERNAME/spoolscan.git
cd spoolscan
flutter pub get
flutter build apk --release
```

## License

This project is licensed under the **GNU General Public License v3.0** — see [LICENSE](LICENSE) for details.

---

## Support

If you find this project useful, consider buying me a coffee! ☕

[![Buy Me A Coffee](https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png)](https://buymeacoffee.com/casai)
