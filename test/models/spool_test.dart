import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/models/spool.dart';

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
}
