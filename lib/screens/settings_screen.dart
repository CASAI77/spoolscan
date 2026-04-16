import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../main.dart' show localeNotifier;
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _service = SettingsService();
  final _printerController = TextEditingController();
  final _spoolmanController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _service.getPrinterIp().then((ip) => _printerController.text = ip);
    _service.getSpoolmanUrl().then((url) => _spoolmanController.text = url);
  }

  @override
  void dispose() {
    _printerController.dispose();
    _spoolmanController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ip = _printerController.text.trim();
    if (ip.isEmpty) return;
    await _service.setPrinterIp(ip);
    final url = _spoolmanController.text.trim();
    if (url.isNotEmpty) await _service.setSpoolmanUrl(url);
    setState(() => _saved = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _setLanguage(String lang) async {
    await _service.setLanguage(lang);
    localeNotifier.value = Locale(lang);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLang = localeNotifier.value.languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settingsPrinterIp,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _printerController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: SettingsService.defaultPrinterIp,
                border: const OutlineInputBorder(),
                suffixIcon: _saved
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.settingsSpoolmanUrl,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _spoolmanController,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: SettingsService.defaultSpoolmanUrl,
                border: const OutlineInputBorder(),
                suffixIcon: _saved
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: Text(l10n.settingsSave),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              l10n.settingsLanguage,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<Locale>(
              valueListenable: localeNotifier,
              builder: (_, locale, __) => SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'de', label: Text('Deutsch')),
                  ButtonSegment(value: 'en', label: Text('English')),
                ],
                selected: {locale.languageCode},
                onSelectionChanged: (sel) => _setLanguage(sel.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
