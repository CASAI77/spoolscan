import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:spoolscan/models/spool.dart';
import 'package:spoolscan/models/tag_format.dart';
import 'package:spoolscan/services/spool_creator.dart';
import 'package:spoolscan/services/spoolman_service.dart';
import 'package:spoolscan/services/tag_reader.dart';

@GenerateMocks([SpoolmanService])
import 'spool_creator_test.mocks.dart';

void main() {
  const baseUrl = 'h:7912';

  group('SpoolCreator', () {
    late MockSpoolmanService spoolman;
    late SpoolCreator creator;

    setUp(() {
      spoolman = MockSpoolmanService();
      creator = SpoolCreator(spoolman: spoolman, baseUrl: baseUrl);
    });

    test('canAutoCreate liefert true wenn Marke + Material + Farbe vorhanden', () {
      final tag = TagReadResult(
        nfcUid: 'aa',
        format: TagFormat.openPrintTag,
        spool: Spool(
          spoolId: '',
          brand: 'Prusament',
          type: 'PETG',
          colorHex: '111111',
        ),
      );
      expect(creator.canAutoCreate(tag), isTrue);
    });

    test('canAutoCreate liefert false bei fehlendem Material', () {
      final tag = TagReadResult(
        nfcUid: 'aa',
        format: TagFormat.spoolCompanion,
        spool: Spool(spoolId: '5', brand: 'Sunlu'),
      );
      expect(creator.canAutoCreate(tag), isFalse);
    });

    test('createAuto: Vendor + Filament neu, Spool wird angelegt', () async {
      final tag = TagReadResult(
        nfcUid: '04a3',
        format: TagFormat.openPrintTag,
        spool: Spool(
          spoolId: '',
          brand: 'Prusament',
          type: 'PETG Schwarz',
          colorHex: '111111',
          minTemp: 240,
          weightTotal: 1000,
        ),
      );
      when(spoolman.listVendors(baseUrl)).thenAnswer((_) async => []);
      when(spoolman.createVendor(baseUrl, name: 'Prusament'))
          .thenAnswer((_) async => 10);
      when(spoolman.listFilaments(baseUrl, vendorId: 10))
          .thenAnswer((_) async => []);
      when(spoolman.createFilament(
        baseUrl,
        vendorId: 10,
        name: 'PETG Schwarz',
        material: 'PETG Schwarz',
        colorHex: '111111',
        extruderTemp: 240,
      )).thenAnswer((_) async => 20);
      when(spoolman.createSpool(
        baseUrl,
        filamentId: 20,
        initialWeight: 1000,
        extra: {'nfc_uid': '04a3'},
      )).thenAnswer((_) async => Spool(spoolId: '99', brand: 'Prusament'));

      final spool = await creator.createAuto(tag);

      expect(spool.spoolId, '99');
      verify(spoolman.createVendor(baseUrl, name: 'Prusament')).called(1);
      verify(spoolman.createFilament(baseUrl,
              vendorId: 10,
              name: 'PETG Schwarz',
              material: 'PETG Schwarz',
              colorHex: '111111',
              extruderTemp: 240))
          .called(1);
    });

    test('createAuto: Vendor existiert (case-insensitive)', () async {
      final tag = TagReadResult(
        nfcUid: '04',
        format: TagFormat.openPrintTag,
        spool: Spool(
          spoolId: '',
          brand: 'sunlu',
          type: 'PLA',
          colorHex: 'ff0000',
        ),
      );
      when(spoolman.listVendors(baseUrl)).thenAnswer(
          (_) async => [SpoolmanVendor(id: 7, name: 'Sunlu')]);
      when(spoolman.listFilaments(baseUrl, vendorId: 7))
          .thenAnswer((_) async => []);
      when(spoolman.createFilament(baseUrl,
              vendorId: 7,
              name: anyNamed('name'),
              material: anyNamed('material'),
              colorHex: anyNamed('colorHex'),
              extruderTemp: anyNamed('extruderTemp')))
          .thenAnswer((_) async => 8);
      when(spoolman.createSpool(baseUrl,
              filamentId: 8,
              initialWeight: anyNamed('initialWeight'),
              extra: anyNamed('extra')))
          .thenAnswer((_) async => Spool(spoolId: '1'));

      await creator.createAuto(tag);

      verifyNever(spoolman.createVendor(any, name: anyNamed('name')));
    });

    test('createAuto: Filament existiert → kein Filament-POST', () async {
      final tag = TagReadResult(
        nfcUid: '04',
        format: TagFormat.openPrintTag,
        spool: Spool(
          spoolId: '',
          brand: 'Sunlu',
          type: 'PLA',
          colorHex: 'ff0000',
        ),
      );
      when(spoolman.listVendors(baseUrl)).thenAnswer(
          (_) async => [SpoolmanVendor(id: 7, name: 'Sunlu')]);
      when(spoolman.listFilaments(baseUrl, vendorId: 7)).thenAnswer((_) async => [
            SpoolmanFilament(
                id: 99,
                name: 'PLA',
                material: 'PLA',
                colorHex: 'ff0000',
                vendorId: 7,
                vendorName: 'Sunlu'),
          ]);
      when(spoolman.createSpool(baseUrl,
              filamentId: 99,
              initialWeight: anyNamed('initialWeight'),
              extra: anyNamed('extra')))
          .thenAnswer((_) async => Spool(spoolId: '1'));

      await creator.createAuto(tag);

      verifyNever(spoolman.createFilament(any,
          vendorId: anyNamed('vendorId'),
          name: anyNamed('name'),
          material: anyNamed('material'),
          colorHex: anyNamed('colorHex'),
          extruderTemp: anyNamed('extruderTemp')));
    });

    test('createManual: nimmt Form-Daten und ruft die gleiche Pipeline auf', () async {
      final form = NewSpoolFormData(
        brand: 'Custom',
        material: 'PETG',
        colorHex: '00ff00',
        weightTotal: 750,
        extruderTemp: 240,
        nfcUid: 'manual-uid',
      );
      when(spoolman.listVendors(baseUrl)).thenAnswer((_) async => []);
      when(spoolman.createVendor(baseUrl, name: 'Custom'))
          .thenAnswer((_) async => 1);
      when(spoolman.listFilaments(baseUrl, vendorId: 1))
          .thenAnswer((_) async => []);
      when(spoolman.createFilament(baseUrl,
              vendorId: 1,
              name: 'PETG',
              material: 'PETG',
              colorHex: '00ff00',
              extruderTemp: 240))
          .thenAnswer((_) async => 2);
      when(spoolman.createSpool(baseUrl,
              filamentId: 2,
              initialWeight: 750,
              extra: {'nfc_uid': 'manual-uid'}))
          .thenAnswer((_) async => Spool(spoolId: '7'));

      final spool = await creator.createManual(form);
      expect(spool.spoolId, '7');
    });

    test('defaultTempForMaterial', () {
      expect(SpoolCreator.defaultTempForMaterial('PLA'), 210);
      expect(SpoolCreator.defaultTempForMaterial('PETG'), 240);
      expect(SpoolCreator.defaultTempForMaterial('ABS'), 250);
      expect(SpoolCreator.defaultTempForMaterial('TPU'), 220);
      expect(SpoolCreator.defaultTempForMaterial('Unbekannt'), isNull);
    });
  });
}
