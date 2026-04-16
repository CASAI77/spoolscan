import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/spool.dart';

class SpoolmanException implements Exception {
  final String message;
  SpoolmanException(this.message);

  @override
  String toString() => 'SpoolmanException: $message';
}

class SpoolmanService {
  final http.Client client;

  SpoolmanService({http.Client? client}) : client = client ?? http.Client();

  Future<Spool> fetchSpool(String baseUrl, String spoolId) async {
    final cleanUrl = baseUrl.replaceFirst(RegExp(r'^https?://'), '');
    final uri = Uri.parse('http://$cleanUrl/api/v1/spool/$spoolId');
    try {
      final response = await client
          .get(uri)
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw SpoolmanException('HTTP ${response.statusCode}: ${response.body}');
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseSpool(spoolId, json);
    } on SpoolmanException {
      rethrow;
    } catch (e) {
      throw SpoolmanException('Verbindungsfehler: $e');
    }
  }

  Spool _parseSpool(String spoolId, Map<String, dynamic> json) {
    final filament = json['filament'] as Map<String, dynamic>?;
    if (filament == null) {
      throw SpoolmanException('Kein filament-Feld in Response');
    }
    final vendor = filament['vendor'] as Map<String, dynamic>?;
    final brand = vendor?['name'] as String?;
    final type = filament['name'] as String?;
    final colorHex = filament['color_hex'] as String?;
    final temp = filament['settings_extruder_temp'] as int?;

    return Spool(
      spoolId: spoolId,
      brand: brand,
      type: type,
      colorHex: colorHex,
      minTemp: temp,
      maxTemp: temp,
    );
  }
}
