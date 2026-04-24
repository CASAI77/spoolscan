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
  /// Sendet drei GCode-Befehle in einem einzigen Script:
  /// 1. SET_CHANNEL_SPOOL CHANNEL=<slot> ID=<id>
  ///    → setzt den Klipper-internen Channel-State (Davo1624 macro,
  ///      wird beim Druck für Verbrauchstracking ausgewertet)
  /// 2. SET_GCODE_VARIABLE MACRO=T<slot> VARIABLE=spool_id VALUE=<id>
  ///    → setzt die GCode-Variable des Tool-Macros (was Spoolman selbst
  ///      beim manuellen "Rolle wechseln" Klick im Web sendet)
  /// 3. SAVE_VARIABLE VARIABLE=t<slot>__spool_id VALUE=<id>
  ///    → persistiert die Zuweisung in Klippers variables.cfg, damit
  ///      Spoolman die "Aktive Rolle"-Anzeige aktualisiert und der
  ///      Zustand auch nach Neustart erhalten bleibt
  Future<void> setActiveSpool({
    required String printerIp,
    required String spoolId,
    required int slot,
  }) async {
    final uri = Uri.parse('http://$printerIp/printer/gcode/script');
    final script = 'SET_CHANNEL_SPOOL CHANNEL=$slot ID=$spoolId\n'
        'SET_GCODE_VARIABLE MACRO=T$slot VARIABLE=spool_id VALUE=$spoolId\n'
        'SAVE_VARIABLE VARIABLE=t${slot}__spool_id VALUE=$spoolId';

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
