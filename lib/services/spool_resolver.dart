import '../models/spool.dart';
import 'spoolman_service.dart';
import 'tag_reader.dart';

enum ResolveStage { foundById, foundByUid, notFound }

class ResolveResult {
  final ResolveStage stage;
  final Spool? spool;
  ResolveResult(this.stage, [this.spool]);
}

class SpoolResolver {
  final SpoolmanService spoolman;
  final String baseUrl;
  final Duration cacheTtl;

  List<Spool>? _cachedSpools;
  DateTime? _cachedAt;

  SpoolResolver({
    required this.spoolman,
    required this.baseUrl,
    this.cacheTtl = const Duration(seconds: 30),
  });

  Future<ResolveResult> resolve(TagReadResult tag) async {
    // Stufe 1: Spoolman-ID aus dem Tag (SpoolCompanion / OpenSpool)
    final tagSpoolId = tag.spool?.spoolId;
    if (tagSpoolId != null && tagSpoolId.isNotEmpty) {
      try {
        final spool = await spoolman.fetchSpool(baseUrl, tagSpoolId);
        await _selfHeal(spool, tag.nfcUid);
        return ResolveResult(ResolveStage.foundById, spool);
      } on SpoolmanException {
        // → fällt durch zu Stufe 2
      }
    }

    // Stufe 2: Suche per NFC-UID in vollständiger Spool-Liste
    final spools = await _loadSpoolsCached();
    Spool? match;
    for (final s in spools) {
      if (s.nfcUid == tag.nfcUid) {
        match = s;
        break;
      }
    }
    if (match != null) {
      return ResolveResult(ResolveStage.foundByUid, match);
    }

    // Stufe 3: nichts gefunden
    return ResolveResult(ResolveStage.notFound);
  }

  /// Schreibt UID nach in extra.nfc_uid, falls dort noch leer.
  /// Nicht-blockierend bei Fehler.
  Future<void> _selfHeal(Spool spool, String nfcUid) async {
    if (spool.nfcUid == nfcUid) return;
    if (spool.nfcUid != null && spool.nfcUid!.isNotEmpty) return;
    try {
      await spoolman.patchSpoolExtra(baseUrl, spool.spoolId, {'nfc_uid': nfcUid});
      _invalidateCache();
    } catch (_) {
      // best-effort: Fehler unterdrücken, User-Flow nicht blockieren
    }
  }

  Future<List<Spool>> _loadSpoolsCached() async {
    final now = DateTime.now();
    if (_cachedSpools != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < cacheTtl) {
      return _cachedSpools!;
    }
    final fresh = await spoolman.listSpools(baseUrl);
    _cachedSpools = fresh;
    _cachedAt = now;
    return fresh;
  }

  void _invalidateCache() {
    _cachedSpools = null;
    _cachedAt = null;
  }
}
