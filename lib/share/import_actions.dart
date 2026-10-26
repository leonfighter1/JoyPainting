import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../gallery/painting_archive.dart';
import '../gallery/painting_file.dart';
import '../l10n.dart';
import '../painting_session.dart';

/// Lets the user pick a `.jypaint` file (for example one saved from a chat
/// app) and opens it as a new painting, or a `.zip` of several paintings
/// (from Export) and adds them all.
Future<void> pickAndImport(
    BuildContext context, PaintingSession session, VoidCallback onOpened) async {
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final file = await openFile(acceptedTypeGroups: [
    XTypeGroup(
      label: s.appName,
      extensions: const [PaintingFile.extension, PaintingArchive.extension],
      // Chat apps often save it without a specific type, so accept the
      // generic ones too; the content is checked on import.
      mimeTypes: const [
        PaintingFile.mimeType,
        PaintingArchive.mimeType,
        'application/x-zip-compressed',
        'application/json',
        'application/octet-stream',
      ],
      // The type declared in ios/Runner/Info.plist, plus any data for files
      // that arrive without it.
      uniformTypeIdentifiers: const [
        'com.personal.jingyaopaint.painting',
        'public.zip-archive',
        'public.data',
      ],
      webWildCards: const [
        '.${PaintingFile.extension}',
        '.${PaintingArchive.extension}',
      ],
    ),
  ]);
  if (file == null) return;
  await importBytes(messenger, s, session, await file.readAsBytes(), onOpened);
}

/// Imports [bytes] and tells the user how it went. A zip adds every
/// painting in it and stays where it is; a single painting opens.
Future<void> importBytes(
  ScaffoldMessengerState messenger,
  S s,
  PaintingSession session,
  Uint8List bytes,
  VoidCallback onOpened,
) async {
  if (PaintingArchive.isZip(bytes)) {
    final count = await session.importArchive(bytes);
    messenger.showSnackBar(SnackBar(
        content: Text(count > 0 ? s.importedMany(count) : s.notAPainting)));
    return;
  }
  final ok = await session.importPainting(bytes);
  messenger.showSnackBar(
      SnackBar(content: Text(ok ? s.imported : s.notAPainting)));
  if (ok) onOpened();
}
