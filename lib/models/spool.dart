import 'dart:convert';

class Spool {
  final String spoolId;
  final String? brand;
  final String? type;
  final String? colorHex;
  final int? minTemp;
  final int? maxTemp;

  Spool({
    required this.spoolId,
    this.brand,
    this.type,
    this.colorHex,
    this.minTemp,
    this.maxTemp,
  });

  /// Parst automatisch OpenSpool-JSON oder SpoolCompanion-Textformat
  factory Spool.fromText(String text) {
    final trimmed = text.trim();

    // Versuche OpenSpool JSON
    if (trimmed.startsWith('{')) {
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        return Spool.fromJson(json);
      } catch (_) {}
    }

    // SpoolCompanion-Format: SPOOL:3\nFILAMENT:8\n...
    return Spool._fromSpoolCompanion(trimmed);
  }

  factory Spool.fromJson(Map<String, dynamic> json) {
    if (json['protocol'] != 'openspool') {
      throw FormatException('Kein OpenSpool-Format (protocol=${json['protocol']})');
    }
    final rawId = json['spool_id'];
    if (rawId == null) {
      throw FormatException('spool_id fehlt im Tag');
    }
    return Spool(
      spoolId: rawId.toString(),
      brand: json['brand'] as String?,
      type: json['type'] as String?,
      colorHex: json['color_hex'] as String?,
      minTemp: json['min_temp'] as int?,
      maxTemp: json['max_temp'] as int?,
    );
  }

  factory Spool._fromSpoolCompanion(String text) {
    String? spoolId;
    String? material;

    for (final line in text.split('\n')) {
      final parts = line.split(':');
      if (parts.length < 2) continue;
      final key = parts[0].trim().toUpperCase();
      final value = parts.sublist(1).join(':').trim();

      if (key == 'SPOOL') spoolId = value;
      if (key == 'MATERIAL' || key == 'TYPE') material = value;
    }

    if (spoolId == null) {
      throw FormatException('Kein SPOOL:-Feld gefunden – unbekanntes Tag-Format');
    }

    return Spool(
      spoolId: spoolId,
      type: material,
    );
  }
}
