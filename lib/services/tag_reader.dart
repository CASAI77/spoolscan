import 'dart:typed_data';
import '../models/openprinttag.dart';
import '../models/spool.dart';
import '../models/tag_format.dart';

class TagReadResult {
  final String nfcUid;
  final TagFormat format;
  final Spool? spool;

  TagReadResult({required this.nfcUid, required this.format, this.spool});
}

class TagReader {
  /// Wandelt UID-Bytes in lowercase-Hex ohne Trennzeichen.
  static String uidFromBytes(Uint8List bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Format-Erkennungs-Kaskade: OpenPrintTag → OpenSpool → SpoolCompanion → unknown.
  static TagReadResult parse({
    required String nfcUid,
    required String textPayload,
  }) {
    if (textPayload.trim().isEmpty) {
      return TagReadResult(nfcUid: nfcUid, format: TagFormat.unknown);
    }

    // 1. OpenPrintTag (JSON mit standard:openprinttag)
    final opt = OpenPrintTagParser.parse(textPayload);
    if (opt != null) {
      return TagReadResult(nfcUid: nfcUid, format: TagFormat.openPrintTag, spool: opt);
    }

    // 2. OpenSpool oder SpoolCompanion → bestehender Spool.fromText
    try {
      final spool = Spool.fromText(textPayload);
      return TagReadResult(
        nfcUid: nfcUid,
        format: spool.tagFormat ?? TagFormat.unknown,
        spool: spool,
      );
    } on FormatException {
      return TagReadResult(nfcUid: nfcUid, format: TagFormat.unknown);
    }
  }
}
