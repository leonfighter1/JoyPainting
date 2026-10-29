import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../../drawing/photos.dart';
import '../../drawing/render/vector_hooks.dart';
import '../../drawing/text_content.dart';
import 'font_outlines.dart';

/// A canvas that writes what is painted on it as SVG, so a painting can be
/// exported as shapes instead of pixels. The strokes paint onto it exactly
/// as they paint onto the screen.
///
/// Every shape is placed on the paper as it is drawn (the canvas's turns
/// and moves are worked into its points), so groups never carry a
/// transform and masks line up with what they cover. What SVG can't do as
/// shapes goes in as pictures: photos, and what the blender smudged.
class SvgCanvas implements TextShapesCanvas {
  SvgCanvas(this.size, {this.fonts = const {}});

  /// The paper's size.
  final Size size;

  /// The fonts text may use, by family, so its letters become outlines.
  /// Text in any other font is written as text.
  final Map<String, FontOutlines> fonts;

  _Affine _ctm = _Affine.identity;
  final _saves = <_Save>[];
  final _root = _Group();
  late _Group _group = _root;
  final _defs = <_Node>[];
  final _images = LinkedHashMap<ui.Image, String>.identity();
  var _ids = 0;
  String? _label;

  /// Set while painting what becomes a mask: every color turns into this
  /// one (white keeps, black takes away), keeping its see-through-ness.
  Color? _maskInk;

  static const _white = Color(0xFFFFFFFF);
  static const _black = Color(0xFF000000);

  String _id(String kind) => '$kind${++_ids}';

  /// A rectangle well around the paper, for masks that must cover
  /// everything.
  Rect get _everywhere => Rect.fromLTWH(-size.width, -size.height,
      size.width * 3, size.height * 3);

  /// Fills the paper with [color], as the bottom-most shape.
  void paper(Color color) => _group.add(_Markup('<rect id="paper" '
      'width="${svgNumber(size.width)}" height="${svgNumber(size.height)}"'
      '${_fill('fill', color)}/>'));

  /// Gives the next layer ([saveLayer]) a name that drawing programs show
  /// (Inkscape's layers, Illustrator's groups).
  void nameNextLayer(String name) => _label = name;

  /// The finished SVG document, titled [title].
  Future<String> finish({String? title}) async {
    while (_saves.isNotEmpty) {
      restore();
    }
    final uris = <ui.Image, String>{};
    for (final image in _images.keys) {
      uris[image] = await _dataUri(image);
    }
    final w = svgNumber(size.width), h = svgNumber(size.height);
    final out = StringBuffer()
      ..write('<?xml version="1.0" encoding="UTF-8"?>\n')
      ..write('<svg xmlns="http://www.w3.org/2000/svg" '
          'xmlns:xlink="http://www.w3.org/1999/xlink" '
          'xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape" '
          'version="1.1" width="$w" height="$h" viewBox="0 0 $w $h">\n');
    if (title != null && title.isNotEmpty) {
      out.write('<title>${xmlText(title)}</title>\n');
    }
    if (_defs.isNotEmpty || _images.isNotEmpty) {
      out.write('<defs>\n');
      for (final MapEntry(key: image, value: id) in _images.entries) {
        out.write('<image id="$id" width="${image.width}" '
            'height="${image.height}" xlink:href="${uris[image]}"/>\n');
      }
      for (final d in _defs) {
        d.write(out);
      }
      out.write('</defs>\n');
    }
    for (final node in _root.children) {
      node.write(out);
    }
    out.write('</svg>\n');
    return out.toString();
  }

  static Future<String> _dataUri(ui.Image image) async {
    if (Photos.photoOf(image) case final photo?) {
      final b = photo.bytes;
      final jpeg = b.length > 2 && b[0] == 0xFF && b[1] == 0xD8;
      return 'data:image/${jpeg ? 'jpeg' : 'png'};base64,${base64Encode(b)}';
    }
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    return 'data:image/png;base64,${base64Encode(png!.buffer.asUint8List())}';
  }

  // Saving, layers and transforms.

