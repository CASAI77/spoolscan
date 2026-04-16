import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spoolscan/services/spoolman_service.dart';

@GenerateMocks([http.Client])
import 'spoolman_service_test.mocks.dart';

void main() {
  group('SpoolmanService.fetchSpool', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('gibt Spool mit korrekten Feldern zurück', () async {
      when(mockClient.get(
        Uri.parse('http://192.168.1.181:7912/api/v1/spool/3'),
      )).thenAnswer((_) async => http.Response(
            '{"id":3,"filament":{"name":"PLA Basic","vendor":{"name":"Bambu Lab"},'
            '"color_hex":"ff5500","settings_extruder_temp":220}}',
            200,
          ));

      final spool = await service.fetchSpool('192.168.1.181:7912', '3');

      expect(spool.spoolId, equals('3'));
      expect(spool.brand, equals('Bambu Lab'));
      expect(spool.type, equals('PLA Basic'));
      expect(spool.colorHex, equals('ff5500'));
      expect(spool.minTemp, equals(220));
      expect(spool.maxTemp, equals(220));
    });

    test('wirft SpoolmanException bei HTTP 404', () async {
      when(mockClient.get(any))
          .thenAnswer((_) async => http.Response('Not Found', 404));

      await expectLater(
        () => service.fetchSpool('192.168.1.181:7912', '99'),
        throwsA(isA<SpoolmanException>()),
      );
    });

    test('wirft SpoolmanException bei Netzwerkfehler', () async {
      when(mockClient.get(any)).thenThrow(Exception('connection refused'));

      await expectLater(
        () => service.fetchSpool('192.168.1.181:7912', '3'),
        throwsA(isA<SpoolmanException>()),
      );
    });

    test('mappt fehlende optionale Felder als null', () async {
      when(mockClient.get(any)).thenAnswer((_) async => http.Response(
            '{"id":5,"filament":{"name":"PETG","settings_extruder_temp":240}}',
            200,
          ));

      final spool = await service.fetchSpool('192.168.1.181:7912', '5');

      expect(spool.spoolId, equals('5'));
      expect(spool.brand, isNull);
      expect(spool.colorHex, isNull);
      expect(spool.minTemp, equals(240));
    });
  });
}
