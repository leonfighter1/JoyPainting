import 'package:flutter/services.dart';

import '../drawing/layers.dart';
import '../l10n.dart';
import '../skill_level.dart';
import 'painting_file.dart';
import 'painting_store.dart';

/// The coloring pages that come with the app: line drawings whose lines
/// are on a locked top layer, so a kid colors under them (by hand or with
/// the paint bucket) and the eraser leaves them alone. Each level has its
/// own pages, drawn for an age: beginner 5–8, intermediate about 12,
/// advanced about 18 (more and smaller areas, but none too fiddly). Made
/// by tool/coloring/make_coloring_test.dart.
enum ColoringPage {
  cat(SkillLevel.beginner),
  house(SkillLevel.beginner),
  flower(SkillLevel.beginner),
  fish(SkillLevel.beginner),
  rocket(SkillLevel.beginner),
  butterfly(SkillLevel.beginner),
  car(SkillLevel.beginner),
  tree(SkillLevel.beginner),
  lighthouse(SkillLevel.intermediate),
  castle(SkillLevel.intermediate),
  underwater(SkillLevel.intermediate),
  balloons(SkillLevel.intermediate),
  owl(SkillLevel.intermediate),
  panda(SkillLevel.intermediate),
  mandala(SkillLevel.advanced),
  koi(SkillLevel.advanced),
  pavilion(SkillLevel.advanced),
  peacock(SkillLevel.advanced),
  teaset(SkillLevel.advanced),
  street(SkillLevel.advanced);

  const ColoringPage(this.level);

  /// Who the page is drawn for.
  final SkillLevel level;

  /// The pages for [level], in book order.
  static List<ColoringPage> of(SkillLevel level) =>
      [for (final page in values) if (page.level == level) page];

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
