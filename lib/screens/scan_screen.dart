import 'dart:async' show unawaited;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import '../l10n/app_localizations.dart';
import '../models/spool.dart';
import 'detail_screen.dart';

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
      NfcManager.instance.startSession(onDiscovered: _onTagDiscovered);
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _onTagDiscovered(NfcTag tag) async {
    if (!mounted || _tagProcessing) return;
    _tagProcessing = true;
    setState(() => _scanning = false);

    Spool? spool;
    String? errorMsg;

    try {
      final ndef = Ndef.from(tag);
      final l10n = AppLocalizations.of(context);
      if (ndef == null) {
        errorMsg = l10n.errorNoNdef;
      } else {
        final message = await ndef.read();
        if (message.records.isEmpty) {
          errorMsg = l10n.errorEmptyTag;
        } else {
          String? payload;
          for (final record in message.records) {
            if (_isTextRecord(record)) {
              final langLen = record.payload[0] & 0x3F;
              payload = utf8.decode(record.payload.sublist(langLen + 1));
              break;
            }
          }
          if (payload == null) {
            errorMsg = l10n.errorNoTextRecord;
          } else {
            spool = Spool.fromText(payload);
          }
        }
      }
    } on FormatException catch (e) {
      errorMsg = e.message;
    } catch (e) {
      errorMsg = AppLocalizations.of(context).scanError('$e');
    }

    if (errorMsg != null) {
      // Error: stop session and show error message
      await NfcManager.instance.stopSession();
      _showError(errorMsg);
      _tagProcessing = false;
      return;
    }

    // Success: navigate while keeping reader mode ACTIVE.
    // Keeping the NFC session open during navigation prevents Android from
    // re-activating its default dispatch (which fires a second NFC intent and
    // disrupts the navigation). Any tag events during navigation are blocked
    // by _tagProcessing = true.
    try {
      if (spool != null && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(spool: spool!)),
        );
      }
    } finally {
      await NfcManager.instance.stopSession();
      _tagProcessing = false;
      if (mounted) _startSession();
    }
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