  @override
  void save() => _saves.add(_Save(_ctm, _group, _maskInk, null));

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    final layer = _Layer(
      paint.blendMode,
      paint.color.a,
      bounds == null ? null : _polygon(bounds),
      _label,
    );
    _label = null;
    _saves.add(_Save(_ctm, _group, _maskInk, layer));
    _group = layer.content;
    if (paint.blendMode == BlendMode.dstIn) _maskInk = _white;
    if (paint.blendMode == BlendMode.dstOut) _maskInk = _black;
  }

  @override
  void restore() {
    if (_saves.isEmpty) return;
    final s = _saves.removeLast();
    _ctm = s.ctm;
    _group = s.group;
    _maskInk = s.maskInk;
    if (s.layer case final layer?) _composite(layer);
  }

  @override
  int getSaveCount() => _saves.length + 1;

  @override
  void restoreToCount(int count) {
    while (_saves.isNotEmpty && _saves.length + 1 > count) {
      restore();
    }
  }

  /// Puts a finished layer onto what is under it.
  void _composite(_Layer layer) {
    final nodes = layer.content.children;
    switch (layer.mode) {
      case BlendMode.dstIn:
        _mask(nodes, keep: true, region: layer.region, opacity: layer.alpha);
      case BlendMode.dstOut:
        _mask(nodes, keep: false, opacity: layer.alpha);
      case final mode:
        if (nodes.isEmpty) return;
        final blend = _cssBlend(mode);
        final plain = layer.label == null && layer.alpha >= 1 && blend == null;
        if (plain && !layer.content.blended) {
          nodes.forEach(_group.add);
          return;
        }
        _group.add(
          _Group(
            label: layer.label,
            opacity: layer.alpha < 1 ? layer.alpha : null,
            isolate: layer.content.blended,
          )..children.addAll(nodes),
          blend: blend,
        );
    }
  }

  /// Keeps what the current group shows so far only where [source] is
  /// ([keep]: inside [region], outside it everything stays), or takes it
  /// away where [source] is (the eraser).
  void _mask(List<_Node> source,
      {required bool keep, String? region, double opacity = 1}) {
    if (_group.children.isEmpty) return;
    final content = <_Node>[
      if (opacity < 1)
        _Group(opacity: opacity)..children.addAll(source)
      else
        ...source,
    ];
    // Erasing again with nothing painted in between adds to the same mask.
    if (!keep && _group.children.length == 1) {
      if (_group.children.single case final _Group only
          when only.mask?.erases == true) {
        only.mask!.content.addAll(content);
        return;
      }
    }
    final around = _everywhere;
    final mask = _MaskDef(_id('m'), around, erases: !keep);
    if (keep) {
      if (region != null) {
        // Outside the layer nothing changes.
        mask.content.add(_Markup('<path d="${_rectData(around)}$region" '
            'fill-rule="evenodd" fill="#fff"/>'));
      }
    } else {
      mask.content.add(_Markup('<rect x="${svgNumber(around.left)}" '
          'y="${svgNumber(around.top)}" width="${svgNumber(around.width)}" '
          'height="${svgNumber(around.height)}" fill="#fff"/>'));
    }
    mask.content.addAll(content);
    _defs.add(mask);
    final wrapped = _Group(mask: mask)..children.addAll(_group.children);
    _group.children
      ..clear()
      ..add(wrapped);
  }

  @override
  void translate(double dx, double dy) =>
      _ctm = _ctm.times(_Affine(1, 0, 0, 1, dx, dy));

  @override
  void scale(double sx, [double? sy]) =>
      _ctm = _ctm.times(_Affine(sx, 0, 0, sy ?? sx, 0, 0));

  @override
  void rotate(double radians) {
    final c = math.cos(radians), s = math.sin(radians);
    _ctm = _ctm.times(_Affine(c, s, -s, c, 0, 0));
  }

  @override
  void skew(double sx, double sy) =>
      _ctm = _ctm.times(_Affine(1, sy, sx, 1, 0, 0));

  @override
  void transform(Float64List matrix4) => _ctm = _ctm.times(
      _Affine(matrix4[0], matrix4[1], matrix4[4], matrix4[5], matrix4[12],
          matrix4[13]));

  @override
  Float64List getTransform() => _ctm.matrix4;

  @override
  void clipRect(Rect rect,
      {ui.ClipOp clipOp = ui.ClipOp.intersect, bool doAntiAlias = true}) {
    if (clipOp != ui.ClipOp.intersect) {
      throw UnsupportedError('SVG export clips only to the inside');
    }
    _clipTo(_polygon(rect));
  }

  @override
  void clipRRect(RRect rrect, {bool doAntiAlias = true}) =>
      clipPath(Path()..addRRect(rrect));

  @override
  void clipPath(Path path, {bool doAntiAlias = true}) =>
      _clipTo(svgPathData(path.transform(_ctm.matrix4)));

  void _clipTo(String d) {
    final id = _id('c');
    _defs.add(_Markup('<clipPath id="$id" clipPathUnits="userSpaceOnUse">'
        '<path d="$d"/></clipPath>\n'));
    final clipped = _Group(clip: id);
    _group.add(clipped);
    _group = clipped;
  }

  @override
  Rect getLocalClipBounds() => _everywhere;

  @override
  Rect getDestinationClipBounds() => _everywhere;

  // Drawing.

  @override
  void drawPath(Path path, Paint paint) {
    final placed = path.transform(_ctm.matrix4);
    final d = svgPathData(placed);
    if (d.isEmpty) return;
    _shape(d, placed.getBounds(), paint,
        evenOdd: path.fillType == PathFillType.evenOdd);
  }

  @override
  void drawRect(Rect rect, Paint paint) =>
      _shape(_polygon(rect), _ctm.box(rect), paint);

  @override
  void drawRRect(RRect rrect, Paint paint) =>
      drawPath(Path()..addRRect(rrect), paint);

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) => drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRRect(outer)
        ..addRRect(inner),
      paint);

  @override
  void drawOval(Rect rect, Paint paint) => drawPath(Path()..addOval(rect), paint);

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      drawPath(Path()..addOval(Rect.fromCircle(center: c, radius: radius)), paint);

  @override
  void drawArc(Rect rect, double startAngle, double sweepAngle, bool useCenter,
      Paint paint) {
    final path = Path();
    if (useCenter) path.moveTo(rect.center.dx, rect.center.dy);
    path.arcTo(rect, startAngle, sweepAngle, !useCenter);
    if (useCenter) path.close();
    drawPath(path, paint);
  }

  @override
  void drawLine(Offset p1, Offset p2, Paint paint) {
    final a = _ctm.apply(p1), b = _ctm.apply(p2);
    _shape('M${_xy(a)}L${_xy(b)}', Rect.fromPoints(a, b), paint, stroke: true);
  }

  @override
  void drawPoints(ui.PointMode pointMode, List<Offset> points, Paint paint) {
    if (points.isEmpty) return;
    final placed = [for (final p in points) _ctm.apply(p)];
    var box = Rect.fromPoints(placed.first, placed.first);
    for (final p in placed) {
      box = box.expandToInclude(Rect.fromPoints(p, p));
    }
    final d = StringBuffer();
    switch (pointMode) {
      case ui.PointMode.points:
        // Each point is a dot as wide as the line would be.
        final r = math.max(paint.strokeWidth, 1) * _ctm.scale / 2;
        final round = paint.strokeCap == StrokeCap.round;
        final rs = svgNumber(r), ds = svgNumber(2 * r);
        for (final p in placed) {
          if (round) {
            d.write('M${svgNumber(p.dx - r)} ${svgNumber(p.dy)}'
                'a$rs $rs 0 1 0 $ds 0a$rs $rs 0 1 0 -$ds 0');
          } else {
            d.write('M${svgNumber(p.dx - r)} ${svgNumber(p.dy - r)}'
                'h${ds}v${ds}h-${ds}Z');
          }
        }
        _shape(d.toString(), box.inflate(r), paint, fill: true);
      case ui.PointMode.lines:
        for (var i = 0; i + 1 < placed.length; i += 2) {
          d.write('M${_xy(placed[i])}L${_xy(placed[i + 1])}');
        }
        _shape(d.toString(), box, paint, stroke: true);
      case ui.PointMode.polygon:
        d.write('M${_xy(placed.first)}');
        for (final p in placed.skip(1)) {
          d.write('L${_xy(p)}');
        }
        _shape(d.toString(), box, paint, stroke: true);
    }
  }

  @override
  void drawRawPoints(ui.PointMode pointMode, Float32List points, Paint paint) =>
      drawPoints(pointMode, [
        for (var i = 0; i + 1 < points.length; i += 2)
          Offset(points[i], points[i + 1]),
      ], paint);

  @override
  void drawPaint(Paint paint) => _shape(_rectData(_everywhere), _everywhere,
      paint, fill: true);

  @override
  void drawColor(Color color, BlendMode blendMode) => drawPaint(Paint()
    ..color = color
    ..blendMode = blendMode);

  @override
  void drawImage(ui.Image image, Offset offset, Paint paint) => drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      offset & Size(image.width.toDouble(), image.height.toDouble()),
      paint);

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    final id = _images[image] ??= _id('i');
    final w = image.width.toDouble(), h = image.height.toDouble();
    // The part [src] of the picture, stretched over [dst].
    final sx = dst.width / src.width, sy = dst.height / src.height;
    final place = _ctm.times(_Affine(
        sx, 0, 0, sy, dst.left - src.left * sx, dst.top - src.top * sy));
    final alpha = paint.color.a;
    var shown = '<use xlink:href="#$id" transform="${place.svg}"'
        '${alpha < 1 ? ' opacity="${svgNumber(alpha)}"' : ''}/>';
    // Only [dst] shows, and only inside the layer: a layer's bounds clip
    // what is painted on it, and a picture (what the blender smudges) can
    // be bigger than its layer.
    final layerRegion =
        _saves.lastWhere((s) => s.layer != null, orElse: () => _noLayer)
            .layer
            ?.region;
    for (final region in [
      if (src != Rect.fromLTWH(0, 0, w, h)) _polygon(dst),
      ?layerRegion,
    ]) {
      final clip = _id('c');
      _defs.add(_Markup('<clipPath id="$clip" clipPathUnits="userSpaceOnUse">'
          '<path d="$region"/></clipPath>\n'));
      shown = '<g clip-path="url(#$clip)">$shown</g>';
    }
    _group.add(_Markup(shown), blend: _cssBlend(paint.blendMode));
  }

  static final _noLayer = _Save(_Affine.identity, _Group(), null, null);

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) =>
      throw UnsupportedError('SVG export draws text with drawTextShapes');

  @override
  void drawTextShapes(
      TextPainter laidOut, Offset topLeft, TextContent content, Color color) {
    final font = fonts[content.fontFamily];
    final ink = _maskInk ?? color;
    final words = content.text;
    final lines = laidOut.computeLineMetrics();
    if (lines.isEmpty) return;
    final em = content.fontSize / (font?.unitsPerEm ?? 1000);
    // The bundled fonts have no italic or bold letters, so Flutter leans
    // and thickens the regular ones; this does the same.
    final lean = content.italic ? 0.25 : 0.0;
    final outlines = StringBuffer();
    final missing = StringBuffer();
    for (var i = 0; i < words.length;) {
      final rune = _runeAt(words, i);
      final n = rune > 0xFFFF ? 2 : 1;
      final boxes = laidOut.getBoxesForSelection(
          TextSelection(baseOffset: i, extentOffset: i + n));
      i += n;
      if (boxes.isEmpty || _isSpace(rune)) continue;
      final box = boxes.first;
      final line = _lineOf(lines, (box.top + box.bottom) / 2);
      final origin = topLeft + Offset(box.left, line.baseline);
      final shape = font?.outline(
          rune,
          (x, y) => _ctm.apply(
              origin + Offset((x + lean * y) * em, -y * em)));
      if (shape != null) {
        outlines.write(shape);
        continue;
      }
      // A letter the font hasn't got stays a letter, in a font the
      // viewer has.
      missing.write('<text transform="${_ctm.svg}" '
          'x="${svgNumber(origin.dx)}" y="${svgNumber(origin.dy)}" '
          'font-family="sans-serif" font-size="${svgNumber(content.fontSize)}"'
          '${content.bold ? ' font-weight="bold"' : ''}'
          '${content.italic ? ' font-style="italic"' : ''}'
          '${_fill('fill', ink)}>${xmlText(String.fromCharCode(rune))}</text>');
    }
    final label = ' aria-label="${xmlText(words)}"';
    if (outlines.isNotEmpty) {
      final bold = content.bold
          ? '${_fill('stroke', ink)} stroke-width="'
              '${svgNumber(_fakeBold(content.fontSize) * _ctm.scale)}" '
              'stroke-linejoin="round"'
          : '';
      _group.add(_Markup(
          '<path d="$outlines"$label${_fill('fill', ink)}$bold/>'));
    }
    if (missing.isNotEmpty) _group.add(_Markup('<g$label>$missing</g>'));
    // Underline and strike-through, along each line.
    for (final (on, metric, fallback) in [
      (content.underline, font?.underline, -0.12),
      (content.strikethrough, font?.strikeout, 0.3),
    ]) {
      if (!on) continue;
      final position = metric?.position ?? fallback / em * content.fontSize;
      final thick =
          (metric?.thickness ?? content.fontSize / 20 / em) * em * 2;
      final across = Path();
      for (final line in lines) {
        final y = topLeft.dy + line.baseline - position * em;
        across.addRect(Rect.fromLTWH(topLeft.dx + line.left, y - thick / 2,
            line.width, thick));
      }
      drawPath(across, Paint()..color = color);
    }
  }

  /// How much Flutter thickens letters for a bold it has to make up: a
  /// 24th of the size for small text, a 32nd for big text.
  static double _fakeBold(double fontSize) {
    final t = ((fontSize - 9) / 27).clamp(0.0, 1.0);
    return fontSize * (1 / 24 + (1 / 32 - 1 / 24) * t);
  }

  static int _runeAt(String s, int i) {
    final u = s.codeUnitAt(i);
    if (u >= 0xD800 && u < 0xDC00 && i + 1 < s.length) {
      final low = s.codeUnitAt(i + 1);
      if (low >= 0xDC00 && low < 0xE000) {
        return 0x10000 + ((u - 0xD800) << 10) + (low - 0xDC00);
      }
    }
    return u;
  }

  static bool _isSpace(int rune) =>
      rune <= 0x20 || rune == 0xA0 || rune == 0x3000 || rune == 0x200B;

  static ui.LineMetrics _lineOf(List<ui.LineMetrics> lines, double y) {
    var best = lines.first;
    var bestGap = double.infinity;
    for (final line in lines) {
      final top = line.baseline - line.ascent;
      final bottom = line.baseline + line.descent;
      final gap = y < top ? top - y : (y > bottom ? y - bottom : 0.0);
      if (gap < bestGap) {
        best = line;
        bestGap = gap;
      }
    }
    return best;
  }

  /// Adds a shape, [d] in paper coordinates covering [box], painted with
  /// [paint] (as a line when [stroke], filled when [fill], else as the
  /// paint's style says).
  void _shape(String d, Rect box, Paint paint,
      {bool evenOdd = false, bool stroke = false, bool fill = false}) {
    final mode = paint.blendMode;
    final ink = switch (mode) {
      BlendMode.dstIn => _white,
      BlendMode.dstOut => _black,
      _ => _maskInk,
    };
    final lined = stroke || (!fill && paint.style == PaintingStyle.stroke);
    final scale = _ctm.scale;
    final width = math.max(paint.strokeWidth, lined ? 1.0 : 0.0) * scale;
    final reach = lined ? width / 2 : 0.0;
    final attrs = StringBuffer(evenOdd && !lined ? ' fill-rule="evenodd"' : '');
    final colorAttr = lined ? 'stroke' : 'fill';
    if (paint.shader case final shader?) {
      final spec = ShaderSpec.of(shader);
      if (spec == null) {
        throw UnsupportedError('SVG export needs to know what a shader is');
      }
      attrs.write(' $colorAttr="url(#${_shaderDef(spec, ink)})"');
      if (paint.color.a < 1) {
        attrs.write(' $colorAttr-opacity="${svgNumber(paint.color.a)}"');
      }
    } else {
      final c = ink?.withValues(alpha: paint.color.a) ?? paint.color;
      attrs.write(_fill(colorAttr, c));
    }
    if (lined) {
      attrs.write(' fill="none" stroke-width="${svgNumber(width)}"');
      if (paint.strokeCap != StrokeCap.butt) {
        attrs.write(' stroke-linecap="${paint.strokeCap.name}"');
      }
      if (paint.strokeJoin != StrokeJoin.miter) {
        attrs.write(' stroke-linejoin="${paint.strokeJoin.name}"');
      }
    }
    if (_blurOf(paint.maskFilter) case final sigma? when sigma > 0) {
      final s = sigma * scale;
      final region = box.inflate(reach + s * 3 + 1);
      final id = _id('f');
      _defs.add(_Markup('<filter id="$id" filterUnits="userSpaceOnUse" '
          'x="${svgNumber(region.left)}" y="${svgNumber(region.top)}" '
          'width="${svgNumber(region.width)}" '
          'height="${svgNumber(region.height)}">'
          '<feGaussianBlur stdDeviation="${svgNumber(s)}"/></filter>\n'));
      attrs.write(' filter="url(#$id)"');
    }
    final node = _Markup('<path d="$d"$attrs/>');
    switch (mode) {
      case BlendMode.dstIn:
        _mask([node], keep: true, region: d);
      case BlendMode.dstOut:
        _mask([node], keep: false);
      default:
        _group.add(node, blend: _cssBlend(mode));
    }
  }

  /// The blur radius (sigma) of a mask filter. dart:ui keeps it private,
  /// but says it in its description.
  static double? _blurOf(MaskFilter? filter) {
    if (filter == null) return null;
    final m = RegExp(r', (-?[\d.]+)\)$').firstMatch(filter.toString());
    return m == null ? null : double.tryParse(m.group(1)!);
  }

  /// Defines a gradient or a repeated picture for [spec] as drawn now, its
  /// colors turned to [ink] when given; returns its id.
  String _shaderDef(ShaderSpec spec, Color? ink) {
    final id = _id(spec is TileSpec ? 'p' : 'g');
    switch (spec) {
      case GradientSpec():
        final stops = StringBuffer();
        for (var i = 0; i < spec.colors.length; i++) {
          final c = spec.colors[i];
          final shown = ink?.withValues(alpha: c.a) ?? c;
          stops.write('<stop offset="${svgNumber(spec.stops[i])}" '
              'stop-color="${_hex(shown)}"'
              '${shown.a < 1 ? ' stop-opacity="${svgNumber(shown.a)}"' : ''}/>');
        }
        final placed = ' gradientUnits="userSpaceOnUse" '
            'gradientTransform="${_ctm.svg}"';
        _defs.add(_Markup(spec.radial
            ? '<radialGradient id="$id" cx="${svgNumber(spec.from.dx)}" '
                'cy="${svgNumber(spec.from.dy)}" r="${svgNumber(spec.radius)}"'
                '$placed>$stops</radialGradient>\n'
            : '<linearGradient id="$id" x1="${svgNumber(spec.from.dx)}" '
                'y1="${svgNumber(spec.from.dy)}" x2="${svgNumber(spec.to.dx)}" '
                'y2="${svgNumber(spec.to.dy)}"$placed>$stops</linearGradient>\n'));
      case TileSpec():
        final tile = _images[spec.image] ??= _id('i');
        final m = spec.matrix;
        final place =
            _ctm.times(_Affine(m[0], m[1], m[4], m[5], m[12], m[13]));
        _defs.add(_Markup('<pattern id="$id" patternUnits="userSpaceOnUse" '
            'width="${spec.image.width}" height="${spec.image.height}" '
            'patternTransform="${place.svg}"><use xlink:href="#$tile"/></pattern>\n'));
    }
    return id;
  }

  /// [r] turned and moved as the canvas is, as path data.
  String _polygon(Rect r) {
    final a = _ctm.apply(r.topLeft), b = _ctm.apply(r.topRight);
    final c = _ctm.apply(r.bottomRight), d = _ctm.apply(r.bottomLeft);
    return 'M${_xy(a)}L${_xy(b)}L${_xy(c)}L${_xy(d)}Z';
  }

  static String _rectData(Rect r) =>
      'M${_xy(r.topLeft)}H${svgNumber(r.right)}V${svgNumber(r.bottom)}'
      'H${svgNumber(r.left)}Z';

  static String _xy(Offset p) => '${svgNumber(p.dx)} ${svgNumber(p.dy)}';

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  /// ` fill="#rrggbb"` (or another [attr]), with its see-through-ness.
  static String _fill(String attr, Color c) =>
      ' $attr="${_hex(c)}"${c.a < 1 ? ' $attr-opacity="${svgNumber(c.a)}"' : ''}';

  /// The CSS name of a blend mode SVG shows with `mix-blend-mode`; null
  /// for normal painting.
  static String? _cssBlend(BlendMode mode) => switch (mode) {
        BlendMode.srcOver => null,
        BlendMode.multiply => 'multiply',
        BlendMode.screen => 'screen',
        BlendMode.overlay => 'overlay',
        BlendMode.darken => 'darken',
        BlendMode.lighten => 'lighten',
        BlendMode.colorDodge => 'color-dodge',
        BlendMode.colorBurn => 'color-burn',
        BlendMode.hardLight => 'hard-light',
        BlendMode.softLight => 'soft-light',
        BlendMode.difference => 'difference',
        BlendMode.exclusion => 'exclusion',
        BlendMode.hue => 'hue',
        BlendMode.saturation => 'saturation',
        BlendMode.color => 'color',
        BlendMode.luminosity => 'luminosity',
        BlendMode.plus => 'plus-lighter',
        _ => throw UnsupportedError('SVG export can\'t blend with $mode'),
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnsupportedError(
      'SVG export can\'t draw ${invocation.memberName}');
}

