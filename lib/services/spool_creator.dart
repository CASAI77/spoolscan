import '../models/spool.dart';
import 'spoolman_service.dart';
import 'tag_reader.dart';

class NewSpoolFormData {
  final String brand;
  final String material;
  final String colorHex;
  final int? weightTotal;
  final int? extruderTemp;
  final String nfcUid;

  NewSpoolFormData({
    required this.brand,
    required this.material,
    required this.colorHex,
    this.weightTotal,
    this.extruderTemp,
    required this.nfcUid,
  });
}

class SpoolCreator {
  final SpoolmanService spoolman;
  final String baseUrl;

  SpoolCreator({required this.spoolman, required this.baseUrl});

  static const Map<String, int> _defaultTemps = {
    'PLA': 210,
    'PETG': 240,
    'ABS': 250,
    'ASA': 250,
    'TPU': 220,
    'PA': 270,
  };

  /// Standard-Dichten in g/cm³ (Basis: gängige Hersteller-Datenblätter).
  static const Map<String, double> _defaultDensities = {
    'PLA': 1.24,
    'PETG': 1.27,
    'ABS': 1.04,
    'ASA': 1.07,
    'TPU': 1.21,
    'PA': 1.14,
  };

  static int? defaultTempForMaterial(String material) =>
      _defaultTemps[material.toUpperCase()];

  static double defaultDensityForMaterial(String material) =>
      _defaultDensities[material.toUpperCase()] ?? 1.24;

  bool canAutoCreate(TagReadResult tag) {
    final s = tag.spool;
    if (s == null) return false;
    return (s.brand?.isNotEmpty ?? false) &&
        (s.type?.isNotEmpty ?? false) &&
        (s.colorHex?.isNotEmpty ?? false);
  }

  Future<Spool> createAuto(TagReadResult tag) async {
    final s = tag.spool!;
    return _create(
      brand: s.brand!,
      filamentName: s.type!,
      material: s.type!,
      colorHex: s.colorHex!,
      extruderTemp: s.minTemp ?? defaultTempForMaterial(s.type!),
      weightTotal: s.weightTotal ?? 1000,
      nfcUid: tag.nfcUid,
    );
  }

  Future<Spool> createManual(NewSpoolFormData form) {
    return _create(
      brand: form.brand,
      filamentName: form.material,
      material: form.material,
      colorHex: form.colorHex,
      extruderTemp: form.extruderTemp ?? defaultTempForMaterial(form.material),
      weightTotal: form.weightTotal ?? 1000,
      nfcUid: form.nfcUid,
    );
  }

  Future<Spool> _create({
    required String brand,
    required String filamentName,
    required String material,
    required String colorHex,
    required int? extruderTemp,
    required int weightTotal,
    required String nfcUid,
  }) async {
    final vendorId = await _findOrCreateVendor(brand);
    final filamentId = await _findOrCreateFilament(
      vendorId: vendorId,
      name: filamentName,
      material: material,
      colorHex: colorHex,
      extruderTemp: extruderTemp,
    );
    return spoolman.createSpool(
      baseUrl,
      filamentId: filamentId,
      initialWeight: weightTotal,
      extra: {'nfc_uid': nfcUid},
    );
  }

  Future<int> _findOrCreateVendor(String name) async {
    final vendors = await spoolman.listVendors(baseUrl);
    for (final v in vendors) {
      if (v.name.toLowerCase() == name.toLowerCase()) return v.id;
    }
    return spoolman.createVendor(baseUrl, name: name);
  }

  Future<int> _findOrCreateFilament({
    required int vendorId,
    required String name,
    required String material,
    required String colorHex,
    required int? extruderTemp,
  }) async {
    final filaments = await spoolman.listFilaments(baseUrl, vendorId: vendorId);
    for (final f in filaments) {
      if (f.name.toLowerCase() == name.toLowerCase() &&
          f.material.toLowerCase() == material.toLowerCase() &&
          f.colorHex.toLowerCase() == colorHex.toLowerCase()) {
        return f.id;
      }
    }
    // density wird aus Material-Tabelle abgeleitet; diameter bleibt 1.75 (Default)
    return spoolman.createFilament(
      baseUrl,
      vendorId: vendorId,
      name: name,
      material: material,
      colorHex: colorHex,
      extruderTemp: extruderTemp,
      density: defaultDensityForMaterial(material),
    );
  }
}
