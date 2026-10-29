import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../text_content.dart';

/// What went into a shader, for a canvas that has to describe it instead of
/// running it (the SVG export). A dart:ui shader can't be read back, so the
/// painting code describes the ones it makes.
sealed class ShaderSpec {
  const ShaderSpec();

  static final _specs = Expando<ShaderSpec>('shaderSpec');

  /// [shader], remembered as made from [spec].
  static T describe<T extends Shader>(T shader, ShaderSpec spec) {
    _specs[shader] = spec;
    return shader;
  }

  /// What [shader] was made from, if the painting code said.
  static ShaderSpec? of(Shader shader) => _specs[shader];
}

/// A linear gradient from [from] to [to], or a radial one centered on
/// [from] reaching [radius], in the canvas's coordinates.
final class GradientSpec extends ShaderSpec {
  const GradientSpec.linear(this.from, this.to, this.colors, this.stops)
      : radial = false,
        radius = 0;

  const GradientSpec.radial(this.from, this.radius, this.colors, this.stops)
      : radial = true,
        to = from;

  final bool radial;
  final Offset from;
  final Offset to;
  final double radius;
  final List<Color> colors;
  final List<double> stops;
}

/// An image repeated in both directions, placed by [matrix] (a column-major
/// 4×4, as dart:ui takes it).
final class TileSpec extends ShaderSpec {
  const TileSpec(this.image, this.matrix);

  final ui.Image image;
  final Float64List matrix;
}

/// A canvas that draws text as shapes of its own (the SVG export draws each
/// letter's outline) instead of as a laid-out paragraph.
abstract interface class TextShapesCanvas implements Canvas {
  /// Draws [laidOut] with its top-left corner at [topLeft]: [content]'s
  /// words in [color].
  void drawTextShapes(
      TextPainter laidOut, Offset topLeft, TextContent content, Color color);
}
