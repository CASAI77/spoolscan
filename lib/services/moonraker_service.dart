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

  /// Weist eine Spule einem Snapmaker-U1-Slot (T0–T3) zu UND markiert sie
  /// als aktive Rolle in Spoolman.
  ///
  /// Sendet die drei nötigen GCode-Befehle als SEPARATE Aufrufe — genauso
  /// wie es Spoolman selbst beim manuellen "Rolle wechseln"-Klick im Web
  /// macht. Multi-Line-Scripts (alles in einem Aufruf) werden von Klipper
  /// in manchen Setups anders verarbeitet und führen zu spurious
  /// "X is not valid for MACRO"-Fehlern.
  ///
  /// Reihenfolge wie bei Spoolman selbst:
  /// 1. SET_GCODE_VARIABLE MACRO=T<slot> VARIABLE=spool_id VALUE=<id>
  /// 2. SAVE_VARIABLE VARIABLE=t<slot>__spool_id VALUE=<id>
  /// 3. SET_CHANNEL_SPOOL CHANNEL=<slot> ID=<id>  (Davo1624 macro,
  ///    für Verbrauchstracking während Druck)
  ///
  /// Schlägt einer der Befehle fehl, wird trotzdem versucht die übrigen
  /// auszuführen. Am Ende werden gesammelte Fehler als kompakte Meldung
  /// geworfen (kein 100-Zeilen-Klipper-Stacktrace).
  Future<void> setActiveSpool({
    required String printerIp,
    required String spoolId,
    required int slot,
  }) async {
    final commands = [
      'SET_GCODE_VARIABLE MACRO=T$slot VARIABLE=spool_id VALUE=$spoolId',
      'SAVE_VARIABLE VARIABLE=t${slot}__spool_id VALUE=$spoolId',
      'SET_CHANNEL_SPOOL CHANNEL=$slot ID=$spoolId',
    ];
    final errors = <String>[];
    for (final cmd in commands) {
      try {
        await _runScript(printerIp, cmd);
      } on MoonrakerException catch (e) {
        errors.add(e.message);
      }
    }
    if (errors.isNotEmpty) {
      throw MoonrakerException(errors.join(' | '));
    }
  }

  Future<void> _runScript(String printerIp, String script) async {
    final uri = Uri.parse('http://$printerIp/printer/gcode/script');
    try {
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'script': script}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw MoonrakerException(_extractErrorMessage(response.body, response.statusCode));
      }
    } on MoonrakerException {
      rethrow;
    } catch (e) {
      throw MoonrakerException('Verbindungsfehler: $e');
    }
  }

  /// Holt die kurze Klipper-Fehlermeldung aus der Response (z.B.
  /// "The value 'T3' is not valid for MACRO") statt den ganzen Stacktrace.
  String _extractErrorMessage(String body, int statusCode) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      final msg = error?['message'] as String?;
      if (msg != null && msg.isNotEmpty) return msg;
    } catch (_) {/* fall through */}
    return 'HTTP $statusCode';
  }
}
