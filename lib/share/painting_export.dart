import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../drawing/render/render_image.dart';
import '../gallery/painting_file.dart';
import '../gallery/painting_store.dart';

/// The formats a painting can be sent as.
enum ExportFormat {
  png('png', 'image/png'),
  jpg('jpg', 'image/jpeg'),
  pdf('pdf', 'application/pdf'),
  painting(PaintingFile.extension, PaintingFile.mimeType);

  const ExportFormat(this.extension, this.mimeType);

  final String extension;
  final String mimeType;
}

class ExportedFile {
  const ExportedFile(this.bytes, this.name, this.mimeType);

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

/// Pixels per canvas point in exported images: sharp enough to print.
const exportPixelRatio = 2.0;

/// Exported pictures are at most this many pixels on their longest side, so
/// a big (4×) paper doesn't make a picture too large to save or send.
const maxExportSide = 4096.0;

/// [exportPixelRatio], lowered for big papers to stay within
/// [maxExportSide].
double exportRatioFor(Size size) => math.min(
    exportPixelRatio, maxExportSide / math.max(1, math.max(size.width, size.height)));

/// The painting's paper size (its own, or the screen it was saved on),
/// with a sensible fallback for odd data.
Size paintingSize(PaintingDoc doc) =>
    doc.paperSize ??
    (doc.meta.width > 0 && doc.meta.height > 0
        ? Size(doc.meta.width, doc.meta.height)
        : const Size(800, 1000));

/// The painting's name as the file name (`My painting 1.png`), or one
/// like `JoyPainting_20261024_1530.png` for a painting without a name.
/// Characters that file systems refuse become `_`.
String exportName(PaintingDoc doc, ExportFormat format) {
  final name = PaintingFile.safeName(doc.meta.name, fallback: '');
  if (name.isNotEmpty) return '$name.${format.extension}';
  final d = doc.meta.updatedAt;
  String two(int n) => n.toString().padLeft(2, '0');
  return 'JoyPainting_${d.year}${two(d.month)}${two(d.day)}_'
      '${two(d.hour)}${two(d.minute)}.${format.extension}';
}

/// Whether [doc] has a photo in it (to trace, see `Stroke.photo`).
bool hasPhoto(PaintingDoc doc) => doc.strokes.any((s) => s.photo != null);

/// [doc] without its photos: a picture of only what was drawn.
PaintingDoc withoutPhotos(PaintingDoc doc) => PaintingDoc(
      meta: doc.meta,
      strokes: [
        for (final s in doc.strokes)
          if (s.photo == null) s,
      ],
      paper: doc.paper,
      paperSize: doc.paperSize,
      layers: doc.layers,
    );

/// [doc] as a file in [format]. Pictures and PDFs leave its photos out
/// unless [photos]; a `.jypaint` always keeps everything.
Future<ExportedFile> exportPainting(PaintingDoc doc, ExportFormat format,
    {bool photos = true}) async {
  final size = paintingSize(doc);
  final picture = photos ? doc : withoutPhotos(doc);
  final Uint8List bytes = switch (format) {
    ExportFormat.png => await renderPng(
        picture.strokes, size, exportRatioFor(size),
            paper: doc.paper, layers: doc.layers),
    ExportFormat.jpg => await _jpg(picture, size),
    ExportFormat.pdf => await buildPdf(
        await renderPng(
            picture.strokes, size, exportRatioFor(size),
            paper: doc.paper, layers: doc.layers),
        size,
        PdfPageFormat.a4),
    ExportFormat.painting => PaintingFile.encode(doc),
  };
  return ExportedFile(bytes, exportName(doc, format), format.mimeType);
}

Future<Uint8List> _jpg(PaintingDoc doc, Size size) async {
  final raw = await renderRgba(
      doc.strokes, size, exportRatioFor(size),
            paper: doc.paper, layers: doc.layers);
  // JPEG encoding is pure Dart and can take a moment on big paintings, so
  // do it off the UI thread where the platform allows.
  return compute(_encodeJpg, raw);
}

Uint8List _encodeJpg(({Uint8List rgba, int width, int height}) raw) {
  final image = img.Image.fromBytes(
    width: raw.width,
    height: raw.height,
    bytes: raw.rgba.buffer,
    numChannels: 4,
  );
  return img.encodeJpg(image, quality: 92);
}

/// A one-page PDF with the picture centered and as large as fits, turned
/// sideways for wide paintings.
Future<Uint8List> buildPdf(
    Uint8List png, Size imageSize, PdfPageFormat format) async {
  final pageFormat =
      imageSize.width > imageSize.height ? format.landscape : format.portrait;
  final doc = pw.Document(title: 'JoyPainting', creator: 'JoyPainting');
  doc.addPage(pw.Page(
    pageFormat: pageFormat,
    margin: const pw.EdgeInsets.all(24),
    build: (_) => pw.Center(
      child: pw.Image(pw.MemoryImage(png), fit: pw.BoxFit.contain),
    ),
  ));
  return doc.save();
}
