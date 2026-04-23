import 'dart:convert';
import 'tag_format.dart';

class Spool {
  final String spoolId;
  final String? brand;
  final String? type;
  final String? colorHex;
  final int? minTemp;
  final int? maxTemp;
  final String? nfcUid;
  final TagFormat? tagFormat;
  final int? remainingWeight;
  final int? weightTotal;

  Spool({
    required this.spoolId,
    this.brand,
    this.type,
    this.colorHex,
    this.minTemp,
    this.maxTemp,
    this.nfcUid,
    this.tagFormat,
    this.remainingWeight,
    this.weightTotal,
  });

  Spool copyWith({
    String? spoolId,
    String? brand,
    String? type,
    String? colorHex,
    int? minTemp,
    int? maxTemp,
    String? nfcUid,
    TagFormat? tagFormat,
    int? remainingWeight,
    int? weightTotal,
  }) =>
      Spool(
        spoolId: spoolId ?? this.spoolId,
        brand: brand ?? this.brand,
        type: type ?? this.type,
        colorHex: colorHex ?? this.colorHex,
        minTemp: minTemp ?? this.minTemp,
        maxTemp: maxTemp ?? this.maxTemp,
        nfcUid: nfcUid ?? this.nfcUid,
        tagFormat: tagFormat ?? this.tagFormat,
        remainingWeight: remainingWeight ?? this.remainingWeight,
        weightTotal: weightTotal ?? this.weightTotal,
      );

  // === bestehende Factory-Methoden bleiben unverändert ===
  factory Spool.fromText(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('{')) {
      try {
        final json = jsonDecode(trimmed) as Map<String, dynamic>;
        return Spool.fromJson(json);
      } catch (_) {}
    }
    return Spool._fromSpoolCompanion(trimmed);
  }

  factory Spool.fromJson(Map<String, dynamic> json) {
    if (json['protocol'] != 'openspool') {
      throw FormatException('Kein OpenSpool-Format (protocol=${json['protocol']})');
    }
    // spool_id ist OPTIONAL: SpoolPainter z.B. schreibt nur Filament-Daten
    // ohne Spoolman-Referenz. Leerer spoolId → Resolver überspringt Stufe 1
    // und geht direkt in den UID-/Anlage-Flow.
    final rawId = json['spool_id'];
    return Spool(
      spoolId: rawId?.toString() ?? '',
      brand: json['brand'] as String?,
      type: json['type'] as String?,
      colorHex: json['color_hex'] as String?,
      // Temperaturen tolerant lesen (SpoolPainter schreibt Strings, andere ints):
      minTemp: _asInt(json['min_temp']),
      maxTemp: _asInt(json['max_temp']),
      tagFormat: TagFormat.openSpool,
    );
  }

  /// Liest int oder int-als-String tolerant.
  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
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
    return Spool(spoolId: spoolId, type: material, tagFormat: TagFormat.spoolCompanion);
  }
}
