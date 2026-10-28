import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../drawing/photos.dart';

/// The most pixels a placed picture keeps across: plenty to trace, and a
/// painting file stays a reasonable size.
const maxPhotoSide = 2048;

/// Lets the user pick a picture; its bytes, or null if none was picked.
Future<Uint8List?> pickPhotoBytes() async {
  final file = await openFile(acceptedTypeGroups: const [
    XTypeGroup(
      label: 'images',
      extensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'],
      mimeTypes: [
        'image/jpeg',
        'image/png',
        'image/gif',
        'image/webp',
        'image/bmp',
      ],
      uniformTypeIdentifiers: ['public.image'],
      webWildCards: ['image/*'],
    ),
  ]);
  return file?.readAsBytes();
}

/// A picture of [bytes] ready to place: turned upright (as cameras mark
/// it), at most [maxPhotoSide] across, as a JPEG, covering [fit] (scaled
/// down to fit inside it, never up). Null if it can't be read. The work
/// is done in the background.
Future<StrokePhoto?> photoFromBytes(Uint8List bytes, Size fit) async {
  final shrunk = await compute(_shrink, bytes);
  if (shrunk == null) return null;
  final scale = math.min(1.0,
      math.min(fit.width / shrunk.width, fit.height / shrunk.height));
  return StrokePhoto(
      shrunk.bytes, Size(shrunk.width * scale, shrunk.height * scale));
}

({Uint8List bytes, int width, int height})? _shrink(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  if (math.max(image.width, image.height) > maxPhotoSide) {
    final wide = image.width >= image.height;
    image = img.copyResize(image,
        width: wide ? maxPhotoSide : null,
        height: wide ? null : maxPhotoSide,
        interpolation: img.Interpolation.average);
  }
  return (
    bytes: img.encodeJpg(image, quality: 85),
    width: image.width,
    height: image.height,
  );
}
