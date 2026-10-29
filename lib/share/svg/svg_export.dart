import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

import '../../app_theme.dart';
import '../../drawing/render/paint_strokes.dart';
import '../../drawing/stroke.dart';
import 'font_outlines.dart';
import 'svg_canvas.dart';

/// [strokes] as an SVG picture of [size]: every line, shape and fill as a
/// shape that stays sharp at any size, text as the outlines of its letters,
/// and each shown layer as a named group. [paper] fills the background
/// unless [background] is off (a see-through picture, for logos); the
/// blender still mixes with it.
Future<Uint8List> renderSvg(List<Stroke> strokes, Size size,
    {required Color paper,
    bool background = true,
    List<PaintingLayer>? layers,
    String? title}) async {
  // Pictures must be decoded before they can be painted.
  await Photos.ready([for (final s in strokes) ?s.photo]);
  final fonts = <String, FontOutlines>{};
  for (final family in {
    for (final s in strokes)
      ?s.text?.fontFamily,
  }) {
    if (await _outlines(family) case final outlines?) fonts[family] = outlines;
  }
  final canvas = SvgCanvas(size, fonts: fonts);
  if (background) canvas.paper(paper);
  // As paintStrokes does: each shown layer on its own sheet.
  final page = Offset.zero & size;
  final all = layers ?? const [PaintingLayer.base];
  if (all.length == 1 && all.single.visible && all.single.opacity == 1) {
    canvas
      ..nameNextLayer(_layerName(all.single, 0))
      ..saveLayer(page, Paint());
    paintStrokeRange(canvas, size, strokes, 0, strokes.length, paper: paper);
    canvas.restore();
  } else {
    for (final (i, layer) in all.indexed) {
      if (!layer.visible || layer.opacity <= 0) continue;
      final own = [
        for (final s in strokes)
          if (s.layerId == layer.id) s,
      ];
      if (own.isEmpty) continue;
      canvas
        ..nameNextLayer(_layerName(layer, i))
        ..saveLayer(page, Paint()..color = Color.fromRGBO(0, 0, 0, layer.opacity));
      paintStrokeRange(canvas, size, own, 0, own.length, paper: paper);
      canvas.restore();
    }
  }
  return utf8.encode(await canvas.finish(title: title));
}

String _layerName(PaintingLayer layer, int index) =>
    layer.name.isNotEmpty ? layer.name : 'Layer ${index + 1}';

final _fontFiles = <String, Future<FontOutlines?>>{};

/// The letter shapes of the bundled font [family], read once. A font file
/// that can't be read, or doesn't arrive within 10 seconds, leaves its
/// letters as text rather than holding the export up (and is tried again
/// next time).
Future<FontOutlines?> _outlines(String family) async {
  final asset = [
    for (final f in kFonts)
      if (f.family == family) f.fileAsset,
  ].firstOrNull;
  if (asset == null) return null;
  final read = _fontFiles[family] ??=
      rootBundle.load(asset).then(FontOutlines.parse);
  try {
    return await read.timeout(const Duration(seconds: 10));
  } catch (e) {
    _fontFiles.remove(family);
    debugPrint('Font $family not read for SVG: $e');
    return null;
  }
}
