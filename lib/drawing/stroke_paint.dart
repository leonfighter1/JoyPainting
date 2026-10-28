part of 'stroke.dart';

/// Painting a stroke onto a canvas: lines, shapes, spray, rainbow, stamps,
/// text, textures, bristles and the blender.
extension StrokePainting on Stroke {
  /// Paints the stroke (and its mirror image) onto [canvas].
  void paint(Canvas canvas) {
    if (transform case final t?) {
      canvas
        ..save()
        ..transform(t.matrix4);
    }
    _paintOnce(canvas);
    if (mirrorX case final m?) {
      canvas
        ..save()
        ..translate(2 * m, 0)
        ..scale(-1, 1);
      _paintOnce(canvas);
      canvas.restore();
    }
    if (transform != null) canvas.restore();
  }

  void _paintText(Canvas canvas) {
    final alpha = (color.a * opacity).clamp(0.0, 1.0);
    final bounds = textBounds;
    // Bubble and text fade together, so the bubble doesn't show through.
    final translucent = alpha < 1;
    if (translucent) {
      canvas.saveLayer(bounds.inflate(2), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    }
    if (text!.bubble) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(bounds, const Radius.circular(16)),
        Paint()..color = color.withValues(alpha: 0.16),
      );
    }
    _laidOutText.paint(canvas, _textTopLeft);
    if (translucent) canvas.restore();
  }

  void _paintOnce(Canvas canvas) {
    // The blender needs what's under it; see [paintSmudge].
    if (brush == BrushType.smudge) return;
    // A blend mode mixes the whole stroke with what's under it at once,
    // and a texture takes paint away from the whole stroke, so the stroke
    // is drawn on its own layer first.
    final blended = blend != StrokeBlend.normal && brush != BrushType.eraser;
    final textured =
        texture != StrokeTexture.none && brush.usesTexture && text == null;
    if (blended || textured) {
      canvas.saveLayer(text != null ? textBounds.inflate(2) : _bounds,
          Paint()..blendMode = blend.mode);
    }
    _paintContent(canvas);
    if (textured) _paintTexture(canvas);
    if (blended || textured) canvas.restore();
  }

  /// Masks the stroke just painted with its texture. Bristles follow a
  /// line along its length; areas get the grain along their longest side.
  void _paintTexture(Canvas canvas) {
    if (texture == StrokeTexture.bristle && !fill && points.length > 1) {
      _paintBristles(canvas);
    } else {
      texture.mask(canvas, _bounds, angle: _mainAngle);
    }
  }

  /// The direction the points mostly run in (radians).
  double get _mainAngle {
    if (points.length < 2) return 0;
    var mx = 0.0, my = 0.0;
    for (final p in points) {
      mx += p.x;
      my += p.y;
    }
    mx /= points.length;
    my /= points.length;
    var xx = 0.0, yy = 0.0, xy = 0.0;
    for (final p in points) {
      final dx = p.x - mx, dy = p.y - my;
      xx += dx * dx;
      yy += dy * dy;
      xy += dx * dy;
    }
    return 0.5 * math.atan2(2 * xy, xx - yy);
  }

  /// Keeps the paint only where the hairs of a bristle brush drag it along
  /// the line: streaks of different strength, some running dry early.
  void _paintBristles(Canvas canvas) {
    final pts = [for (final p in points) p as Offset];
    Offset normalAt(int i) {
      final d = pts[math.min(pts.length - 1, i + 1)] - pts[math.max(0, i - 1)];
      return d.distance == 0
          ? const Offset(0, 1)
          : Offset(-d.dy, d.dx) / d.distance;
    }

    final normals = [for (var i = 0; i < pts.length; i++) normalAt(i)];
    final rnd = math.Random(seed);
    final hairs = (width / 1.5).clamp(5, 48).round();
    canvas.saveLayer(_bounds, Paint()..blendMode = BlendMode.dstIn);
    for (var h = 0; h < hairs; h++) {
      final across = ((h + 0.5) / hairs - 0.5) * width * 1.05 +
          (rnd.nextDouble() - 0.5) * width / hairs;
      final strength = 0.4 + 0.6 * rnd.nextDouble();
      final start = (rnd.nextDouble() * 0.1 * pts.length).floor();
      final end = pts.length - (rnd.nextDouble() * 0.3 * pts.length).floor();
      final hairWidth = width / hairs * (1.6 + rnd.nextDouble());
      if (end - start < 2) continue;
      // Each hair runs dry toward its end: the last third fades out.
      final paint = Paint()
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = hairWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final dry = start + ((end - start) * 0.67).round();
      for (final (from, to, fade) in [
        (start, dry, 1.0),
        (dry - 1, dry + (end - dry) ~/ 2, 0.6),
        (dry + (end - dry) ~/ 2 - 1, end, 0.3),
      ]) {
        if (to - from < 2) continue;
        final hair = Path();
        for (var i = from; i < to; i++) {
          final p = pts[i] + normals[i] * across;
          i == from ? hair.moveTo(p.dx, p.dy) : hair.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
            hair, paint..color = Color.fromRGBO(255, 255, 255, strength * fade));
      }
    }
    canvas.restore();
  }

  /// How far the blender spreads colors (a blur radius in pixels).
  double get smudgeRadius => math.max(1, width * 0.3);

  /// Paints a blender stroke: [under], what's painted beneath it already
  /// blurred and covering [region] of the paper, shows through the
  /// stroke's shape, as strongly as its opacity.
  void paintSmudge(Canvas canvas, ui.Image under, Rect region) {
    final area = bounds.intersect(region);
    if (area.isEmpty) return;
    canvas
      ..saveLayer(area, Paint())
      ..drawImageRect(
        under,
        Rect.fromLTWH(0, 0, under.width.toDouble(), under.height.toDouble()),
        region,
        Paint()..filterQuality = FilterQuality.medium,
      )
      // The stroke's shape (and its mirror image) together, as a mask.
      ..saveLayer(area, Paint()..blendMode = BlendMode.dstIn);
    if (transform case final t?) {
      canvas
        ..save()
        ..transform(t.matrix4);
    }
    _paintSmudgeMask(canvas);
    if (mirrorX case final m?) {
      canvas
        ..save()
        ..translate(2 * m, 0)
        ..scale(-1, 1);
      _paintSmudgeMask(canvas);
      canvas.restore();
    }
    if (transform != null) canvas.restore();
    canvas
      ..restore()
      ..restore();
  }

  void _paintSmudgeMask(Canvas canvas) {
    final paint = Paint()
      ..isAntiAlias = true
      ..color = Color.fromRGBO(0, 0, 0, (opacity * brush.opacity).clamp(0, 1));
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    if (shape != null && !fill) {
      canvas.drawPath(
          _shapePath,
          paint
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    } else {
      canvas.drawPath(fill ? _fillArea : path, paint);
    }
  }

  void _paintContent(Canvas canvas) {
    if (text != null) {
      _paintText(canvas);
      return;
    }
    if (shape != null) {
      _paintShape(canvas);
      return;
    }
    if (brush == BrushType.eraser) {
      // dstOut removes existing ink in proportion to alpha, so a
      // half-opacity eraser fades ink instead of removing it.
      canvas.drawPath(fill ? _fillArea : path, Paint()
        ..isAntiAlias = true
        ..blendMode = BlendMode.dstOut
        ..color = Color.fromRGBO(0, 0, 0, opacity));
      return;
    }
    final alpha = _alpha;
    if (fill) {
      // A free shape: one filled area, so a translucent paint is enough.
      canvas.drawPath(_fillArea, _ink(alpha,
          solid: brush == BrushType.rainbow ? _rainbowAt(0) : null));
      return;
    }
    if (brush.kind == BrushKind.outline) {
      // A single filled outline never overlaps itself, so a translucent
      // paint is enough.
      canvas.drawPath(path, _ink(alpha));
      return;
    }
    // Dots, segments and stamps overlap each other. Draw them solid into a
    // layer and fade the whole layer, so overlaps don't get darker.
    final translucent = alpha < 1;
    if (translucent) {
      canvas.saveLayer(_bounds, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    }
    final solid = color.withValues(alpha: 1);
    switch (brush.kind) {
      case BrushKind.spray:
        _paintSpray(canvas, solid);
      case BrushKind.rainbow:
        _paintRainbow(canvas);
      case BrushKind.stamp:
        _paintStamps(canvas, solid);
      case BrushKind.outline || BrushKind.text:
        break;
    }
    if (translucent) canvas.restore();
  }

  /// How see-through the whole stroke is. A gradient's colors carry
  /// their own see-through-ness, so then [color] doesn't count.
  double get _alpha =>
      ((gradient == null ? color.a : 1) * opacity * brush.opacity)
          .clamp(0.0, 1.0);

  /// The paint for lines and filled areas, faded to [alpha]: the stroke's
  /// gradient, or [solid] (its color by default), with soft edges when it
  /// has [blur].
  Paint _ink(double alpha, {Color? solid}) {
    final paint = Paint()..isAntiAlias = true;
    if (gradient case final g? when solid == null) {
      paint
        ..color = const Color(0xFF000000)
        ..shader = g.shader(_outlineBox, alpha);
    } else {
      paint.color = (solid ?? color).withValues(alpha: alpha);
    }
    if (blur > 0) paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    return paint;
  }

  void _paintShape(Canvas canvas) {
    final outline = _shapePath;
    final linePaint = Paint()
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (brush == BrushType.eraser) {
      // A filled eraser shape clears its whole area.
      final erase = Color.fromRGBO(0, 0, 0, opacity);
      if (fill) {
        canvas.drawPath(outline, Paint()
          ..blendMode = BlendMode.dstOut
          ..color = erase);
      }
      canvas.drawPath(outline, linePaint
        ..blendMode = BlendMode.dstOut
        ..color = erase);
      return;
    }
    // Fill and outline overlap, so fade them together in one layer.
    final alpha = _alpha;
    final translucent = alpha < 1;
    if (translucent) {
      canvas.saveLayer(_bounds, Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    }
    final solid = color.withValues(alpha: 1);
    if (fill) {
      canvas.drawPath(outline,
          _ink(1, solid: brush == BrushType.rainbow ? _rainbowAt(0) : null));
    }
    switch (brush.kind) {
      // Text never becomes a shape; treat it like a plain outline.
      case BrushKind.outline || BrushKind.text:
        // Exact geometry keeps corners crisp.
        canvas.drawPath(
            outline,
            _ink(1)
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round);
      case BrushKind.spray:
        _paintSpray(canvas, solid);
      case BrushKind.rainbow:
        _paintRainbow(canvas);
      case BrushKind.stamp:
        _paintStamps(canvas, solid);
    }
    if (translucent) canvas.restore();
  }

  Color _rainbowAt(double distance) => HSVColor.fromAHSV(
          1, ((seed % 360) + distance * 1.2) % 360, 0.6, 0.97)
      .toColor();

  void _paintSpray(Canvas canvas, Color solid) {
    final radius = math.max(2.0, width / 2);
    // Dots are generated once per new point and kept, so drawing stays fast
    // as the stroke grows. Each segment has its own seed, so the result never
    // depends on how many frames were painted.
    for (var i = _sprayPointsDone; i < points.length; i++) {
      final a = i == 0 ? points[0] : points[i - 1];
      final b = points[i];
      final rnd = math.Random(seed * 7919 + i);
      final steps =
          i == 0 ? 1 : math.max(1, ((b - a).distance / (radius * 0.5)).ceil());
      final perStep = (radius * radius / 10).clamp(6, 50).round();
      for (var s = 0; s < steps; s++) {
        final center = Offset.lerp(a, b, s / steps)!;
        for (var k = 0; k < perStep; k++) {
          final angle = rnd.nextDouble() * 2 * math.pi;
          final dist = radius * math.sqrt(rnd.nextDouble());
          _sprayDots.add(center + Offset(math.cos(angle), math.sin(angle)) * dist);
        }
      }
    }
    _sprayPointsDone = points.length;
    canvas.drawPoints(
      ui.PointMode.points,
      _sprayDots,
      Paint()
        ..color = solid
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(1.2, radius / 7),
    );
  }

  void _paintRainbow(Canvas canvas) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = width;
    final hueAt = _rainbowAt;
    if (points.length == 1) {
      canvas.drawCircle(points.first, width / 2,
          paint..style = PaintingStyle.fill..color = hueAt(0));
      return;
    }
    var travelled = 0.0;
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      canvas.drawLine(a, b, paint..color = hueAt(travelled));
      travelled += (b - a).distance;
    }
  }

  void _paintStamps(Canvas canvas, Color solid) {
    final spacing = width * 1.3;
    final fill = Paint()
      ..isAntiAlias = true
      ..color = solid;
    final light = Paint()
      ..isAntiAlias = true
      ..color = Color.lerp(solid, Colors.white, 0.65)!;
    var index = 0;
    void place(Offset at) {
      final rnd = math.Random(seed + index++);
      final scale = width / 2 * (0.85 + rnd.nextDouble() * 0.3);
      canvas
        ..save()
        ..translate(at.dx, at.dy)
        ..rotate((rnd.nextDouble() - 0.5) * 0.8)
        ..scale(scale);
      for (final (path, isCenter) in _stampPaths[stamp]!) {
        canvas.drawPath(path, isCenter ? light : fill);
      }
      canvas.restore();
    }

    if (points.isEmpty) return;
    place(points.first);
    var untilNext = spacing;
    for (var i = 1; i < points.length; i++) {
      var a = points[i - 1] as Offset;
      final b = points[i] as Offset;
      var segment = (b - a).distance;
      while (segment >= untilNext) {
        a = Offset.lerp(a, b, untilNext / segment)!;
        place(a);
        segment = (b - a).distance;
        untilNext = spacing;
      }
      untilNext -= segment;
    }
  }

  /// Stamp shapes in a unit box centered on the origin. The bool marks a
  /// lighter center (the flower's middle).
  static final Map<StampShape, List<(Path, bool)>> _stampPaths = {
    StampShape.heart: [
      (
        Path()
          ..moveTo(0, 0.85)
          ..cubicTo(-1.3, 0, -0.85, -1.15, 0, -0.45)
          ..cubicTo(0.85, -1.15, 1.3, 0, 0, 0.85)
          ..close(),
        false,
      ),
    ],
    StampShape.star: [(_star(), false)],
    StampShape.flower: [
      for (var i = 0; i < 5; i++)
        (
          Path()
            ..addOval(Rect.fromCircle(
              center: Offset.fromDirection(i * 2 * math.pi / 5 - math.pi / 2, 0.52),
              radius: 0.42,
            )),
          false,
        ),
      (Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.3)), true),
    ],
  };

  static Path _star() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? 1.0 : 0.45;
      final p = Offset.fromDirection(i * math.pi / 5 - math.pi / 2, r);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    return path..close();
  }
}
