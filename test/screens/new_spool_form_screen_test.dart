import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/l10n/app_localizations.dart';
import 'package:spoolscan/screens/new_spool_form_screen.dart';
import 'package:spoolscan/services/spool_creator.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de')],
        locale: const Locale('de'),
        home: child,
      );

  testWidgets('Pflichtfelder validieren', (tester) async {
    NewSpoolFormData? saved;
    await tester.pumpWidget(wrap(NewSpoolFormScreen(
      nfcUid: 'aa',
      knownVendors: const ['Sunlu', 'Prusament'],
      knownMaterials: const ['PLA', 'PETG'],
      onSave: (d) async => saved = d,
      onCancel: () {},
    )));

    await tester.tap(find.text('Speichern & Weiter'));
    await tester.pump();
    expect(saved, isNull);
    expect(find.text('Pflichtfeld'), findsAtLeastNWidgets(1));
  });

  testWidgets('gültige Eingabe ruft onSave', (tester) async {
    NewSpoolFormData? saved;
    await tester.pumpWidget(wrap(NewSpoolFormScreen(
      nfcUid: 'aa',
      knownVendors: const [],
      knownMaterials: const [],
      onSave: (d) async => saved = d,
      onCancel: () {},
    )));

    await tester.enterText(find.byKey(const Key('brand')), 'Sunlu');
    await tester.enterText(find.byKey(const Key('material')), 'PLA');
    await tester.enterText(find.byKey(const Key('color')), 'ff5500');
    await tester.tap(find.text('Speichern & Weiter'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.brand, 'Sunlu');
    expect(saved!.material, 'PLA');
    expect(saved!.colorHex, 'ff5500');
    expect(saved!.nfcUid, 'aa');
  });

  testWidgets('ungültige Hex-Farbe wird abgelehnt', (tester) async {
    await tester.pumpWidget(wrap(NewSpoolFormScreen(
      nfcUid: 'aa',
      knownVendors: const [],
      knownMaterials: const [],
      onSave: (_) async {},
      onCancel: () {},
    )));

    await tester.enterText(find.byKey(const Key('brand')), 'X');
    await tester.enterText(find.byKey(const Key('material')), 'Y');
    await tester.enterText(find.byKey(const Key('color')), 'xyz');
    await tester.tap(find.text('Speichern & Weiter'));
    await tester.pump();

    expect(find.text('Ungültige Hex-Farbe (6 Zeichen)'), findsOneWidget);
  });
}
