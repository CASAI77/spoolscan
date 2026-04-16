import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/spool.dart';
import '../services/moonraker_service.dart';
import '../services/settings_service.dart';
import '../services/spoolman_service.dart';
import 'confirmation_screen.dart';

class DetailScreen extends StatefulWidget {
  final Spool spool;
  const DetailScreen({super.key, required this.spool});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final _moonraker = MoonrakerService();
  final _settings = SettingsService();
  final _spoolman = SpoolmanService();
  bool _loading = false;
  bool _loadingSpoolman = true;
  Spool? _enrichedSpool;
  String? _spoolmanError;

  Spool get _displaySpool => _enrichedSpool ?? widget.spool;

  @override
  void initState() {
    super.initState();
    _loadSpoolmanData();
  }

  Future<void> _loadSpoolmanData() async {
    final url = await _settings.getSpoolmanUrl();
    if (url.isEmpty) {
      if (mounted) setState(() => _loadingSpoolman = false);
      return;
    }
    try {
      final enriched = await _spoolman.fetchSpool(url, widget.spool.spoolId);
      if (mounted) {
        setState(() {
          _enrichedSpool = enriched;
          _loadingSpoolman = false;
        });
      }
    } on SpoolmanException catch (e) {
      if (mounted) setState(() {
        _loadingSpoolman = false;
        _spoolmanError = e.message;
      });
    } catch (e) {
      if (mounted) setState(() {
        _loadingSpoolman = false;
        _spoolmanError = e.toString();
      });
    }
  }

  Future<void> _assignSlot(int slot) async {
    setState(() => _loading = true);

    String? errorMessage;
    try {
      final ip = await _settings.getPrinterIp();
      await _moonraker.setActiveSpool(
        printerIp: ip,
        spoolId: widget.spool.spoolId,
        slot: slot,
      );
    } on MoonrakerException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Unbekannter Fehler: $e';
    } finally {
      setState(() => _loading = false);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmationScreen(
          success: errorMessage == null,
          message: errorMessage ?? 'Spule zugewiesen',
          spoolLabel:
              '${_displaySpool.brand ?? ''} ${_displaySpool.type ?? ''}'
                  .trim(),
          slotLabel: 'T$slot',
        ),
      ),
    );
  }

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.grey;
    final clean = hex.startsWith('#') ? hex.substring(1) : hex;
    if (clean.length != 6) return Colors.grey;
    try {
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spool = _displaySpool;
    final color = _parseColor(spool.colorHex);

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).detailTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _loadingSpoolman
                          ? const SizedBox(
                              height: 48,
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white24, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${spool.brand ?? AppLocalizations.of(context).detailUnknown} ${spool.type ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (spool.minTemp != null &&
                                          spool.maxTemp != null)
                                        Text(
                                          '${spool.minTemp}–${spool.maxTemp} °C',
                                          style: const TextStyle(
                                              color: Colors.white70),
                                        ),
                                      Text(
                                        'ID: ${spool.spoolId}',
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (_spoolmanError != null) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'Spoolman: $_spoolmanError',
                        style: const TextStyle(
                            color: Colors.orange, fontSize: 11),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Text(
                    AppLocalizations.of(context).detailSlotQuestion,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    children: List.generate(4, (i) {
                      return FilledButton(
                        onPressed: () => _assignSlot(i),
                        style: FilledButton.styleFrom(
                          textStyle: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        child: Text('T$i'),
                      );
                    }),
                  ),
                ],
              ),
            ),
    );
  }
}
