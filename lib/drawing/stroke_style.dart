import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'render/vector_hooks.dart';

/// How a stroke mixes with what's under it.
enum StrokeBlend {
  normal(BlendMode.srcOver),

  /// Darkens what's underneath, like a shadow or a glaze.
  multiply(BlendMode.multiply),

  /// Lightens what's underneath, like light falling on it.
  screen(BlendMode.screen),
  overlay(BlendMode.overlay),
  softLight(BlendMode.softLight),
  // Since 6.0; older versions paint these normally.
  hardLight(BlendMode.hardLight),

  /// Brightens what's underneath, as if it glowed.
  colorDodge(BlendMode.colorDodge),

  /// Darkens and deepens what's underneath, like burnt edges.
  colorBurn(BlendMode.colorBurn),

  /// Gives what's underneath this color, keeping its light and shade.
  color(BlendMode.color);

  const StrokeBlend(this.mode);

  final BlendMode mode;

  static StrokeBlend fromName(String? name) =>
      values.firstWhere((b) => b.name == name, orElse: () => normal);
}

/// Colors blending into each other across a stroke, instead of one color.
///
/// [from] and [to] are fractions of the stroke's outline box ((0, 0) its
/// top left, (1, 1) its bottom right), so the gradient grows, moves and
/// turns with the stroke. Radial gradients are centered on [from] and
/// reach [to].
@immutable
class StrokeGradient {
  const StrokeGradient({
    required this.colors,
    this.stops,
    this.radial = false,
    this.from = const Offset(0.5, 0),
    this.to = const Offset(0.5, 1),
  });

  final List<Color> colors;

  /// Where each color sits, 0 to 1; null spreads them evenly.
  final List<double>? stops;
  final bool radial;
  final Offset from;
  final Offset to;

  /// The shader for a stroke whose outline box is [box], with every color
  /// faded by [alpha].
  Shader shader(Rect box, double alpha) {
    // A flat line has a box with no height; give it some.
    final b = Rect.fromCenter(
      center: box.center,
      width: math.max(box.width, 1),
      height: math.max(box.height, 1),
    );
    Offset at(Offset f) => b.topLeft + Offset(f.dx * b.width, f.dy * b.height);
    final faded = [
      for (final c in colors.length == 1 ? [colors[0], colors[0]] : colors)
        c.withValues(alpha: c.a * alpha),
    ];
    // dart:ui wants stops for anything but two colors.
    final positions = stops != null && stops!.length == faded.length
        ? stops
        : [for (var i = 0; i < faded.length; i++) i / (faded.length - 1)];
    final a = at(from), z = at(to);
    // Described too, for the SVG export.
    if (radial) {
      final r = math.max(0.5, (z - a).distance);
      return ShaderSpec.describe(ui.Gradient.radial(a, r, faded, positions),
          GradientSpec.radial(a, r, faded, positions!));
    }
    final end = z == a ? a + const Offset(0, 1) : z;
    return ShaderSpec.describe(ui.Gradient.linear(a, end, faded, positions),
        GradientSpec.linear(a, end, faded, positions!));
  }

  Map<String, Object?> toJson() => {
        'colors': [for (final c in colors) c.toARGB32()],
        if (stops != null) 'stops': [for (final s in stops!) (s * 1000).round() / 1000],
        if (radial) 'radial': true,
        'from': [(from.dx * 1000).round() / 1000, (from.dy * 1000).round() / 1000],
        'to': [(to.dx * 1000).round() / 1000, (to.dy * 1000).round() / 1000],
      };

  /// Null for anything that isn't a usable gradient.
  static StrokeGradient? fromJson(Object? json) {
    if (json is! Map) return null;
    final colors = json['colors'];
    if (colors is! List || colors.length < 2) return null;
    final stops = json['stops'];
    Offset offset(Object? v, Offset fallback) => v is List && v.length == 2
        ? Offset((v[0] as num).toDouble(), (v[1] as num).toDouble())
        : fallback;
    return StrokeGradient(
      colors: [for (final c in colors) Color(c as int)],
      stops: stops is List && stops.length == colors.length
          ? [for (final s in stops) (s as num).toDouble()]
          : null,
      radial: json['radial'] == true,
      from: offset(json['from'], const Offset(0.5, 0)),
      to: offset(json['to'], const Offset(0.5, 1)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StrokeGradient &&
      other.radial == radial &&
      other.from == from &&
      other.to == to &&
      listEquals(other.colors, colors) &&
      listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(radial, from, to, Object.hashAll(colors),
      stops == null ? null : Object.hashAll(stops!));
}

/// The ready-made gradients offered in the tools drawer, each made from
/// the chosen color. Linear ones run from the top of a stroke to its
/// bottom, as if lit from above; turn a stroke to turn its gradient.
enum GradientStyle {
  none,

  /// Lighter at the top.
  lighter,

  /// Darker at the bottom.
  darker,

  /// Fading away toward the bottom.
  fade,

  /// Strong in the middle, fading out all around.
  glow,

  /// Lit from the top left, darker around the edge, like a ball.
  rounded,

  // Since 6.0. Older versions read these from the file as they are saved:
  // the colors, not the style.

  /// Lighter on the left, darker on the right.
  across,

  /// Light from the top left corner to shade in the bottom right.
  diagonal,

  /// Through the colors of the rainbow, starting at the chosen one.
  rainbow,

  /// From the chosen color to its opposite on the color wheel.
  contrast;

  StrokeGradient? forColor(Color c) {
    // Whole 8-bit colors, as they will be saved.
    Color whole(Color x) => Color(x.toARGB32());
    final light = whole(Color.lerp(c, Colors.white, 0.6)!);
    final dark = whole(Color.lerp(c, Colors.black, 0.55)!);
    final clear = c.withValues(alpha: 0);
    // Black, white and grays have no hue: their rainbow starts at red.
    final hsl = HSLColor.fromColor(c);
    final hued = hsl.saturation < 0.15
        ? HSLColor.fromAHSL(c.a, 0, 0.75, 0.55)
        : hsl;
    Color turned(double degrees) =>
        whole(hued.withHue((hued.hue + degrees) % 360).toColor());
    return switch (this) {
      none => null,
      lighter => StrokeGradient(colors: [light, c]),
      darker => StrokeGradient(colors: [c, dark]),
      fade => StrokeGradient(colors: [c, clear]),
      glow => StrokeGradient(
          colors: [c, clear], radial: true, from: const Offset(0.5, 0.5),
          to: const Offset(1, 0.5)),
      rounded => StrokeGradient(
          colors: [light, c, dark], stops: const [0, 0.45, 1], radial: true,
          from: const Offset(0.38, 0.32), to: const Offset(1, 1)),
      across => StrokeGradient(
          colors: [light, c, dark], from: const Offset(0, 0.5),
          to: const Offset(1, 0.5)),
      diagonal => StrokeGradient(
          colors: [light, dark], from: Offset.zero, to: const Offset(1, 1)),
      rainbow => StrokeGradient(
          colors: [for (var k = 0; k < 6; k++) turned(k * 60.0)],
          from: const Offset(0, 0.5), to: const Offset(1, 0.5)),
      contrast => StrokeGradient(
          colors: [hsl.saturation < 0.15 ? c : turned(0), turned(180)],
          from: Offset.zero, to: const Offset(1, 1)),
    };
  }

  static GradientStyle fromName(String? name) =>
      values.firstWhere((g) => g.name == name, orElse: () => none);
}
