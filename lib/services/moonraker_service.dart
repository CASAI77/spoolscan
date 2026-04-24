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

  /// Weist eine Spule einem Snapmaker-U1-Slot (T0–T3) zu UND aktiviert sie
  /// als aktive Rolle in Spoolman.
  ///
  /// Verwendet die Custom-Macros aus dem Davo1624/snapmaker-u1 Setup:
  /// - SET_CHANNEL_SPOOL CHANNEL=<slot> ID=<id>  → Slot-Zuweisung
  /// - USE_CHANNEL CHANNEL=<slot>                → Aktivierung
  ///
  /// Beide Befehle werden in einem einzigen GCode-Script gesendet,
  /// damit Spoolman die "Aktive Rolle"-Anzeige korrekt aktualisiert.
  Future<void> setActiveSpool({
    required String printerIp,
    required String spoolId,
    required int slot,
  }) async {
    final uri = Uri.parse('http://$printerIp/printer/gcode/script');
    final script =
        'SET_CHANNEL_SPOOL CHANNEL=$slot ID=$spoolId\nUSE_CHANNEL CHANNEL=$slot';

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
