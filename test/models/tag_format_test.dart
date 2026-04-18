import 'package:flutter_test/flutter_test.dart';
import 'package:spoolscan/models/tag_format.dart';

void main() {
  group('TagFormat', () {
    test('hat alle erwarteten Werte', () {
      expect(TagFormat.values, [
        TagFormat.openPrintTag,
        TagFormat.openSpool,
        TagFormat.spoolCompanion,
        TagFormat.unknown,
      ]);
    });
  });
}
