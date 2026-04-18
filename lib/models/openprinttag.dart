import 'dart:convert';
import 'spool.dart';
import 'tag_format.dart';

class OpenPrintTagParser {
  static const _standardKey = 'openprinttag';

  /// Parst OpenPrintTag-NDEF-Payload. Liefert null wenn das Tag
  /// kein OpenPrintTag ist oder die Daten unbrauchbar sind.
  /// spoolId bleibt leer — das Mapping zu Spoolman erfolgt über die NFC-UID.
  static Spool? parse(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;
      if (decoded['standard'] != _standardKey) return null;

      final temp = decoded['print_temp'] as int?;
      return Spool(
        spoolId: '',
        brand: decoded['brand'] as String?,
        type: decoded['material'] as String?,
        colorHex: decoded['color_hex'] as String?,
        minTemp: temp,
        maxTemp: temp,
        weightTotal: decoded['weight_total'] as int?,
        remainingWeight: decoded['weight_remaining'] as int?,
        tagFormat: TagFormat.openPrintTag,
      );
    } catch (_) {
      return null;
    }
  }
}
