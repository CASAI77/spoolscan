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
      // fetchSpool behält die strikte Prüfung: filament muss vorhanden sein
      if (json['filament'] == null) {
        throw SpoolmanException('Kein filament-Feld in Response');
      }
      return _parseSpool(spoolId, json);
    } on SpoolmanException {
      rethrow;
    } catch (e) {
      throw SpoolmanException('Verbindungsfehler: $e');
    }
  }

  Future<List<Spool>> listSpools(String baseUrl) async {
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/spool');
    final r = await client.get(uri).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) {
      throw SpoolmanException('HTTP ${r.statusCode}: ${r.body}');
    }
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((j) => _parseSpool(j['id'].toString(), j))
        .toList();
  }

  Future<int> createVendor(String baseUrl, {required String name}) async {
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/vendor');
    final r = await client
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'name': name}))
        .timeout(const Duration(seconds: 5));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw SpoolmanException('createVendor HTTP ${r.statusCode}: ${r.body}');
    }
    return (jsonDecode(r.body) as Map<String, dynamic>)['id'] as int;
  }

  Future<int> createFilament(
    String baseUrl, {
    required int vendorId,
    required String name,
    required String material,
    required String colorHex,
    int? extruderTemp,
    double diameter = 1.75,
    double density = 1.24,
  }) async {
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/filament');
    final body = <String, dynamic>{
      'vendor_id': vendorId,
      'name': name,
      'material': material,
      'color_hex': colorHex,
      'diameter': diameter,
      'density': density,
      if (extruderTemp != null) 'settings_extruder_temp': extruderTemp,
    };
    final r = await client
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 5));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw SpoolmanException('createFilament HTTP ${r.statusCode}: ${r.body}');
    }
    return (jsonDecode(r.body) as Map<String, dynamic>)['id'] as int;
  }

  Future<Spool> createSpool(
    String baseUrl, {
    required int filamentId,
    int? initialWeight,
    Map<String, String>? extra,
  }) async {
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/spool');
    final body = <String, dynamic>{
      'filament_id': filamentId,
      if (initialWeight != null) 'initial_weight': initialWeight,
      // Spoolman erwartet extra-Werte als JSON-encodierte Strings:
      if (extra != null)
        'extra': extra.map((k, v) => MapEntry(k, jsonEncode(v))),
    };
    final r = await client
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 5));
    if (r.statusCode != 200 && r.statusCode != 201) {
      throw SpoolmanException('createSpool HTTP ${r.statusCode}: ${r.body}');
    }
    final j = jsonDecode(r.body) as Map<String, dynamic>;
    return _parseSpool(j['id'].toString(), j);
  }

  Future<void> patchSpoolExtra(
    String baseUrl,
    String spoolId,
    Map<String, String> extra,
  ) async {
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/spool/$spoolId');
    final body = jsonEncode({
      'extra': extra.map((k, v) => MapEntry(k, jsonEncode(v))),
    });
    final r = await client
        .patch(uri,
            headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) {
      throw SpoolmanException('patchSpoolExtra HTTP ${r.statusCode}: ${r.body}');
    }
  }

  Future<List<SpoolmanVendor>> listVendors(String baseUrl) async {
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/vendor');
    final r = await client.get(uri).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) {
      throw SpoolmanException('listVendors HTTP ${r.statusCode}: ${r.body}');
    }
    final list = jsonDecode(r.body) as List<dynamic>;
    return list
        .cast<Map<String, dynamic>>()
        .map((j) => SpoolmanVendor(id: j['id'] as int, name: j['name'] as String))
        .toList();
  }

  Future<List<SpoolmanFilament>> listFilaments(
    String baseUrl, {
    int? vendorId,
  }) async {
    final q = vendorId != null ? '?vendor.id=$vendorId' : '';
    final uri = Uri.parse('http://${_clean(baseUrl)}/api/v1/filament$q');
    final r = await client.get(uri).timeout(const Duration(seconds: 5));
    if (r.statusCode != 200) {
      throw SpoolmanException('listFilaments HTTP ${r.statusCode}: ${r.body}');
    }
    final list = jsonDecode(r.body) as List<dynamic>;
    return list.cast<Map<String, dynamic>>().map((j) {
      final v = j['vendor'] as Map<String, dynamic>?;
      return SpoolmanFilament(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        material: j['material'] as String? ?? '',
        colorHex: j['color_hex'] as String? ?? '',
        vendorId: v?['id'] as int?,
        vendorName: v?['name'] as String?,
        extruderTemp: j['settings_extruder_temp'] as int?,
      );
    }).toList();
  }

  String _clean(String baseUrl) =>
      baseUrl.replaceFirst(RegExp(r'^https?://'), '');

  Spool _parseSpool(String spoolId, Map<String, dynamic> json) {
    final filament = json['filament'] as Map<String, dynamic>?;
    final vendor = filament?['vendor'] as Map<String, dynamic>?;
    final extra = json['extra'] as Map<String, dynamic>?;

    String? nfcUid;
    if (extra != null && extra['nfc_uid'] != null) {
      // Spoolman speichert extra-Werte als JSON-encodierte Strings
      try {
        nfcUid = jsonDecode(extra['nfc_uid'] as String) as String?;
      } catch (_) {
        nfcUid = extra['nfc_uid'] as String?;
      }
    }

    final temp = filament?['settings_extruder_temp'] as int?;
    return Spool(
      spoolId: spoolId,
      brand: vendor?['name'] as String?,
      type: filament?['name'] as String?,
      colorHex: filament?['color_hex'] as String?,
      minTemp: temp,
      maxTemp: temp,
      nfcUid: nfcUid,
      remainingWeight: (json['remaining_weight'] as num?)?.toInt(),
      weightTotal: (json['initial_weight'] as num?)?.toInt(),
    );
  }
}

class SpoolmanVendor {
  final int id;
  final String name;
  SpoolmanVendor({required this.id, required this.name});
}

class SpoolmanFilament {
  final int id;
  final String name;
  final String material;
  final String colorHex;
  final int? vendorId;
  final String? vendorName;
  final int? extruderTemp;
  SpoolmanFilament({
    required this.id,
    required this.name,
    required this.material,
    required this.colorHex,
    this.vendorId,
    this.vendorName,
    this.extruderTemp,
  });
}
