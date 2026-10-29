// The SVG export in a browser, where paths and text are measured by the
// web engine. Browser only: flutter test --platform chrome test/svg_web_test.dart
@TestOn('browser')
library;

import 'dart:convert';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/share/svg/svg_canvas.dart';
import 'package:jingyao_paint/share/svg/svg_export.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:xml/xml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shapes, textures, the eraser and letters export in a browser',
      () async {
    final strokes = [
      Stroke.shape(
        shape: ShapeKind.star,
        from: const Offset(10, 10),
        to: const Offset(110, 110),
        brush: BrushType.pen,
        color: const Color(0xFFE0474C),
        size: 4,
        fill: true,
        gradient: GradientStyle.rounded.forColor(const Color(0xFFE0474C)),
        isComplete: true,
      ),
      for (final (brush, texture, y) in [
        (BrushType.marker, StrokeTexture.canvas, 140.0),
        (BrushType.eraser, StrokeTexture.none, 140.0),
        (BrushType.soft, StrokeTexture.none, 170.0),
      ])
        Stroke(
          brush: brush,
          color: const Color(0xFF233A73),
          size: 10,
          usesRealPressure: false,
          texture: texture,
          blur: brush == BrushType.soft ? 6 : 0,
          isComplete: true,
          points: [
            for (var x = 10.0; x < 200; x += 8) PointVector(x, y, 0.5),
          ],
        ),
      Stroke.text(
        anchor: const Offset(10, 200),
        content: const TextContent(text: '快乐 Joy', fontFamily: 'ZCOOLKuaiLe'),
        color: const Color(0xFF233A73),
      ),
    ];
    final bytes = await renderSvg(strokes, const Size(220, 260),
        paper: const Color(0xFFFFFFFF));
    final svg = XmlDocument.parse(utf8.decode(bytes));
    Iterable<XmlElement> all(String name) => svg.descendants
        .whereType<XmlElement>()
        .where((e) => e.localName == name);
    expect(all('radialGradient'), isNotEmpty);
    expect(all('pattern'), hasLength(1));
    expect(all('mask'), isNotEmpty);
    expect(all('feGaussianBlur'), isNotEmpty);
    final star = all('path').firstWhere((p) =>
        (p.getAttribute('fill') ?? '').startsWith('url(#g'));
    expect(star.getAttribute('d'), allOf(startsWith('M'), endsWith('Z')));
    final words =
        all('path').where((p) => p.getAttribute('aria-label') == '快乐 Joy');
    expect(words.single.getAttribute('d'), isNotEmpty);
    expect(svgPathData(Path()..addRect(const Rect.fromLTWH(0, 0, 10, 10))),
        'M0 0L10 0L10 10L0 10L0 0Z');
  });
}
