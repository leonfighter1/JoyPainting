import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/drawing/canvas/tools/draw_tool.dart';
import 'package:jingyao_paint/drawing/drawing_controller.dart';
import 'package:jingyao_paint/drawing/render/layer_cache.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/settings.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

const _size = Size(120, 90);

/// The paper as the drawing screen shows it: the finished layers (with a
/// stroke drawn into its layer) are painted again only when
/// [DrawingController.finishedRevision] changes, as `FinishedStrokesPainter`
/// is; the stroke being drawn on every change, as `CurrentStrokePainter`
/// is.
class _Screen {
  _Screen(this.drawing);

  final DrawingController drawing;
  final _cache = LayeredCache();
  ui.Picture? _finished;
  int? _revision;

  /// How many pixels show ink (differ from the white paper).
  Future<int> inked() async {
    if (_revision != drawing.finishedRevision.value) {
      _revision = drawing.finishedRevision.value;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)
        ..drawRect(Offset.zero & _size, Paint()..color = Colors.white);
      _cache.paint(canvas, _size, drawing.strokes, drawing.layers,
          drawing.paper, 1,
          intoLayer: drawing.intoLayer);
      _finished = recorder.endRecording();
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawPicture(_finished!);
    drawing.paintCurrent(canvas, _size);
    final image = await recorder.endRecording().toImage(120, 90);
    final data = (await image.toByteData())!;
    var n = 0;
    for (var i = 0; i < data.lengthInBytes; i += 4) {
      if (data.getUint8(i) < 225 ||
          data.getUint8(i + 1) < 225 ||
          data.getUint8(i + 2) < 225) {
        n++;
      }
    }
    return n;
  }

  void dispose() => _cache.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'every brush, light & shadow and shape shows while it is drawn, as it '
      'will once finished', () async {
    SharedPreferences.setMockInitialValues(testDefaults);
    final settings = await AppSettings.load();
    settings.color = Colors.black;
    // The brushes that draw on the paper with the draw tool. The eraser and
    // the blender show nothing on blank paper; their own tests cover them.
    final brushes = [
      for (final b in BrushType.values)
        if (!b.drawsNothing &&
            b != BrushType.bucket &&
            b != BrushType.text &&
            b != BrushType.eraser &&
            b != BrushType.smudge)
          b,
    ];
    final failures = <String>[];
    var checked = 0;
    for (final brush in brushes) {
      // Freehand, a free shape, and each shape (closed ones filled too).
      final kinds = <(ShapeKind?, bool, bool)>[
        (null, false, false),
        if (brush.usesShapes) ...[
          (null, true, false),
          for (final k in ShapeKind.values) ...[
            (k, false, false),
            if (k.closed) (k, false, true),
          ],
        ],
      ];
      for (final blend in StrokeBlend.values) {
        for (final (shape, freeShape, fill) in kinds) {
          settings
            ..brush = brush
            ..blend = blend
            ..shape = shape
            ..freeShape = freeShape
            ..fill = fill
            ..size = 6;
          final drawing = DrawingController();
          final screen = _Screen(drawing);
          final name = '${brush.name} ${blend.name} '
              '${shape?.name ?? (freeShape ? 'free shape' : 'freehand')}'
              '${fill ? ' filled' : ''}';
          // A drag from (20, 20) to (100, 70), as the draw tool does it.
          final stroke = newStroke(settings, const Offset(20, 20));
          drawing.begin(stroke,
              stroke.shape == null ? const PointVector(20, 20, 0.5) : null);
          await screen.inked();
          for (var t = 0.1; t <= 1.0001; t += 0.1) {
            final p = Offset.lerp(const Offset(20, 20), const Offset(100, 70), t)!;
            if (stroke.shape != null) {
              drawing.moveShapeEnd(p);
            } else {
              // A loop back for free shapes, so there's an area.
              drawing.extend(PointVector(p.dx, t < 0.5 ? p.dy : p.dy - 30, 0.5));
            }
          }
          final whileDrawing = await screen.inked();
          drawing.end();
          final finished = await screen.inked();
          screen.dispose();
          checked++;
          if (finished == 0) {
            failures.add('$name: nothing once finished');
          } else if (whileDrawing < finished * 0.6) {
            failures.add('$name: $whileDrawing pixels while drawing, '
                '$finished once finished');
          }
        }
      }
    }
    expect(failures, isEmpty,
        reason: '${failures.length} of $checked combinations');
    expect(checked, greaterThan(300));
  });

  test(
      'light & shadow shows while drawing with mirror drawing, a texture, '
      'low opacity, or on a see-through upper layer', () async {
    SharedPreferences.setMockInitialValues(testDefaults);
    final settings = await AppSettings.load();
    settings
      ..color = Colors.black
      ..brush = BrushType.marker
      ..size = 6;
    final failures = <String>[];
    var checked = 0;
    for (final blend in StrokeBlend.values.skip(1)) {
      for (final shape in [null, ShapeKind.line, ShapeKind.rectangle]) {
        for (final extra in ['mirror', 'texture', 'opacity', 'layer']) {
          settings
            ..blend = blend
            ..shape = shape
            ..freeShape = false
            ..fill = false
            ..mirror = extra == 'mirror'
            ..texture =
                extra == 'texture' ? StrokeTexture.charcoal : StrokeTexture.none
            ..opacity = extra == 'opacity' ? 0.4 : 1;
          final drawing = DrawingController();
          if (extra == 'layer') {
            drawing.addLayer();
            drawing.updateLayer(drawing.active.copyWith(opacity: 0.5));
          }
          final screen = _Screen(drawing);
          final stroke = newStroke(settings, const Offset(20, 20),
              mirrorX: settings.mirror ? _size.width / 2 : null,
              layer: drawing.newStrokeLayer);
          drawing.begin(stroke,
              stroke.shape == null ? const PointVector(20, 20, 0.5) : null);
          await screen.inked();
          for (var t = 0.1; t <= 1.0001; t += 0.1) {
            final p = Offset.lerp(const Offset(20, 20), const Offset(50, 70), t)!;
            stroke.shape != null
                ? drawing.moveShapeEnd(p)
                : drawing.extend(PointVector(p.dx, p.dy, 0.5));
          }
          final whileDrawing = await screen.inked();
          drawing.end();
          final finished = await screen.inked();
          screen.dispose();
          checked++;
          final name = '${blend.name} ${shape?.name ?? 'freehand'} $extra';
          if (finished == 0 || whileDrawing < finished * 0.6) {
            failures.add('$name: $whileDrawing while drawing, $finished finished');
          }
        }
      }
    }
    expect(failures, isEmpty,
        reason: '${failures.length} of $checked combinations');
  });
}
