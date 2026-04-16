import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';

final localeNotifier = ValueNotifier<Locale>(const Locale('de'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final lang = prefs.getString('language') ?? 'de';
  localeNotifier.value = Locale(lang);
  runApp(const SpoolScanApp());
}

class SpoolScanApp extends StatelessWidget {
  const SpoolScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (_, locale, __) => MaterialApp(
        title: 'SpoolScan',
        debugShowCheckedModeBanner: false,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('de'),
          Locale('en'),
        ],
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A9EFF),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const ScanScreen(),
        routes: {
          '/settings': (context) => const SettingsScreen(),
        },
      ),
    );
  }
}
