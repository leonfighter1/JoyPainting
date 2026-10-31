import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/share/painting_export.dart';
import 'package:jingyao_paint/share/share_actions.dart';
import 'package:jingyao_paint/share/svg/font_outlines.dart';
import 'package:jingyao_paint/share/svg/svg_canvas.dart';
import 'package:jingyao_paint/widgets/elastic_switch.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:xml/xml.dart';

import 'photo_test.dart' show redPhoto;
import 'widget_test.dart' show pumpApp, tapMenu;

const _navy = Color(0xFF233A73);
const _red = Color(0xFFE0474C);

List<PointVector> _wave(double y, {double from = 20, double to = 300}) => [
      for (var x = from; x <= to; x += 6)
        PointVector(x, y + 10 * math.sin(x / 20), 0.5),
    ];

Stroke _line(BrushType brush, List<PointVector> pts,
        {Color color = _navy,
        double size = 8,
        StrokeTexture texture = StrokeTexture.none,
        StrokeBlend blend = StrokeBlend.normal,
        double? mirrorX,
        StrokeTransform? transform,
        double blur = 0,
        String? layer}) =>
    Stroke(
      brush: brush,
      color: color,
      size: size,
      usesRealPressure: false,
      seed: 3,
      texture: texture,
      blend: blend,
      mirrorX: mirrorX,
      transform: transform,
      blur: blur,
      layer: layer,
      isComplete: true,
      points: pts,
    );

/// A painting with every kind of stroke the SVG export has to handle.
PaintingDoc _everything() {
  final strokes = [
    _line(BrushType.pen, _wave(30)),
    _line(BrushType.spray, _wave(60), color: _red),
    _line(BrushType.rainbow, _wave(90)),
    _line(BrushType.stamp, _wave(120)),
    Stroke.shape(
      shape: ShapeKind.star,
      from: const Offset(320, 20),
      to: const Offset(400, 100),
      brush: BrushType.pen,
      color: _red,
      size: 4,
      fill: true,
      gradient: GradientStyle.lighter.forColor(_red),
      isComplete: true,
    ),
    Stroke.shape(
      shape: ShapeKind.ellipse,
      from: const Offset(420, 20),
      to: const Offset(500, 100),
      brush: BrushType.pen,
      color: _navy,
      size: 4,
      fill: true,
      gradient: GradientStyle.glow.forColor(_navy),
      isComplete: true,
    ),
    _line(BrushType.marker, _wave(160), size: 16, texture: StrokeTexture.canvas),
    _line(BrushType.pen, _wave(190), size: 3, texture: StrokeTexture.paper),
    _line(BrushType.marker, _wave(220), size: 12, blend: StrokeBlend.multiply),
    _line(BrushType.soft, _wave(250), size: 12, blur: 8),
    // Two eraser strokes in a row.
    _line(BrushType.eraser, _wave(165, to: 120)),
    _line(BrushType.eraser, _wave(225, to: 120)),
    _line(BrushType.smudge, _wave(200, from: 150, to: 250)),
    _line(BrushType.pen, _wave(280), color: _red, mirrorX: 320),
    _line(BrushType.stamp, _wave(310, to: 100),
        transform: StrokeTransform.around(const Offset(60, 310), angle: 0.4)),
    Stroke(
      brush: BrushType.bucket,
      color: _red,
      size: 1,
      usesRealPressure: false,
      fill: true,
      isComplete: true,
      area: const [
        [Offset(320, 150), Offset(480, 150), Offset(480, 250), Offset(320, 250)],
        [Offset(360, 180), Offset(440, 180), Offset(400, 230)],
      ],
      points: [PointVector(320, 150, 0.5), PointVector(480, 250, 0.5)],
    ),
    Stroke.text(
      anchor: const Offset(30, 340),
      content: const TextContent(
          text: '快乐 Joy',
          fontFamily: 'ZCOOLKuaiLe',
          bold: true,
          underline: true,
          bubble: true),
      color: _navy,
    ),
    Stroke.text(
      anchor: const Offset(300, 340),
      content: const TextContent(text: 'Hi'),
      color: _red,
    ),
    Stroke.photo(
        topLeft: const Offset(320, 280), photo: redPhoto(), layer: 'top'),
    _line(BrushType.pen, _wave(380), layer: 'hidden'),
  ];
  final now = DateTime(2026, 10, 30, 9);
  return PaintingDoc(
    meta: PaintingMeta(
      id: 'svg',
      name: 'Logo <draft>',
      createdAt: now,
      updatedAt: now,
      width: 520,
      height: 420,
      strokeCount: strokes.length,
    ),
    strokes: strokes,
    paper: const Color(0xFFFFF8E1),
    paperSize: const Size(520, 420),
    layers: const [
      PaintingLayer.base,
      PaintingLayer(id: 'top', name: '照片', opacity: 0.8),
      PaintingLayer(id: 'hidden', visible: false),
    ],
  );
}

