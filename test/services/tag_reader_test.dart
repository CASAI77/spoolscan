import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/models/tag_format.dart';
import 'package:spoolscan/services/tag_reader.dart';

void main() {
  group('TagReader.parse', () {
    test('erkennt OpenPrintTag-Payload', () {
      final payload = jsonEncode({
        'standard': 'openprinttag',
        'brand': 'Prusament',
        'material': 'PETG',
        'color_hex': '111111',
      });
      final result = TagReader.parse(
        nfcUid: '04a3b21c5d6e80',
        textPayload: payload,
      );
      expect(result.format, TagFormat.openPrintTag);
      expect(result.spool?.brand, 'Prusament');
      expect(result.nfcUid, '04a3b21c5d6e80');
    });

    test('erkennt OpenSpool-JSON', () {
      final payload = jsonEncode({
        'protocol': 'openspool',
        'spool_id': 3,
        'brand': 'Sunlu',
      });
      final result = TagReader.parse(nfcUid: 'aa', textPayload: payload);
      expect(result.format, TagFormat.openSpool);
      expect(result.spool?.spoolId, '3');
    });

    test('erkennt SpoolCompanion-Format', () {
      final result = TagReader.parse(
        nfcUid: 'bb',
        textPayload: 'SPOOL:42\nMATERIAL:PLA',
      );
      expect(result.format, TagFormat.spoolCompanion);
      expect(result.spool?.spoolId, '42');
    });

    test('erkennt leeren/unbekannten Payload', () {
      final result = TagReader.parse(nfcUid: 'cc', textPayload: '');
      expect(result.format, TagFormat.unknown);
      expect(result.spool, isNull);
    });

    test('uidFromBytes formatiert als lowercase Hex ohne Trennung', () {
      final bytes = Uint8List.fromList([0x04, 0xA3, 0xB2, 0x1C]);
      expect(TagReader.uidFromBytes(bytes), '04a3b21c');
    });
  });
}
