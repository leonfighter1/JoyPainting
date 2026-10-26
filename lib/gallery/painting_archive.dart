import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import 'painting_file.dart';
import 'painting_store.dart';

/// Several paintings in one `.zip`, each inside as `<name>.jypaint`: what
/// exporting more than one painting makes, and what importing reads back.
abstract final class PaintingArchive {
  static const extension = 'zip';
  static const mimeType = 'application/zip';

  /// Zip files start with "PK\x03\x04" (or "PK\x05\x06" when empty).
  static bool isZip(Uint8List bytes) =>
      bytes.length >= 4 &&
      bytes[0] == 0x50 &&
      bytes[1] == 0x4B &&
      ((bytes[2] == 3 && bytes[3] == 4) || (bytes[2] == 5 && bytes[3] == 6));

  static Uint8List encode(List<PaintingDoc> docs) {
    final archive = Archive();
    final used = <String>{};
    for (final doc in docs) {
      final base = PaintingFile.safeName(doc.meta.name, fallback: 'painting');
      var name = base;
      for (var n = 2; used.contains(name.toLowerCase()); n++) {
        name = '$base ($n)';
      }
      used.add(name.toLowerCase());
      archive.addFile(ArchiveFile.bytes(
          '$name.${PaintingFile.extension}', PaintingFile.encode(doc)));
    }
    return ZipEncoder().encodeBytes(archive);
  }

  /// The paintings inside, in the archive's order. Anything else in it
  /// (other files, damaged paintings) is skipped. Throws [FormatException]
  /// if [bytes] isn't a zip.
  static List<PaintingDoc> decode(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw FormatException('Not a zip file: $e');
    }
    return [
      for (final file in archive.files)
        if (file.isFile &&
            file.name.toLowerCase().endsWith('.${PaintingFile.extension}'))
          ?_tryDecode(file.content),
    ];
  }

  static PaintingDoc? _tryDecode(Uint8List bytes) {
    try {
      return PaintingFile.decode(bytes);
    } on FormatException catch (e) {
      debugPrint('Skipped a file in the archive: $e');
      return null;
    }
  }
}
