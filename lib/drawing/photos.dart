import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// A picture placed on the paper (a photo to trace, say): its encoded
/// bytes (JPEG or PNG) and the size it covers, in paper points. Copies of
/// a stroke share it.
class StrokePhoto {
  StrokePhoto(this.bytes, this.size);

  final Uint8List bytes;
  final ui.Size size;

  Map<String, Object?> toJson() => {
        'data': base64Encode(bytes),
        'w': (size.width * 10).round() / 10,
        'h': (size.height * 10).round() / 10,
      };

  /// Null for anything that isn't a usable picture.
  static StrokePhoto? fromJson(Object? json) {
    if (json is! Map || json['data'] is! String) return null;
    final w = json['w'], h = json['h'];
    if (w is! num || h is! num || w <= 0 || h <= 0) return null;
    try {
      return StrokePhoto(base64Decode(json['data'] as String),
          ui.Size(w.toDouble(), h.toDouble()));
    } on FormatException {
      return null;
    }
  }
}

/// The decoded pictures of [StrokePhoto]s. Painting can't wait, so a
/// picture is decoded the first time it's needed, and [decoded] tells
/// painters to paint again once it's ready.
abstract final class Photos {
  static final _images = Expando<ui.Image>('photo');
  static final _decoding = Expando<Future<void>>('decoding');

  /// Bumped whenever a picture finishes decoding.
  static final decoded = ValueNotifier<int>(0);

  /// The decoded picture, or null while it's being decoded (which this
  /// starts).
  static ui.Image? imageFor(StrokePhoto photo) {
    final image = _images[photo];
    if (image == null) _decode(photo);
    return image;
  }

  /// Waits until every one of [photos] is decoded (before an export).
  static Future<void> ready(Iterable<StrokePhoto> photos) => Future.wait([
        for (final p in photos)
          if (_images[p] == null) _decode(p),
      ]);

  static Future<void> _decode(StrokePhoto photo) =>
      _decoding[photo] ??= () async {
        try {
          final codec = await ui.instantiateImageCodec(photo.bytes);
          final frame = await codec.getNextFrame();
          codec.dispose();
          _images[photo] = frame.image;
          decoded.value++;
        } catch (_) {
          // An unreadable picture stays a placeholder.
        }
      }();
}
