import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../render/layer_cache.dart';
import '../stroke.dart';
import 'replay_timeline.dart';

/// The replay of [strokes] on a paper of [size] as an animated GIF.
///
/// Frames are painted here (they need the engine) and encoded in the
/// background. The whole replay is fitted into at most [maxSeconds] at
/// [fps] frames a second, at most [maxSide] pixels across; the finished
/// painting stays on screen for two seconds before it loops. [onProgress]
/// hears 0 to 1; [cancelled] stops early (the result is then null).
Future<Uint8List?> replayGif(List<Stroke> strokes, Size size, Color paper,
    {List<PaintingLayer> layers = const [PaintingLayer.base],
    int maxSide = 400,
    int fps = 10,
    double maxSeconds = 10,
    void Function(double done)? onProgress,
    bool Function()? cancelled}) async {
  final timeline = ReplayTimeline(strokes);
  final frames =
      math.max(2, (math.min(timeline.total, maxSeconds) * fps).round());
  final scale = maxSide / math.max(size.width, size.height);
  final width = math.max(1, (size.width * scale).round());
  final height = math.max(1, (size.height * scale).round());
  final cache = LayeredCache();
  final pixels = <Uint8List>[];
  try {
    for (var i = 0; i < frames; i++) {
      if (cancelled?.call() ?? false) return null;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(width / size.width);
      paintReplayFrame(canvas, size, timeline,
          timeline.total * i / (frames - 1), paper, layers, cache, scale);
      final image = await recorder.endRecording().toImage(width, height);
      final data =
          await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      image.dispose();
      pixels.add(data!.buffer.asUint8List());
      onProgress?.call(0.6 * (i + 1) / frames);
    }
  } finally {
    cache.dispose();
  }
  if (cancelled?.call() ?? false) return null;
  final gif = await compute(
      encodeGif,
      GifFrames(pixels, width, height,
          delay: (100 / fps).round(), lastDelay: 200));
  onProgress?.call(1);
  return gif;
}

/// RGBA frames to encode, with how long each shows (hundredths of a
/// second) and how long the last one stays.
class GifFrames {
  const GifFrames(this.rgba, this.width, this.height,
      {required this.delay, required this.lastDelay});

  final List<Uint8List> rgba;
  final int width;
  final int height;
  final int delay;
  final int lastDelay;
}

/// Encodes [frames] as a looping GIF (for `compute`). Each frame gets its
/// own 256 colors; no dithering, so flat colors stay flat and it is quick.
Uint8List encodeGif(GifFrames frames) {
  final encoder = img.GifEncoder(
      quantizerType: img.QuantizerType.octree, dither: img.DitherKernel.none);
  for (var i = 0; i < frames.rgba.length; i++) {
    encoder.addFrame(
        img.Image.fromBytes(
            width: frames.width,
            height: frames.height,
            bytes: frames.rgba[i].buffer,
            numChannels: 4),
        duration:
            i == frames.rgba.length - 1 ? frames.lastDelay : frames.delay);
  }
  return encoder.finish()!;
}
