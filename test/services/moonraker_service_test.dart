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

    test('sendet korrekten POST-Request an Moonraker', () async {
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

      final captured = verify(mockClient.post(
        Uri.parse('http://192.168.1.179/printer/gcode/script'),
        headers: captureAnyNamed('headers'),
        body: captureAnyNamed('body'),
      )).captured;

      final body = jsonDecode(captured[1] as String);
      expect(body['script'], contains('SET_ACTIVE_SPOOL'));
      expect(body['script'], contains('3'));
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
