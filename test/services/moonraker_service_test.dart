import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spoolscan/services/moonraker_service.dart';

@GenerateMocks([http.Client])
import 'moonraker_service_test.mocks.dart';

void main() {
  group('MoonrakerService.setActiveSpool', () {
    late MockClient mockClient;
    late MoonrakerService service;

    setUp(() {
      mockClient = MockClient();
      service = MoonrakerService(client: mockClient);
    });

    test('sendet drei separate POST-Requests an Moonraker', () async {
      when(mockClient.post(
        Uri.parse('http://192.168.1.179/printer/gcode/script'),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"result": "ok"}', 200));

      await service.setActiveSpool(
        printerIp: '192.168.1.179',
        spoolId: '3',
        slot: 0,
      );

      // Drei einzelne Aufrufe — Multi-Line-Scripts werden von Klipper
      // in manchen Setups anders verarbeitet (führte zu spurious
      // "X is not valid for MACRO"-Fehlern).
      final captured = verify(mockClient.post(
        Uri.parse('http://192.168.1.179/printer/gcode/script'),
        headers: captureAnyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured;

      // captured enthält Paare [headers, body] für jeden Aufruf
      expect(captured.length, 6); // 3 Aufrufe × 2 captured-Argumente
      final scripts = <String>[];
      for (var i = 1; i < captured.length; i += 2) {
        scripts.add((jsonDecode(captured[i] as String) as Map)['script'] as String);
      }

      // Reihenfolge wie Spoolman selbst:
      expect(scripts[0], 'SET_GCODE_VARIABLE MACRO=T0 VARIABLE=spool_id VALUE=3');
      expect(scripts[1], 'SAVE_VARIABLE VARIABLE=t0__spool_id VALUE=3');
      expect(scripts[2], 'SET_CHANNEL_SPOOL CHANNEL=0 ID=3');
    });

    test('extrahiert die Klipper-Fehlermeldung statt rohes JSON', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            '{"error":{"code":400,"message":"The value \'T3\' is not valid for MACRO","traceback":"..."}}',
            400,
          ));

      try {
        await service.setActiveSpool(
            printerIp: 'p', spoolId: '7', slot: 3);
        fail('expected MoonrakerException');
      } on MoonrakerException catch (e) {
        // Die freundliche Klipper-Message muss drinstehen, der lange
        // Traceback nicht.
        expect(e.message, contains("'T3' is not valid for MACRO"));
        expect(e.message, isNot(contains('Traceback')));
      }
    });

    test('wirft MoonrakerException bei HTTP-Fehler', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('error', 500));

      expect(
        () => service.setActiveSpool(
          printerIp: '192.168.1.179',
          spoolId: '3',
          slot: 0,
        ),
        throwsA(isA<MoonrakerException>()),
      );
    });

    test('wirft MoonrakerException bei Timeout', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 10));
        return http.Response('', 200);
      });

      expect(
        () => service.setActiveSpool(
          printerIp: '192.168.1.179',
          spoolId: '3',
          slot: 0,
        ),
        throwsA(isA<MoonrakerException>()),
      );
    });
  });
}
