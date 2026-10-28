import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../stroke.dart';
import 'paint_strokes.dart';

/// Renders [strokes] on [paper] into an image of [size] times [pixelRatio]
/// (each side at most 16384 pixels). The caller disposes it.
Future<ui.Image> renderImage(List<Stroke> strokes, Size size, double pixelRatio,
    {Color paper = Colors.white}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(pixelRatio);
  canvas.drawRect(Offset.zero & size, Paint()..color = paper);
  paintStrokes(canvas, size, strokes, paper: paper);
  return recorder.endRecording().toImage(
      (size.width * pixelRatio).round().clamp(1, 1 << 14),
      (size.height * pixelRatio).round().clamp(1, 1 << 14));
}

/// Renders [strokes] on [paper] as PNG bytes.
Future<Uint8List> renderPng(List<Stroke> strokes, Size size, double pixelRatio,
    {Color paper = Colors.white}) async {
  final image = await renderImage(strokes, size, pixelRatio, paper: paper);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

/// Renders [strokes] on [paper] as raw RGBA pixels, for encoders that
/// Flutter doesn't have built in (like JPEG).
Future<({Uint8List rgba, int width, int height})> renderRgba(
    List<Stroke> strokes, Size size, double pixelRatio,
    {Color paper = Colors.white}) async {
  final image = await renderImage(strokes, size, pixelRatio, paper: paper);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = (
    rgba: data!.buffer.asUint8List(),
    width: image.width,
    height: image.height,
  );
  image.dispose();
  return result;
}
