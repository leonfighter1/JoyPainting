// Makes the coloring pages (lib/gallery/coloring_pages.dart) as `.jypaint`
// files with small previews in assets/coloring/:
//
//   flutter test tool/coloring/make_coloring_test.dart
//
// Each page's lines are on a locked top layer, so coloring (by hand or
// with the paint bucket) goes under them and the eraser leaves them
// alone. Big previews for checking go to local_art/out/coloring/ (not in
// git).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/coloring_pages.dart';
import 'package:jingyao_paint/gallery/painting_file.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';

import '../samples/artist.dart';
import 'coloring_art.dart';

void main() {
  test('make the coloring pages', () async {
    final out = Directory('assets/coloring')..createSync(recursive: true);
    final check = Directory('local_art/out/coloring')
      ..createSync(recursive: true);
    for (final page in ColoringPage.values) {
      final a = Artist();
      drawPage(page.name, a);
      final strokes = [
        for (final s in a.strokes) s.onLayer(ColoringPage.linesLayer.id),
      ];
      final when = DateTime(2026, 10, 28);
      final doc = PaintingDoc(
        meta: PaintingMeta(
          id: page.name,
          name: page.name,
          createdAt: when,
          updatedAt: when,
          width: pageSize.width,
          height: pageSize.height,
          strokeCount: strokes.length,
        ),
        strokes: strokes,
        paperSize: pageSize,
        layers: const [PaintingLayer.base, ColoringPage.linesLayer],
      );
      File('${out.path}/${page.name}.jypaint')
          .writeAsBytesSync(PaintingFile.encode(doc));
      File('${out.path}/${page.name}.png').writeAsBytesSync(await renderPng(
          strokes, pageSize, 0.25, layers: doc.layers));
      File('${check.path}/${page.name}.png').writeAsBytesSync(
          await renderPng(strokes, pageSize, 1, layers: doc.layers));
    }
  });
}
