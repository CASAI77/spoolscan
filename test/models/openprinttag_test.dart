import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/models/openprinttag.dart';
import 'package:spoolscan/models/tag_format.dart';

void main() {
  group('OpenPrintTagParser.parse', () {
    test('parst vollständigen OpenPrintTag-NDEF-Payload', () {
      final json = jsonEncode({
        'standard': 'openprinttag',
        'version': 1,
        'brand': 'Prusament',
        'material': 'PETG',
        'color_hex': '1a1a1a',
        'weight_total': 1000,
        'weight_remaining': 850,
        'print_temp': 240,
      });
      final spool = OpenPrintTagParser.parse(json);
      expect(spool, isNotNull);
      expect(spool!.brand, 'Prusament');
      expect(spool.type, 'PETG');
      expect(spool.colorHex, '1a1a1a');
      expect(spool.minTemp, 240);
      expect(spool.maxTemp, 240);
      expect(spool.weightTotal, 1000);
      expect(spool.remainingWeight, 850);
      expect(spool.tagFormat, TagFormat.openPrintTag);
      expect(spool.spoolId, isEmpty);
    });

    test('gibt null zurück wenn Standard-Feld fehlt', () {
      final json = jsonEncode({'brand': 'X', 'material': 'PLA'});
      expect(OpenPrintTagParser.parse(json), isNull);
    });

    test('gibt null zurück bei kaputtem JSON', () {
      expect(OpenPrintTagParser.parse('not json'), isNull);
    });

    test('toleriert fehlende optionale Felder', () {
      final json = jsonEncode({
        'standard': 'openprinttag',
        'brand': 'Sunlu',
        'material': 'PLA',
        'color_hex': 'ff0000',
      });
      final spool = OpenPrintTagParser.parse(json)!;
      expect(spool.brand, 'Sunlu');
      expect(spool.weightTotal, isNull);
      expect(spool.remainingWeight, isNull);
      expect(spool.minTemp, isNull);
    });
  });
}