Future<XmlDocument> _svgOf(PaintingDoc doc, {bool paper = true}) async {
  final file = await exportPainting(doc, ExportFormat.svg, paper: paper);
  return XmlDocument.parse(utf8.decode(file.bytes));
}

Iterable<XmlElement> _all(XmlDocument doc, String name) =>
    doc.descendants.whereType<XmlElement>().where((e) => e.localName == name);

/// Every point in path data [d].
List<Offset> _points(String d) {
  final n = [
    for (final m in RegExp(r'-?\d+(\.\d+)?').allMatches(d))
      double.parse(m.group(0)!),
  ];
  return [for (var i = 0; i + 1 < n.length; i += 2) Offset(n[i], n[i + 1])];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SVG export', () {
    test('is an SVG picture of the paper, with each shown layer named',
        () async {
      final doc = _everything();
      final file = await exportPainting(doc, ExportFormat.svg);
      expect(file.name, 'Logo _draft_.svg');
      expect(file.mimeType, 'image/svg+xml');
      final svg = XmlDocument.parse(utf8.decode(file.bytes));
      final root = svg.rootElement;
      expect(root.localName, 'svg');
      expect(root.getAttribute('viewBox'), '0 0 520 420');
      expect(root.getAttribute('width'), '520');
      expect(_all(svg, 'title').single.innerText, 'Logo <draft>');
      final paper = _all(svg, 'rect').firstWhere((r) => r.getAttribute('id') == 'paper');
      expect(paper.getAttribute('fill'), '#fff8e1');
      final layers = [
        for (final g in _all(svg, 'g'))
          ?g.getAttribute('inkscape:label'),
      ];
      expect(layers, ['Layer 1', '照片'], reason: 'the hidden layer is left out');
    });

    test('every reference points at something defined, once', () async {
      final svg = await _svgOf(_everything());
      final ids = [
        for (final e in svg.descendants.whereType<XmlElement>())
          ?e.getAttribute('id'),
      ];
      expect(ids.toSet(), hasLength(ids.length));
      final refs = <String>[];
      for (final e in svg.descendants.whereType<XmlElement>()) {
        for (final a in e.attributes) {
          for (final m in RegExp(r'url\(#([^)]+)\)').allMatches(a.value)) {
            refs.add(m.group(1)!);
          }
          if (a.name.local == 'href' && a.value.startsWith('#')) {
            refs.add(a.value.substring(1));
          }
        }
      }
      expect(refs, isNotEmpty);
      expect(refs.where((r) => !ids.contains(r)), isEmpty);
    });

    test('keeps gradients, textures, blends, blur, the eraser and pictures',
        () async {
      final svg = await _svgOf(_everything());
      expect(_all(svg, 'linearGradient'), isNotEmpty);
      expect(_all(svg, 'radialGradient'), isNotEmpty);
      expect(_all(svg, 'pattern'), hasLength(2), reason: 'two textured lines');
      expect(_all(svg, 'feGaussianBlur'), isNotEmpty, reason: 'soft brush');
      expect(_all(svg, 'mask'), isNotEmpty);
      expect(
        _all(svg, 'g').map((g) => g.getAttribute('style') ?? ''),
        contains(contains('mix-blend-mode:multiply')),
      );
      final pictures = [
        for (final i in _all(svg, 'image')) i.getAttribute('xlink:href') ?? '',
      ];
      expect(pictures, isNotEmpty);
      expect(pictures.every((p) => p.startsWith('data:image/png;base64,')),
          isTrue);
      expect(
        _all(svg, 'path').where((p) => p.getAttribute('fill-rule') == 'evenodd'),
        isNotEmpty,
        reason: 'the paint bucket area keeps its hole',
      );
    });

    test('two eraser strokes in a row share one mask', () async {
      final svg = await _svgOf(_everything());
      final erasing = _all(svg, 'mask').where((m) =>
          m.childElements.first.localName == 'rect' &&
          m.childElements.first.getAttribute('fill') == '#fff');
      expect(erasing, hasLength(1));
      expect(
        erasing.single.childElements.where((e) => e.getAttribute('fill') == '#000000'),
        hasLength(2),
      );
    });

    test('writes letters as outlines of the bundled font', () async {
      final svg = await _svgOf(_everything());
      final words = _all(svg, 'path')
          .where((p) => p.getAttribute('aria-label') == '快乐 Joy')
          .single;
      expect(words.getAttribute('d'), allOf(startsWith('M'), endsWith('Z')));
      expect(words.getAttribute('stroke'), '#233a73', reason: 'made-up bold');
      // Text in the device's own font stays text.
      final plain = _all(svg, 'text').map((t) => t.innerText).join();
      expect(plain, 'Hi');
    });

    test('leaves the paper color out when asked, as a PNG does', () async {
      final doc = _everything();
      final svg = await _svgOf(doc, paper: false);
      expect(_all(svg, 'rect').where((r) => r.getAttribute('id') == 'paper'),
          isEmpty);
      for (final (paper, alpha) in [(true, 255), (false, 0)]) {
        final png = await exportPainting(doc, ExportFormat.png, paper: paper);
        final picture = img.decodePng(png.bytes)!;
        expect(picture.getPixel(picture.width - 2, picture.height - 2).a, alpha);
      }
    });
  });

  group('SVG shapes', () {
    test('keep their corners exactly and their curves within reach', () {
      final star = [
        for (var i = 0; i < 10; i++)
          Offset(100, 100) +
              Offset.fromDirection(i * math.pi / 5, i.isEven ? 80 : 30),
      ];
      final d = svgPathData(Path()..addPolygon(star, true));
      expect(d, endsWith('Z'));
      final pts = _points(d);
      for (final corner in star) {
        expect(pts.any((p) => (p - corner).distance < 0.02), isTrue,
            reason: 'corner $corner');
      }
      expect(pts.length, lessThan(30), reason: 'straight sides need no steps');
      final circle = _points(svgPathData(
          Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 50))));
      for (final p in circle) {
        expect(p.distance, closeTo(50, 0.12));
      }
    });

    test('numbers are short', () {
      expect(svgNumber(12), '12');
      expect(svgNumber(12.5), '12.5');
      expect(svgNumber(-0.004), '0');
      expect(svgNumber(-3.14159), '-3.14');
      expect(svgNumber(0.05), '0.05');
    });

    test('letters come from the font file', () async {
      final font = FontOutlines.parse(await rootBundle
          .load('assets/fonts/zcoolkuaile/ZCOOLKuaiLe-Regular.ttf'))!;
      expect(font.unitsPerEm, greaterThan(0));
      for (final c in '快乐A9'.split('')) {
        expect(font.has(c.runes.single), isTrue, reason: c);
        expect(font.outline(c.runes.single, (x, y) => Offset(x, -y)),
            allOf(startsWith('M'), endsWith('Z')));
      }
      expect(font.outline(' '.runes.single, (x, y) => Offset(x, y)), '');
      expect(font.has(0x1F600), isFalse);
      expect(font.outline(0x1F600, (x, y) => Offset(x, y)), isNull);
      expect(FontOutlines.parse(ByteData(64)), isNull);
    });
  });

  testWidgets('the download sheet offers SVG and a see-through background',
      (tester) async {
    final delivered = <ExportedFile>[];
    deliverExport = (file, origin) async => delivered.add(file);
    await pumpApp(tester);
    await tapMenu(tester, '下载图片');
    final paper = find.byKey(const ValueKey('exportPaper'));
    expect(find.text('带上纸的颜色'), findsOneWidget);
    expect(tester.widget<ElasticSwitchTile>(paper).value, isTrue);
    await tester.tap(paper);
    await tester.pumpAndSettle();
    expect(tester.widget<ElasticSwitchTile>(paper).value, isFalse);
    final svg = find.widgetWithText(ListTile, '矢量图（SVG）');
    await tester.ensureVisible(svg);
    await tester.pumpAndSettle();
    await tester.tap(svg);
    await tester.pumpAndSettle();
    expect(delivered.single.name, endsWith('.svg'));
    expect(delivered.single.mimeType, 'image/svg+xml');
    expect(utf8.decode(delivered.single.bytes), isNot(contains('id="paper"')));
  });
}
