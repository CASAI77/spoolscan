import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/l10n/app_localizations.dart';
import 'package:spoolscan/models/spool.dart';
import 'package:spoolscan/models/tag_format.dart';
import 'package:spoolscan/screens/new_spool_confirm_screen.dart';
import 'package:spoolscan/services/tag_reader.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('de')],
        locale: const Locale('de'),
        home: child,
      );

  testWidgets('zeigt Tag-Daten read-only und beide Buttons', (tester) async {
    final tag = TagReadResult(
      nfcUid: '04a3',
      format: TagFormat.openPrintTag,
      spool: Spool(
        spoolId: '',
        brand: 'Prusament',
        type: 'PETG',
        colorHex: '111111',
        weightTotal: 1000,
        minTemp: 240,
      ),
    );

    await tester.pumpWidget(wrap(NewSpoolConfirmScreen(
      tag: tag,
      onConfirm: () async {},
      onCancel: () {},
    )));

    expect(find.text('Prusament'), findsOneWidget);
    expect(find.text('PETG'), findsOneWidget);
    expect(find.text('Anlegen & Weiter'), findsOneWidget);
    expect(find.text('Abbrechen'), findsOneWidget);
  });

  testWidgets('Cancel-Button ruft onCancel auf', (tester) async {
    var cancelled = false;
    final tag = TagReadResult(
      nfcUid: '04a3',
      format: TagFormat.openPrintTag,
      spool: Spool(spoolId: '', brand: 'X', type: 'Y', colorHex: '000000'),
    );

    await tester.pumpWidget(wrap(NewSpoolConfirmScreen(
      tag: tag,
      onConfirm: () async {},
      onCancel: () => cancelled = true,
    )));
    await tester.tap(find.text('Abbrechen'));
    await tester.pump();

    expect(cancelled, isTrue);
  });
}
