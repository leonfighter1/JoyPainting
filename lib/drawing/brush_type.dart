/// How a brush turns pointer points into paint.
enum BrushKind {
  /// A smooth filled outline (perfect_freehand).
  outline,

  /// A cloud of random dots, like an airbrush.
  spray,

  /// A line whose color cycles through the rainbow.
  rainbow,

  /// Little shapes stamped along the path.
  stamp,

  /// A block of formatted text placed on the paper.
  text,
}

/// The drawing tools, in toolbar order.
enum BrushType {
  pen(BrushKind.outline, thinning: 0.6, smoothing: 0.5, streamline: 0.5, sizeFactor: 1),
  pencil(BrushKind.outline, thinning: 0.3, smoothing: 0.3, streamline: 0.3, sizeFactor: 0.5, opacity: 0.85),
  marker(BrushKind.outline, smoothing: 0.6, streamline: 0.5, sizeFactor: 1.2),
  highlighter(BrushKind.outline, smoothing: 0.6, streamline: 0.6, sizeFactor: 2, opacity: 0.35),

  /// A see-through line with blurred edges, for shading, glows and soft
  /// light: layers of it build up like paint.
  soft(BrushKind.outline, thinning: 0.2, smoothing: 0.6, streamline: 0.5, sizeFactor: 2, opacity: 0.6, blur: 0.35),

  /// A blender: paints nothing itself, but softens and mixes the colors
  /// already on the paper under it, like a finger or a dry brush smudging
  /// wet paint. See [Stroke.paintSmudge].
  smudge(BrushKind.outline, thinning: 0.2, smoothing: 0.6, streamline: 0.5, sizeFactor: 2.5, blur: 0.2),
  spray(BrushKind.spray, sizeFactor: 2.5),
  rainbow(BrushKind.rainbow, sizeFactor: 1),
  stamp(BrushKind.stamp, sizeFactor: 2.2),

  /// Not a brush but a tool: tap an area to fill it with the color. The
  /// fill is a filled shape (see [Stroke.area]).
  bucket(BrushKind.outline, sizeFactor: 1),

  /// Not a brush but a tool: tap to add text. Its "size" is half the font
  /// size, so the shared size slider still makes sense.
  text(BrushKind.text, sizeFactor: 2),

  /// Not a brush but a tool: select one stroke and drag it somewhere else.
  /// It never creates strokes.
  move(BrushKind.outline, sizeFactor: 1),

  /// Not a brush but a tool: touch the paper to pick up the color seen
  /// there. It never creates strokes.
  picker(BrushKind.outline, sizeFactor: 1),
  eraser(BrushKind.outline, sizeFactor: 2);

  const BrushType(
    this.kind, {
    this.thinning = 0,
    this.smoothing = 0.5,
    this.streamline = 0.5,
    required this.sizeFactor,
    this.opacity = 1,
    this.blur = 0,
  });

  final BrushKind kind;

  /// How much pressure changes the width (0 = constant width). Outline only.
  final double thinning;
  final double smoothing;
  final double streamline;

  /// Multiplies the slider size so every brush feels right at the same setting.
  final double sizeFactor;

  /// Built-in see-through-ness (a highlighter is always a bit transparent),
  /// multiplied with the user's opacity slider.
  final double opacity;

  /// How soft new strokes' edges are: the blur radius as a share of the
  /// line width (see [Stroke.blur]).
  final double blur;

  /// Brushes that ignore the chosen color.
  bool get usesColor =>
      this != eraser &&
      this != rainbow &&
      this != move &&
      this != picker &&
      this != smudge;

  /// Tools that can draw shapes. The eraser is always a round tip; text and
  /// move don't draw at all.
  bool get usesShapes =>
      this != eraser &&
      this != text &&
      this != move &&
      this != picker &&
      this != bucket;

  /// Tools that never draw, so brush size and opacity mean nothing to them.
  bool get drawsNothing => this == move || this == picker;

  /// Tools whose size slider means something.
  bool get usesSize => !drawsNothing && this != bucket;

  /// Brushes whose paint can have a [StrokeTexture]. The eraser and the
  /// blender paint nothing of their own.
  bool get usesTexture => usesShapes && this != smudge;

  /// Tools whose strokes paint nothing of their own (they remove or mix
  /// what's there), so they can't be picked up or selected.
  bool get isEffect => this == eraser || this == smudge;

  static BrushType fromName(String? name) =>
      values.firstWhere((b) => b.name == name, orElse: () => pen);
}

enum StampShape {
  heart,
  star,
  flower,
  // Since 6.0; older versions stamp hearts instead.
  sun,
  leaf,
  paw,
  note;

  static StampShape fromName(String? name) =>
      values.firstWhere((s) => s.name == name, orElse: () => heart);
}
