import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../stroke.dart';
import 'paint_strokes.dart';

/// The color seen at a point of the paper, and the little patch of paper
/// around it (for a loupe).
class PaperSample {
  PaperSample(this.color, this.patch);

  final Color color;

  /// [PaperSampler.patchSize] × [PaperSampler.patchSize] pixels, one per
  /// paper point, centered on the point. The caller disposes it.
  final ui.Image patch;
}

/// Reads what the painting looks like at a point: paper and paint mixed as
/// on screen, with blends, textures and see-through paint. The eyedropper
/// uses it; filling an area will too.
abstract final class PaperSampler {
  static const patchSize = 9;

  /// The paper of [size] and [paper] color under [strokes], around [at].
  /// [finished], a picture of exactly [strokes] (see
  /// [StrokeLayerCache.imageOf]), saves painting them again.
  static Future<PaperSample> sample(Offset at,
      {required Size size,
      required Color paper,
      required List<Stroke> strokes,
      ui.Image? finished}) async {
    const half = patchSize / 2;
    // The patch's pixels are paper points, the middle one centered on [at].
    final area = Rect.fromLTWH(at.dx.floorToDouble() + 0.5 - half,
        at.dy.floorToDouble() + 0.5 - half, patchSize.toDouble(),
        patchSize.toDouble());
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)
      ..translate(-area.left, -area.top)
      ..clipRect(area)
      ..drawRect(area, Paint()..color = paper);
    if (finished != null) {
      final sx = finished.width / size.width;
      final sy = finished.height / size.height;
      canvas.drawImageRect(
          finished,
          Rect.fromLTRB(area.left * sx, area.top * sy, area.right * sx,
              area.bottom * sy),
          area,
          Paint()..filterQuality = FilterQuality.medium);
    } else {
      paintStrokes(canvas, size, strokes, paper: paper);
    }
    final patch =
        await recorder.endRecording().toImage(patchSize, patchSize);
    final data = (await patch.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    return PaperSample(_middle(data), patch);
  }

  static Color _middle(ByteData data) {
    final i = (patchSize ~/ 2 * patchSize + patchSize ~/ 2) * 4;
    // The paper is opaque, so the color is too.
    return Color.fromARGB(
        255, data.getUint8(i), data.getUint8(i + 1), data.getUint8(i + 2));
  }
}

/// The whole painting as RGBA pixels, [ratio] pixels per paper point.
class PaperPixels {
  PaperPixels(this.rgba, this.width, this.height, this.ratio);

  final Uint8List rgba;
  final int width;
  final int height;
  final double ratio;
}

/// The paper of [size] and [paper] color under [strokes] as pixels: two
/// per paper point, or fewer for a big paper (at most [maxSide] across).
/// [finished], a picture of exactly [strokes], saves painting them again.
Future<PaperPixels> paperPixels(
    {required Size size,
    required Color paper,
    required List<Stroke> strokes,
    ui.Image? finished,
    int maxSide = 2048}) async {
  final ratio = math.min(2.0, maxSide / math.max(size.width, size.height));
  final width = math.max(1, (size.width * ratio).round());
  final height = math.max(1, (size.height * ratio).round());
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(width / size.width, height / size.height)
    ..drawRect(Offset.zero & size, Paint()..color = paper);
  if (finished != null) {
    canvas.drawImageRect(
        finished,
        Rect.fromLTWH(
            0, 0, finished.width.toDouble(), finished.height.toDouble()),
        Offset.zero & size,
        Paint()..filterQuality = FilterQuality.medium);
  } else {
    paintStrokes(canvas, size, strokes, paper: paper);
  }
  final image = await recorder.endRecording().toImage(width, height);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();
  return PaperPixels(data.buffer.asUint8List(), width, height, ratio);
}
