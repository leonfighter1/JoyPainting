import 'package:flutter/material.dart';

import 'stroke.dart';

/// 我的画笔: a brush with its settings (size, opacity, color, gradient,
/// light & shadow, texture) saved under a name, to pick again in one tap.
@immutable
class BrushPreset {
  const BrushPreset({
    required this.id,
    required this.name,
    required this.brush,
    required this.size,
    required this.opacity,
    required this.color,
    this.gradient = GradientStyle.none,
    this.blend = StrokeBlend.normal,
    this.texture = StrokeTexture.none,
  });

  /// At most this many are kept.
  static const max = 12;

  final String id;
  final String name;
  final BrushType brush;
  final double size;
  final double opacity;
  final Color color;
  final GradientStyle gradient;
  final StrokeBlend blend;
  final StrokeTexture texture;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'brush': brush.name,
    'size': size,
    'opacity': opacity,
    'color': color.toARGB32(),
    if (gradient != GradientStyle.none) 'gradient': gradient.name,
    if (blend != StrokeBlend.normal) 'blend': blend.name,
    if (texture != StrokeTexture.none) 'texture': texture.name,
  };

  /// Null if [json] isn't a brush preset.
  static BrushPreset? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final id = json['id'], name = json['name'], size = json['size'];
    final color = json['color'], opacity = json['opacity'];
    if (id is! String || name is! String || size is! num || color is! int) {
      return null;
    }
    return BrushPreset(
      id: id,
      name: name,
      brush: BrushType.fromName(json['brush'] as String?),
      size: size.toDouble(),
      opacity: opacity is num ? opacity.toDouble() : 1,
      color: Color(color),
      gradient: GradientStyle.fromName(json['gradient'] as String?),
      blend: StrokeBlend.fromName(json['blend'] as String?),
      texture: StrokeTexture.fromName(json['texture'] as String?),
    );
  }
}