/// [path] as SVG path data. Each outline is followed in small steps, its
/// corners found exactly, and then thinned to the fewest points that stay
/// within [tolerance] of it: dart:ui can't hand out a path's curves.
String svgPathData(Path path, {double step = 0.75, double tolerance = 0.08}) {
  final out = StringBuffer();
  for (final contour in path.computeMetrics()) {
    final length = contour.length;
    if (length <= 0) continue;
    final steps = math.max(2, (length / step).ceil());
    final at = length / steps;
    final pts = <Offset>[];
    Offset? lastPos, lastDir;
    for (var i = 0; i <= steps; i++) {
      final t = contour.getTangentForOffset(i * at);
      if (t == null) continue;
      final p = t.position, v = t.vector;
      if (lastPos != null && lastDir != null) {
        // A sharp turn between two steps is a corner: put it where the
        // lines on either side meet.
        final cross = lastDir.dx * v.dy - lastDir.dy * v.dx;
        final dot = lastDir.dx * v.dx + lastDir.dy * v.dy;
        if (dot < 0.9 && cross.abs() > 1e-6) {
          final w = p - lastPos;
          final k = (w.dx * v.dy - w.dy * v.dx) / cross;
          final corner = lastPos + lastDir * k;
          if ((corner - lastPos).distance < 2 * at &&
              (corner - p).distance < 2 * at) {
            pts.add(corner);
          }
        }
      }
      pts.add(p);
      lastPos = p;
      lastDir = v;
    }
    final kept = _simplify(pts, tolerance);
    if (kept.length < 2) continue;
    out.write('M${svgNumber(kept.first.dx)} ${svgNumber(kept.first.dy)}');
    for (final p in kept.skip(1)) {
      out.write('L${svgNumber(p.dx)} ${svgNumber(p.dy)}');
    }
    if (contour.isClosed) out.write('Z');
  }
  return out.toString();
}

