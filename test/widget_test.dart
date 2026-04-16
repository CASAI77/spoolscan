import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spoolscan/main.dart';

void main() {
  testWidgets('SpoolScanApp startet ohne Fehler', (WidgetTester tester) async {
    await tester.pumpWidget(const SpoolScanApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
