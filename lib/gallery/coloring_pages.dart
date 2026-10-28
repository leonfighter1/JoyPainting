import 'package:flutter/services.dart';

import '../drawing/layers.dart';
import '../l10n.dart';
import 'painting_file.dart';
import 'painting_store.dart';

/// The coloring pages that come with the app: line drawings whose lines
/// are on a locked top layer, so a kid colors under them (by hand or with
/// the paint bucket) and the eraser leaves them alone. Made by
/// tool/coloring/make_coloring_test.dart.
enum ColoringPage {
  cat,
  house,
  flower,
  fish,
  rocket,
  butterfly,
  car,
  tree;

  /// The layer a page's lines are on.
  static const linesLayer =
      PaintingLayer(id: 'lines', name: '线稿', locked: true);

  String get asset => 'assets/coloring/$name.jypaint';

  /// A small picture of the page, for choosing one.
  String get preview => 'assets/coloring/$name.png';

  /// The page as a painting, named in the language of [s].
  Future<PaintingDoc> load(S s, {AssetBundle? bundle}) async {
    final data = await (bundle ?? rootBundle).load(asset);
    final doc = PaintingFile.decode(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    final now = DateTime.now();
    return PaintingDoc(
      meta: PaintingMeta(
        id: doc.meta.id,
        name: s.coloringPainting(s.coloringName(this)),
        createdAt: now,
        updatedAt: now,
        width: doc.meta.width,
        height: doc.meta.height,
        strokeCount: doc.strokes.length,
      ),
      strokes: doc.strokes,
      paper: doc.paper,
      paperSize: doc.paperSize,
      layers: doc.layers,
    );
  }
}
