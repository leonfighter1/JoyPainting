import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/tools/fill_tool.dart';
import 'package:jingyao_paint/drawing/canvas_page.dart';
import 'package:jingyao_paint/drawing/render/flood_fill.dart';
import 'package:jingyao_paint/drawing/render/render_image.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/skill_level.dart';

import 'test_helpers.dart';
import 'widget_test.dart' show pumpApp;

/// A white [w]×[h] picture with black where [ink] is true.
Uint8List picture(int w, int h, bool Function(int x, int y) ink) {
  final px = Uint8List(w * h * 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      final v = ink(x, y) ? 0 : 255;
      px
        ..[i] = v
        ..[i + 1] = v
        ..[i + 2] = v
        ..[i + 3] = 255;
    }
  }
  return px;
}

/// The outlines filled when (x, y) is tapped.
List<List<Offset>> fill(Uint8List px, int x, int y, {int gap = 0}) =>
    fillOutlines(FillRequest(
        rgba: px, width: 100, height: 100, x: x, y: y, gap: gap));

/// Whether [p] is inside [loops], filled even-odd.
bool filled(List<List<Offset>> loops, Offset p) {
  var inside = false;
  for (final loop in loops) {
    for (var i = 0, j = loop.length - 1; i < loop.length; j = i++) {
      final a = loop[i], b = loop[j];
      if ((a.dy > p.dy) != (b.dy > p.dy) &&
          p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) {
        inside = !inside;
      }
    }
  }
  return inside;
}

/// A ring around (50, 50), 20 across the middle of its 2-pixel line, with
/// a [gap] pixels wide opening on the right.
bool ring(int x, int y, {int gap = 0}) {
  final d = math.sqrt((x - 50) * (x - 50) + (y - 50) * (y - 50));
  return d >= 19 && d < 21 && !(x > 60 && (y - 50).abs() * 2 < gap);
}

