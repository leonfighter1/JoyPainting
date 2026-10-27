import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../drawing/drawing_controller.dart';
import '../gallery/painting_archive.dart';
import '../gallery/painting_file.dart';
import '../gallery/painting_store.dart';
import '../image_saver.dart';
import '../l10n.dart';
import '../theme/cute_theme.dart';
import 'painting_export.dart';
import 'print_preview_page.dart';
import 'web_send.dart';

IconData _formatIcon(ExportFormat f) => switch (f) {
      ExportFormat.png => Icons.image_rounded,
      ExportFormat.jpg => Icons.photo_rounded,
      ExportFormat.pdf => Icons.picture_as_pdf_rounded,
      ExportFormat.painting => Icons.brush_rounded,
    };

/// A sheet listing [formats] under [title] (and [hint]); the one tapped,
/// or null if the sheet was closed.
Future<ExportFormat?> pickExportFormat(
  BuildContext context, {
  required String title,
  String? hint,
  List<ExportFormat> formats = ExportFormat.values,
}) {
  final s = S.of(context);
  return showModalBottomSheet<ExportFormat>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final cute = CuteTheme.of(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (hint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Text(hint),
              ),
            for (final f in formats)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: cute.spec.secondary,
                  foregroundColor: cute.spec.onSecondary,
                  child: Icon(_formatIcon(f)),
                ),
                title: Text(s.formatName(f.name)),
                subtitle: Text(s.formatHint(f.name)),
                onTap: () => Navigator.pop(context, f),
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Downloads [doc] as a PNG, JPG or PDF, as the user picks: a download in
/// the browser; in the apps, pictures go to the photo gallery and a PDF to
/// the share sheet (Save to Files…).
Future<void> downloadPainting(BuildContext context, PaintingDoc doc) async {
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final origin = shareOrigin(context);
  final format = await pickExportFormat(
    context,
    title: s.downloadAs,
    hint: kIsWeb ? null : s.downloadHintApps,
    formats: const [ExportFormat.png, ExportFormat.jpg, ExportFormat.pdf],
  );
  if (format == null) return;
  try {
    final file = await exportPainting(doc, format);
    if (kIsWeb) {
      downloadInBrowser(file.bytes, file.name, file.mimeType);
      messenger.showSnackBar(SnackBar(content: Text(s.downloaded(file.name))));
    } else if (format == ExportFormat.pdf) {
      await deliverExport(file, origin);
    } else {
      await saveImage(file.bytes,
          file.name.substring(0, file.name.length - format.extension.length - 1));
      messenger.showSnackBar(SnackBar(content: Text(s.savedToGallery)));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(s.saveFailed(e))));
  }
}

/// Asks which format to send [doc] in, then opens the system share sheet,
/// where the user picks who or which app to send it to. In a browser it
/// goes to an email as an attachment (see [sendFromBrowser]).
Future<void> showSendSheet(BuildContext context, PaintingDoc doc) async {
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final origin = shareOrigin(context);
  final format = await pickExportFormat(
    context,
    title: s.sendAs,
    hint: kIsWeb ? s.sendHintWeb : null,
  );
  if (format == null) return;
  try {
    final file = await exportPainting(doc, format);
    if (kIsWeb) {
      final result = await sendFromBrowser(
        file.bytes,
        name: file.name,
        mimeType: file.mimeType,
        subject: s.mailSubject(doc.meta.name),
        body: s.mailBody(file.name),
      );
      if (result == WebSendResult.downloadedForEmail) {
        messenger.showSnackBar(SnackBar(
          content: Text(s.mailFallback(file.name)),
          duration: const Duration(seconds: 10),
        ));
      }
      return;
    }
    await SharePlus.instance.share(ShareParams(
      files: [XFile.fromData(file.bytes, mimeType: file.mimeType, name: file.name)],
      fileNameOverrides: [file.name],
      title: s.appName,
      sharePositionOrigin: origin,
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(s.sendFailed(e))));
  }
}

/// Exports paintings to keep or move to another device: one painting as
/// its `.jypaint` file, several as one `.zip` of them. Import reads both.
Future<void> exportPaintings(BuildContext context, List<PaintingDoc> docs) async {
  if (docs.isEmpty) return;
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final origin = shareOrigin(context);
  try {
    final file = docs.length == 1
        ? ExportedFile(PaintingFile.encode(docs.single),
            exportName(docs.single, ExportFormat.painting), PaintingFile.mimeType)
        : ExportedFile(PaintingArchive.encode(docs),
            s.archiveName(docs.length, DateTime.now()), PaintingArchive.mimeType);
    await deliverExport(file, origin);
    messenger.showSnackBar(
        SnackBar(content: Text(s.exportedCount(docs.length))));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(s.exportFailed(e))));
  }
}

/// Hands an exported file over: the share sheet in the apps (save to
/// Files, send to a chat…), a download in the browser. Replaced in tests.
@visibleForTesting
Future<void> Function(ExportedFile file, Rect? origin) deliverExport =
    _deliver;

Future<void> _deliver(ExportedFile file, Rect? origin) async {
  if (kIsWeb) {
    downloadInBrowser(file.bytes, file.name, file.mimeType);
    return;
  }
  await SharePlus.instance.share(ShareParams(
    files: [XFile.fromData(file.bytes, mimeType: file.mimeType, name: file.name)],
    fileNameOverrides: [file.name],
    sharePositionOrigin: origin,
  ));
}

/// Where the share sheet points from: the area of the widget at [context],
/// in screen coordinates. On iPad the sheet is a popover and needs one (it
/// fails without); phones ignore it.
Rect? shareOrigin(BuildContext context) {
  final box = context.findRenderObject();
  if (box is! RenderBox || !box.hasSize || box.size.isEmpty) return null;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// Opens the app's print preview for [doc] (a one-page picture), from which
/// the system print screen can be opened, or the page closed.
Future<void> printPainting(BuildContext context, PaintingDoc doc) async {
  final s = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  try {
    final size = paintingSize(doc);
    final png = await DrawingController.renderPng(
        doc.strokes, size, exportRatioFor(size), paper: doc.paper);
    await navigator.push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PrintPreviewPage(
        png: png,
        size: size,
        name: exportName(doc, ExportFormat.pdf),
      ),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(s.printFailed(e))));
  }
}
