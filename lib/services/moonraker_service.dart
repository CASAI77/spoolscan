import 'dart:convert';
import 'package:http/http.dart' as http;

class MoonrakerException implements Exception {
  final String message;
  MoonrakerException(this.message);

  @override
  String toString() => 'MoonrakerException: $message';
}

class MoonrakerService {
  final http.Client client;

  MoonrakerService({http.Client? client}) : client = client ?? http.Client();

  Future<void> setActiveSpool({
    required String printerIp,
    required String spoolId,
    required int slot,
  }) async {
    final uri = Uri.parse('http://$printerIp/printer/gcode/script');
    final script = 'SET_ACTIVE_SPOOL ID=$spoolId';

    try {
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'script': script}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw MoonrakerException('HTTP ${response.statusCode}: ${response.body}');
      }
    } on MoonrakerException {
      rethrow;
    } catch (e) {
      throw MoonrakerException('Verbindungsfehler: $e');
    }
  }
}