/// Ramer–Douglas–Peucker: the points of [pts] needed to stay within
/// [tolerance] of the line through all of them.
List<Offset> _simplify(List<Offset> pts, double tolerance) {
  if (pts.length < 3) return pts;
  final keep = List.filled(pts.length, false);
  keep[0] = keep[pts.length - 1] = true;
  final stack = <(int, int)>[(0, pts.length - 1)];
  while (stack.isNotEmpty) {
    final (a, b) = stack.removeLast();
    if (b - a < 2) continue;
    final p = pts[a], q = pts[b];
    final d = q - p;
    final len = d.distance;
    var far = -1.0, farAt = a;
    for (var i = a + 1; i < b; i++) {
      final r = pts[i] - p;
      final off = len < 1e-9
          ? r.distance
          : (r.dx * d.dy - r.dy * d.dx).abs() / len;
      if (off > far) {
        far = off;
        farAt = i;
      }
    }
    if (far > tolerance) {
      keep[farAt] = true;
      stack
        ..add((a, farAt))
        ..add((farAt, b));
    }
  }
  return [
    for (var i = 0; i < pts.length; i++)
      if (keep[i]) pts[i],
  ];
}

/// [s] safe inside XML text or a quoted attribute.
String xmlText(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

/// A 2D transform: `x' = a·x + c·y + e`, `y' = b·x + d·y + f`.
class _Affine {
  const _Affine(this.a, this.b, this.c, this.d, this.e, this.f);

  static const identity = _Affine(1, 0, 0, 1, 0, 0);

  final double a, b, c, d, e, f;

  /// [next] first, then this.
  _Affine times(_Affine next) => _Affine(
        a * next.a + c * next.b,
        b * next.a + d * next.b,
        a * next.c + c * next.d,
        b * next.c + d * next.d,
        a * next.e + c * next.f + e,
        b * next.e + d * next.f + f,
      );

  Offset apply(Offset p) =>
      Offset(a * p.dx + c * p.dy + e, b * p.dx + d * p.dy + f);

  /// How much it enlarges (the strokes it draws only turn, resize evenly
  /// and mirror).
  double get scale => math.sqrt((a * d - b * c).abs());

  /// The box around [r] once placed.
  Rect box(Rect r) {
    final corners = [
      apply(r.topLeft),
      apply(r.topRight),
      apply(r.bottomRight),
      apply(r.bottomLeft),
    ];
    var out = Rect.fromPoints(corners.first, corners.first);
    for (final p in corners) {
      out = out.expandToInclude(Rect.fromPoints(p, p));
    }
    return out;
  }

  Float64List get matrix4 => Float64List.fromList(
      [a, b, 0, 0, c, d, 0, 0, 0, 0, 1, 0, e, f, 0, 1]);

  String get svg => 'matrix(${svgNumber4(a)} ${svgNumber4(b)} '
      '${svgNumber4(c)} ${svgNumber4(d)} ${svgNumber(e)} ${svgNumber(f)})';

  /// Turning and scaling need more digits than positions.
  static String svgNumber4(double v) {
    final s = v.toStringAsFixed(4);
    final trimmed = s.contains('.')
        ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')
        : s;
    return trimmed == '-0' ? '0' : trimmed;
  }
}

class _Save {
  _Save(this.ctm, this.group, this.maskInk, this.layer);

  final _Affine ctm;
  final _Group group;
  final Color? maskInk;
  final _Layer? layer;
}

class _Layer {
  _Layer(this.mode, this.alpha, this.region, this.label);

  final BlendMode mode;
  final double alpha;

  /// Where the layer is, as path data on the paper.
  final String? region;
  final String? label;
  final content = _Group();
}

sealed class _Node {
  void write(StringBuffer out);
}

class _Markup extends _Node {
  _Markup(this.text);

  final String text;

  @override
  void write(StringBuffer out) => out
    ..write(text)
    ..write('\n');
}

class _Group extends _Node {
  _Group({this.label, this.opacity, this.isolate = false, this.mask, this.clip});

  final String? label;
  final double? opacity;
  final bool isolate;
  final _MaskDef? mask;
  final String? clip;
  final children = <_Node>[];
  String? _blend;

  /// Whether something in it mixes with what's under it.
  bool blended = false;

  void add(_Node node, {String? blend}) {
    if (blend != null) {
      blended = true;
      if (node is! _Group || node._blend != null) {
        node = _Group()..children.add(node);
      }
      node._blend = blend;
    }
    children.add(node);
  }

  @override
  void write(StringBuffer out) {
    out.write('<g');
    if (label != null) {
      out.write(' inkscape:groupmode="layer" inkscape:label="${xmlText(label!)}"');
    }
    if (opacity != null) out.write(' opacity="${svgNumber(opacity!)}"');
    final style = [
      if (_blend != null) 'mix-blend-mode:$_blend',
      if (isolate) 'isolation:isolate',
    ];
    if (style.isNotEmpty) out.write(' style="${style.join(';')}"');
    if (mask != null) out.write(' mask="url(#${mask!.id})"');
    if (clip != null) out.write(' clip-path="url(#$clip)"');
    out.write('>\n');
    for (final c in children) {
      c.write(out);
    }
    out.write('</g>\n');
  }
}

class _MaskDef extends _Node {
  _MaskDef(this.id, this.area, {required this.erases});

  final String id;
  final Rect area;

  /// Whether it takes paint away (the eraser) rather than keeping it.
  final bool erases;
  final content = <_Node>[];

  @override
  void write(StringBuffer out) {
    out.write('<mask id="$id" maskUnits="userSpaceOnUse" '
        'x="${svgNumber(area.left)}" y="${svgNumber(area.top)}" '
        'width="${svgNumber(area.width)}" height="${svgNumber(area.height)}">\n');
    for (final c in content) {
      c.write(out);
    }
    out.write('</mask>\n');
  }
}
