import 'drawing/stroke.dart';

/// How many tools the drawing screen shows. Beginners see the simple ones,
/// and each level adds more. Paintings look the same at every level: a
/// level only hides tools, never what was drawn with them.
enum SkillLevel {
  /// The everyday brushes, colors, shapes, stamps, the paint bucket and text.
  beginner,

  /// Adds the highlighter, soft brush, move tool and color picker, opacity,
  /// free shapes and gradients.
  intermediate,

  /// Everything: adds the blender, light and shadow, textures and layers,
  /// for realistic paintings.
  advanced;

  static SkillLevel fromName(String? name) =>
      values.firstWhere((l) => l.name == name, orElse: () => beginner);

  bool get _intermediate => index >= intermediate.index;

  /// Whether [b] is shown in the tools drawer and toolbar.
  bool allows(BrushType b) => switch (b) {
        BrushType.pen ||
        BrushType.pencil ||
        BrushType.marker ||
        BrushType.spray ||
        BrushType.rainbow ||
        BrushType.stamp ||
        BrushType.bucket ||
        BrushType.text ||
        BrushType.eraser =>
          true,
        BrushType.highlighter ||
        BrushType.soft ||
        BrushType.move ||
        BrushType.picker =>
          _intermediate,
        BrushType.smudge => this == advanced,
      };

  /// The brushes and tools shown, in toolbar order.
  List<BrushType> get brushes =>
      [for (final b in BrushType.values) if (allows(b)) b];

  bool get opacity => _intermediate;
  bool get freeShape => _intermediate;

  /// Adding a photo to trace.
  bool get photos => _intermediate;
  bool get gradients => _intermediate;
  bool get lightAndShadow => this == advanced;
  bool get textures => this == advanced;

  /// Several layers, each shown, hidden, locked or faded on its own.
  bool get layers => this == advanced;
}
