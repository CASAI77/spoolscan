import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spoolscan/models/spool.dart';
import 'package:spoolscan/models/tag_format.dart';
import 'package:spoolscan/services/spool_resolver.dart';
import 'package:spoolscan/services/spoolman_service.dart';
import 'package:spoolscan/services/tag_reader.dart';

@GenerateMocks([SpoolmanService])
import 'spool_resolver_test.mocks.dart';

void main() {
  const baseUrl = 'h:7912';

  group('SpoolResolver', () {
    late MockSpoolmanService spoolman;
    late SpoolResolver resolver;

    setUp(() {
      spoolman = MockSpoolmanService();
      resolver = SpoolResolver(spoolman: spoolman, baseUrl: baseUrl);
    });

    test('Stufe 1: Tag mit Spoolman-ID → fetchSpool wird aufgerufen', () async {
      final tag = TagReadResult(
        nfcUid: 'aa',
        format: TagFormat.spoolCompanion,
        spool: Spool(spoolId: '3', tagFormat: TagFormat.spoolCompanion),
      );
      when(spoolman.fetchSpool(baseUrl, '3')).thenAnswer(
          (_) async => Spool(spoolId: '3', brand: 'Sunlu', nfcUid: 'aa'));

      final result = await resolver.resolve(tag);

      expect(result.stage, ResolveStage.foundById);
      expect(result.spool?.brand, 'Sunlu');
      verifyNever(spoolman.listSpools(any));
    });

    test('Stufe 1 Match ohne UID → Self-Healing PATCH', () async {
      final tag = TagReadResult(
        nfcUid: 'newuid',
        format: TagFormat.spoolCompanion,
        spool: Spool(spoolId: '3', tagFormat: TagFormat.spoolCompanion),
      );
      when(spoolman.fetchSpool(baseUrl, '3')).thenAnswer(
          (_) async => Spool(spoolId: '3', brand: 'Sunlu')); // nfcUid: null
      when(spoolman.patchSpoolExtra(any, any, any)).thenAnswer((_) async {});

      await resolver.resolve(tag);

      verify(spoolman.patchSpoolExtra(baseUrl, '3', {'nfc_uid': 'newuid'}))
          .called(1);
    });

    test('Stufe 1 Match mit gleicher UID → kein Self-Healing', () async {
      final tag = TagReadResult(
        nfcUid: 'aa',
        format: TagFormat.spoolCompanion,
        spool: Spool(spoolId: '3', tagFormat: TagFormat.spoolCompanion),
      );
      when(spoolman.fetchSpool(baseUrl, '3')).thenAnswer(
          (_) async => Spool(spoolId: '3', nfcUid: 'aa'));

      await resolver.resolve(tag);

      verifyNever(spoolman.patchSpoolExtra(any, any, any));
    });

    test('Stufe 2: Tag ohne Spoolman-ID, UID matched in listSpools', () async {
      final tag = TagReadResult(
        nfcUid: 'xyz',
        format: TagFormat.openPrintTag,
        spool: Spool(spoolId: '', tagFormat: TagFormat.openPrintTag),
      );
      when(spoolman.listSpools(baseUrl)).thenAnswer((_) async => [
            Spool(spoolId: '5', nfcUid: 'other'),
            Spool(spoolId: '8', nfcUid: 'xyz', brand: 'Prusament'),
          ]);

      final result = await resolver.resolve(tag);

      expect(result.stage, ResolveStage.foundByUid);
      expect(result.spool?.spoolId, '8');
      expect(result.spool?.brand, 'Prusament');
    });

    test('Stufe 3: kein Match überall → notFound', () async {
      final tag = TagReadResult(
        nfcUid: 'xyz',
        format: TagFormat.unknown,
        spool: null,
      );
      when(spoolman.listSpools(baseUrl)).thenAnswer((_) async => []);

      final result = await resolver.resolve(tag);

      expect(result.stage, ResolveStage.notFound);
      expect(result.spool, isNull);
    });

    test('Stufe 1 wirft 404 → fällt auf Stufe 2 zurück', () async {
      final tag = TagReadResult(
        nfcUid: 'xyz',
        format: TagFormat.openSpool,
        spool: Spool(spoolId: '99', tagFormat: TagFormat.openSpool),
      );
      when(spoolman.fetchSpool(baseUrl, '99'))
          .thenThrow(SpoolmanException('HTTP 404'));
      when(spoolman.listSpools(baseUrl))
          .thenAnswer((_) async => [Spool(spoolId: '7', nfcUid: 'xyz')]);

      final result = await resolver.resolve(tag);

      expect(result.stage, ResolveStage.foundByUid);
      expect(result.spool?.spoolId, '7');
    });

    test('Cache: zweiter resolve innerhalb 30s lädt nicht neu', () async {
      when(spoolman.listSpools(baseUrl))
          .thenAnswer((_) async => [Spool(spoolId: '5', nfcUid: 'aa')]);
      final tag = TagReadResult(nfcUid: 'aa', format: TagFormat.unknown);

      await resolver.resolve(tag);
      await resolver.resolve(tag);

      verify(spoolman.listSpools(baseUrl)).called(1);
    });
  });
}
