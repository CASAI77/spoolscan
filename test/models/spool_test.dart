import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/models/spool.dart';
import 'package:spoolscan/models/tag_format.dart';

void main() {
  group('Spool.fromJson', () {
    test('parst valides OpenSpool-JSON korrekt', () {
      final json = {
        'version': 1,
        'protocol': 'openspool',
        'color_hex': 'FF0000',
        'type': 'PETG',
        'min_temp': 230,
        'max_temp': 250,
        'brand': 'Sunlu',
        'spool_id': '3',
      };
      final spool = Spool.fromJson(json);
      expect(spool.spoolId, '3');
      expect(spool.brand, 'Sunlu');
      expect(spool.type, 'PETG');
      expect(spool.colorHex, 'FF0000');
      expect(spool.minTemp, 230);
      expect(spool.maxTemp, 250);
    });

    test('spool_id als Zahl (int) wird zu String konvertiert', () {
      final json = {
        'protocol': 'openspool',
        'spool_id': 5,
      };
      final spool = Spool.fromJson(json);
      expect(spool.spoolId, '5');
    });

    test('wirft FormatException wenn protocol nicht openspool', () {
      final json = {
        'protocol': 'other',
        'spool_id': '3',
      };
      expect(() => Spool.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('wirft FormatException wenn spool_id fehlt', () {
      final json = {
        'protocol': 'openspool',
      };
      expect(() => Spool.fromJson(json), throwsA(isA<FormatException>()));
    });

    test('optionale Felder dürfen null sein', () {
      final json = {
        'protocol': 'openspool',
        'spool_id': '1',
      };
      final spool = Spool.fromJson(json);
      expect(spool.brand, isNull);
      expect(spool.colorHex, isNull);
    });
  });

  group('Spool – neue Felder', () {
    test('Konstruktor akzeptiert nfcUid, tagFormat, remainingWeight, weightTotal', () {
      final spool = Spool(
        spoolId: '7',
        nfcUid: '04a3b21c5d6e80',
        tagFormat: TagFormat.openPrintTag,
        remainingWeight: 743,
        weightTotal: 1000,
      );
      expect(spool.nfcUid, '04a3b21c5d6e80');
      expect(spool.tagFormat, TagFormat.openPrintTag);
      expect(spool.remainingWeight, 743);
      expect(spool.weightTotal, 1000);
    });

    test('neue Felder sind optional und null als Default', () {
      final spool = Spool(spoolId: '1');
      expect(spool.nfcUid, isNull);
      expect(spool.tagFormat, isNull);
      expect(spool.remainingWeight, isNull);
      expect(spool.weightTotal, isNull);
    });
  });
}