void main() {
  group('Filling an area', () {
    test('fills inside a closed ring, not outside, and under its edge', () {
      final loops = fill(picture(100, 100, ring), 50, 50);
      expect(loops, hasLength(1));
      expect(filled(loops, const Offset(50.5, 50.5)), isTrue);
      expect(filled(loops, const Offset(50.5, 32.5)), isTrue,
          reason: 'right up to the line');
      expect(filled(loops, const Offset(50.5, 31.5)), isTrue,
          reason: 'one pixel under the line, so no seam shows');
      expect(filled(loops, const Offset(50.5, 30.5)), isFalse,
          reason: 'the rest of the line stays visible');
      expect(filled(loops, const Offset(5.5, 5.5)), isFalse);
    });

    test('a small gap in the line is closed; without closing, it leaks',
        () {
      final px = picture(100, 100, (x, y) => ring(x, y, gap: 3));
      final leak = fill(px, 50, 50);
      expect(filled(leak, const Offset(5.5, 5.5)), isTrue, reason: 'leaked');
      final closed = fill(px, 50, 50, gap: 2);
      expect(filled(closed, const Offset(50.5, 50.5)), isTrue);
      expect(filled(closed, const Offset(5.5, 5.5)), isFalse);
      expect(filled(closed, const Offset(75.5, 50.5)), isFalse,
          reason: 'only a little past the gap');
    });

    test('what is inside stays as a hole; outside fills around the ring',
        () {
      // A square frame with a dot in the middle.
      final px = picture(100, 100, (x, y) {
        final frame = (x >= 20 && x < 80 && y >= 20 && y < 80) &&
            !(x >= 22 && x < 78 && y >= 22 && y < 78);
        final dot = x >= 47 && x < 53 && y >= 47 && y < 53;
        return frame || dot;
      });
      final inside = fill(px, 30, 30);
      expect(inside, hasLength(2), reason: 'around the area, around the dot');
      expect(filled(inside, const Offset(30.5, 30.5)), isTrue);
      expect(filled(inside, const Offset(50.5, 50.5)), isFalse);
      expect(filled(inside, const Offset(10.5, 10.5)), isFalse);
      final outside = fill(px, 5, 5);
      expect(filled(outside, const Offset(5.5, 95.5)), isTrue);
      expect(filled(outside, const Offset(30.5, 30.5)), isFalse);
    });

    test('blank paper fills completely, as one rectangle', () {
      final loops = fill(picture(100, 100, (x, y) => false), 10, 10);
      expect(loops.single, hasLength(4));
      expect(filled(loops, const Offset(99.5, 99.5)), isTrue);
    });

    test('a tap outside the picture fills nothing', () {
      expect(fill(picture(100, 100, (x, y) => false), 100, 5), isEmpty);
    });
  });

  group('A filled area as a stroke', () {
    final area = [
      const [Offset(0, 0), Offset(40, 0), Offset(40, 40), Offset(0, 40)],
      const [Offset(10, 10), Offset(30, 10), Offset(30, 30), Offset(10, 30)],
    ];

    test('is saved with its holes and moves with them', () async {
      final settings = (await createTestApp()).settings
        ..color = const Color(0xFF3DA9FC);
      final s = fillStroke(settings, area);
      expect(s.hits(const Offset(5, 5)), isTrue);
      expect(s.hits(const Offset(20, 20), reach: 0), isFalse,
          reason: 'the hole is not part of it');
      final back = Stroke.fromJson(s.toJson());
      expect(back.area, area);
      expect(back.color, const Color(0xFF3DA9FC));
      final moved = back.moved(const Offset(5, 5));
      expect(moved.area![1].first, const Offset(15, 15));
      final json = Map.of(s.toJson())..remove('area');
      expect(Stroke.fromJson(json).area, isNull,
          reason: 'older files have no area');
    });

    test('paints exactly its area, square corners included', () async {
      final settings = (await createTestApp()).settings
        ..color = const Color(0xFF000000);
      final raw = await renderRgba(
          [fillStroke(settings, area)], const Size(50, 50), 1);
      int red(int x, int y) => raw.rgba[(y * raw.width + x) * 4];
      expect(red(1, 1), 0, reason: 'the corner is filled');
      expect(red(38, 38), 0);
      expect(red(20, 20), 255, reason: 'the hole is empty');
      expect(red(45, 45), 255);
    });
  });

  test('every level has the bucket; it has no size', () {
    for (final level in SkillLevel.values) {
      expect(level.brushes, contains(BrushType.bucket));
    }
    expect(BrushType.bucket.usesSize, isFalse);
    expect(BrushType.bucket.usesShapes, isFalse);
    expect(BrushType.bucket.usesColor, isTrue);
  });

  testWidgets('tapping inside a drawn ring fills it; one undo takes it away',
      (tester) async {
    final app = await pumpApp(tester);
    final drawing = app.session.drawing;
    final paper = tester.getRect(find.byKey(CanvasPageState.paperKey));
    final center = paper.size.center(Offset.zero);
    drawing.add(Stroke.shape(
      shape: ShapeKind.ellipse,
      from: center - const Offset(60, 60),
      to: center + const Offset(60, 60),
      brush: BrushType.marker,
      color: Colors.black,
      size: 4,
    ));
    app.settings
      ..brush = BrushType.bucket
      ..color = const Color(0xFFFFD23F);
    await tester.pumpAndSettle();
    await tester.tapAt(paper.center);
    // Reading the painting and working out the area is real work.
    for (var i = 0; i < 20 && drawing.strokes.length < 2; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    expect(drawing.strokes, hasLength(2));
    final fill = drawing.strokes.last;
    expect(fill.area, isNotNull);
    expect(fill.color, const Color(0xFFFFD23F));
    expect(fill.hits(center, reach: 0), isTrue);
    expect(fill.hits(center + const Offset(80, 0), reach: 0), isFalse,
        reason: 'outside the ring');
    drawing.undo();
    expect(drawing.strokes, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
  });
}
