import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const delegate = _AppLocalizationsDelegate();

  bool get _de => locale.languageCode == 'de';

  // ScanScreen
  String get scanInstruction => _de ? 'Handy an Spule halten' : 'Hold phone to spool';
  String get scanSubtitle => _de ? 'NFC-Tag wird automatisch erkannt' : 'NFC tag is automatically detected';
  String get scanRetrying => _de ? 'Neuer Versuch...' : 'Retrying...';
  String get errorNfcUnavailable => _de ? 'NFC nicht verfügbar' : 'NFC not available';
  String get errorNoNdef => _de ? 'Tag hat keine NDEF-Daten' : 'Tag has no NDEF data';
  String get errorEmptyTag => _de ? 'Tag ist leer' : 'Tag is empty';
  String get errorNoTextRecord => _de ? 'Kein Text-Record auf dem Tag' : 'No text record on tag';
  String scanError(String e) => _de ? 'Scan-Fehler: $e' : 'Scan error: $e';

  // DetailScreen
  String get detailTitle => _de ? 'Spule erkannt' : 'Spool detected';
  String get detailUnknown => _de ? 'Unbekannt' : 'Unknown';
  String get detailSlotQuestion => _de ? 'In welchen Slot?' : 'Assign to slot?';

  // SettingsScreen
  String get settingsTitle => _de ? 'Einstellungen' : 'Settings';
  String get settingsPrinterIp => _de ? 'Drucker-IP (Moonraker)' : 'Printer IP (Moonraker)';
  String get settingsSpoolmanUrl => 'Spoolman URL (host:port)';
  String get settingsSave => _de ? 'Speichern' : 'Save';
  String get settingsLanguage => _de ? 'Sprache' : 'Language';

  // ConfirmationScreen
  String get confirmAssigned => _de ? 'Zugewiesen!' : 'Assigned!';
  String get confirmError => _de ? 'Fehler' : 'Error';
  String get confirmSpoolmanUpdated => _de ? 'Spoolman aktualisiert ✓' : 'Spoolman updated ✓';
  String get confirmNextSpool => _de ? 'Nächste Spule' : 'Next spool';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['de', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_) => false;
}
