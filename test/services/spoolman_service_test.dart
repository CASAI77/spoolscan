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

  group('SpoolmanService.listSpools', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('liefert alle Spulen mit extra-Feldern', () async {
      when(mockClient.get(Uri.parse('http://h:7912/api/v1/spool')))
          .thenAnswer((_) async => http.Response(
                '[{"id":1,"filament":{"name":"PLA","vendor":{"name":"V"}},'
                '"extra":{"nfc_uid":"\\"abc\\""}},'
                '{"id":2,"filament":{"name":"PETG","vendor":{"name":"V"}}}]',
                200,
              ));
      final spools = await service.listSpools('h:7912');
      expect(spools.length, 2);
      expect(spools[0].nfcUid, 'abc');
      expect(spools[1].nfcUid, isNull);
    });
  });

  group('SpoolmanService.createVendor', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('POSTed JSON und gibt neue Vendor-ID zurück', () async {
      when(mockClient.post(
        Uri.parse('http://h:7912/api/v1/vendor'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"id":42,"name":"Sunlu"}', 200));

      final id = await service.createVendor('h:7912', name: 'Sunlu');
      expect(id, 42);
    });
  });

  group('SpoolmanService.createFilament', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('POSTed JSON mit allen Feldern und gibt ID zurück', () async {
      when(mockClient.post(
        Uri.parse('http://h:7912/api/v1/filament'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"id":7}', 200));

      final id = await service.createFilament(
        'h:7912',
        vendorId: 42,
        name: 'PETG Schwarz',
        material: 'PETG',
        colorHex: '111111',
        extruderTemp: 240,
      );
      expect(id, 7);
    });
  });

  group('SpoolmanService.createSpool', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('POSTed JSON mit filament_id + extra und gibt Spool zurück', () async {
      when(mockClient.post(
        Uri.parse('http://h:7912/api/v1/spool'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            '{"id":99,"filament":{"name":"PETG","vendor":{"name":"Sunlu"},'
            '"color_hex":"111111"},"extra":{"nfc_uid":"\\"04a3\\""}}',
            200,
          ));

      final spool = await service.createSpool(
        'h:7912',
        filamentId: 7,
        initialWeight: 1000,
        extra: {'nfc_uid': '04a3'},
      );
      expect(spool.spoolId, '99');
      expect(spool.brand, 'Sunlu');
      expect(spool.nfcUid, '04a3');
    });
  });

  group('SpoolmanService.patchSpoolExtra', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('PATCH mit extra-Map', () async {
      when(mockClient.patch(
        Uri.parse('http://h:7912/api/v1/spool/3'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"id":3}', 200));

      await service.patchSpoolExtra('h:7912', '3', {'nfc_uid': 'abc'});

      verify(mockClient.patch(
        Uri.parse('http://h:7912/api/v1/spool/3'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });
  });

  group('SpoolmanService.listVendors / listFilaments', () {
    late MockClient mockClient;
    late SpoolmanService service;

    setUp(() {
      mockClient = MockClient();
      service = SpoolmanService(client: mockClient);
    });

    test('listVendors liefert Liste', () async {
      when(mockClient.get(Uri.parse('http://h:7912/api/v1/vendor')))
          .thenAnswer((_) async => http.Response(
                '[{"id":1,"name":"Sunlu"},{"id":2,"name":"Prusament"}]', 200));
      final vs = await service.listVendors('h:7912');
      expect(vs.length, 2);
      expect(vs[0].name, 'Sunlu');
    });

    test('listFilaments mit vendor-Filter', () async {
      when(mockClient.get(Uri.parse('http://h:7912/api/v1/filament?vendor.id=1')))
          .thenAnswer((_) async => http.Response(
                '[{"id":3,"name":"PLA Basic","material":"PLA","color_hex":"ff0000",'
                '"vendor":{"id":1,"name":"Sunlu"}}]',
                200,
              ));
      final fs = await service.listFilaments('h:7912', vendorId: 1);
      expect(fs.length, 1);
      expect(fs[0].material, 'PLA');
    });
  });
}
