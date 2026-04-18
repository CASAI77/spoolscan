import 'dart:async' show unawaited;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../l10n/app_localizations.dart';
import '../models/spool.dart';
import '../services/settings_service.dart';
import '../services/spoolman_service.dart';
import '../services/spool_resolver.dart';
import '../services/spool_creator.dart';
import '../services/tag_reader.dart';
import 'detail_screen.dart';
import 'new_spool_confirm_screen.dart';
import 'new_spool_form_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  bool _scanning = false;
  String? _errorMessage;
  bool _isStarting = false;
  bool _tagProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(NfcManager.instance.stopSession());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession();
    } else if (state == AppLifecycleState.paused) {
      NfcManager.instance.stopSession();
      setState(() => _scanning = false);
    }
  }

  Future<void> _startSession() async {
    if (_isStarting || _scanning || _tagProcessing) return;
    _isStarting = true;
    try {
      final isAvailable = await NfcManager.instance.isAvailable();
      if (!isAvailable) {
        _showError(AppLocalizations.of(context).errorNfcUnavailable);
        return;
      }
      if (!mounted) return;
      setState(() {
        _scanning = true;
        _errorMessage = null;
      });
      // Explizite Polling-Optionen für ALLE Tag-Technologien:
      // verhindert dass Samsung-Geräte bei z.B. unformatierten NTAGs
      // konkurrierend die System-Tags-App aufrufen.
      NfcManager.instance.startSession(
        onDiscovered: _onTagDiscovered,
        pollingOptions: const {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
      );
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _onTagDiscovered(NfcTag tag) async {
    if (!mounted || _tagProcessing) return;
    _tagProcessing = true;
    setState(() => _scanning = false);

    final l10n = AppLocalizations.of(context);
    String? errorMsg;
    Spool? resultSpool;

    try {
      // 1. UID + Text-Payload aus dem Tag ziehen
      final nfcaData = tag.data['nfca'] as Map<dynamic, dynamic>?;
      final ndefData = tag.data['ndef'] as Map<dynamic, dynamic>?;
      final uidBytes = (nfcaData?['identifier'] ?? ndefData?['identifier']) as Uint8List?;
      if (uidBytes == null) {
        errorMsg = 'NFC-UID nicht lesbar';
      } else {
        final nfcUid = TagReader.uidFromBytes(uidBytes);
        String textPayload = '';
        final ndef = Ndef.from(tag);
        if (ndef != null) {
          // ndef.read() darf scheitern (leerer/unformatierter Tag).
          // Dann bleibt textPayload leer → führt in den Anlage-Flow,
          // statt einen User-sichtbaren Fehler zu zeigen.
          try {
            final message = await ndef.read();
            for (final record in message.records) {
              if (_isTextRecord(record)) {
                final langLen = record.payload[0] & 0x3F;
                textPayload = utf8.decode(record.payload.sublist(langLen + 1));
                break;
              }
            }
          } catch (_) {
            // textPayload bleibt '' → TagReader.parse liefert TagFormat.unknown
          }
        }

        // 2. TagReader: Format + Spool-Vorschlag
        final tagResult = TagReader.parse(nfcUid: nfcUid, textPayload: textPayload);

        // 3. Resolver
        final settings = SettingsService();
        final spoolmanUrl = await settings.getSpoolmanUrl();
        final spoolman = SpoolmanService();
        final resolver = SpoolResolver(spoolman: spoolman, baseUrl: spoolmanUrl);
        final res = await resolver.resolve(tagResult);

        if (res.stage == ResolveStage.foundById ||
            res.stage == ResolveStage.foundByUid) {
          resultSpool = res.spool;
        } else {
          // 4. Anlage-Flow
          // Reader Mode aktiv lassen, damit Android nicht den Tag selbst dispatcht
          // (genau wie im Match-Pfad). Die finally-Klausel unten stoppt die Session.
          final creator = SpoolCreator(spoolman: spoolman, baseUrl: spoolmanUrl);

          if (creator.canAutoCreate(tagResult)) {
            resultSpool = await _showAutoConfirm(tagResult, creator);
          } else {
            resultSpool = await _showManualForm(tagResult, creator, spoolmanUrl, spoolman);
          }
        }
      }
    } on FormatException catch (e) {
      errorMsg = e.message;
    } catch (e) {
      errorMsg = l10n.scanError('$e');
    }

    if (errorMsg != null) {
      await NfcManager.instance.stopSession();
      _showError(errorMsg);
      _tagProcessing = false;
      return;
    }

    try {
      if (resultSpool != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(spool: resultSpool!)),
        );
      }
    } finally {
      await NfcManager.instance.stopSession();
      _tagProcessing = false;
      if (mounted) _startSession();
    }
  }

  Future<Spool?> _showAutoConfirm(TagReadResult tag, SpoolCreator creator) async {
    Spool? created;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => NewSpoolConfirmScreen(
        tag: tag,
        onConfirm: () async {
          try {
            created = await creator.createAuto(tag);
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).createError('$e'))),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      )),
    );
    return created;
  }

  Future<Spool?> _showManualForm(
    TagReadResult tag,
    SpoolCreator creator,
    String spoolmanUrl,
    SpoolmanService spoolman,
  ) async {
    final vendors = await spoolman.listVendors(spoolmanUrl);
    final filaments = await spoolman.listFilaments(spoolmanUrl);
    final knownMaterials = filaments.map((f) => f.material).toSet().toList()..sort();

    Spool? created;
    if (!mounted) return null;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => NewSpoolFormScreen(
        nfcUid: tag.nfcUid,
        knownVendors: vendors.map((v) => v.name).toList(),
        knownMaterials: knownMaterials,
        prefillBrand: tag.spool?.brand,
        prefillMaterial: tag.spool?.type,
        prefillColorHex: tag.spool?.colorHex,
        prefillWeightTotal: tag.spool?.weightTotal,
        prefillExtruderTemp: tag.spool?.minTemp,
        onSave: (form) async {
          try {
            created = await creator.createManual(form);
            if (mounted) Navigator.pop(context);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context).createError('$e'))),
              );
            }
          }
        },
        onCancel: () => Navigator.pop(context),
      )),
    );
    return created;
  }

  bool _isTextRecord(NdefRecord record) =>
      record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
      record.type.length == 1 &&
      record.type[0] == 0x54;

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _scanning = false;
      _errorMessage = message;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SpoolScan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null) ...[
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).scanRetrying, style: const TextStyle(color: Colors.grey)),
            ] else ...[
              _AnimatedNfcIcon(scanning: _scanning),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context).scanInstruction,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).scanSubtitle,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnimatedNfcIcon extends StatefulWidget {
  final bool scanning;
  const _AnimatedNfcIcon({required this.scanning});

  @override
  State<_AnimatedNfcIcon> createState() => _AnimatedNfcIconState();
}

class _AnimatedNfcIconState extends State<_AnimatedNfcIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Icon(
        Icons.nfc,
        size: 96,
        color: widget.scanning
            ? Theme.of(context).colorScheme.primary
            : Colors.grey,
      ),
    );
  }
}
