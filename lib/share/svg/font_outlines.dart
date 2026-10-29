import 'dart:typed_data';
import 'dart:ui';

/// The letter shapes of a TrueType font, read straight from its file, so
/// text can be exported as outlines that look the same everywhere (no font
/// needs to be installed to open the picture).
class FontOutlines {
  FontOutlines._(this._data, this._tables, this.unitsPerEm, this._longLoca,
      this._numGlyphs);

  /// The font in [data], or null when it isn't a TrueType font with glyph
  /// outlines.
  static FontOutlines? parse(ByteData data) {
    try {
      final count = data.getUint16(4);
      final tables = <String, int>{};
      for (var i = 0; i < count; i++) {
        final at = 12 + 16 * i;
        final tag = String.fromCharCodes([
          for (var k = 0; k < 4; k++) data.getUint8(at + k),
        ]);
        tables[tag] = data.getUint32(at + 8);
      }
      for (final need in ['head', 'cmap', 'loca', 'glyf', 'maxp']) {
        if (!tables.containsKey(need)) return null;
      }
      final head = tables['head']!;
      final font = FontOutlines._(
        data,
        tables,
        data.getUint16(head + 18),
        data.getInt16(head + 50) == 1,
        data.getUint16(tables['maxp']! + 4),
      );
      font._readCmap();
      return font;
    } on RangeError {
      return null;
    }
  }

  final ByteData _data;
  final Map<String, int> _tables;

  /// Font units per em: a letter at font size `s` is scaled by
  /// `s / unitsPerEm`.
  final int unitsPerEm;
  final bool _longLoca;
  final int _numGlyphs;

  // The character map, as ranges of code points.
  final _ranges = <_Range>[];
  final _glyphs = <int, int>{};
  final _shapes = <int, List<List<_Point>>>{};

  /// Where an underline goes and how thick it is, in font units (up is
  /// positive); null when the font doesn't say.
  ({double position, double thickness})? get underline {
    final post = _tables['post'];
    if (post == null) return null;
    return (
      position: _data.getInt16(post + 8).toDouble(),
      thickness: _data.getInt16(post + 10).toDouble(),
    );
  }

  /// Where a line through the text goes and how thick it is, in font units.
  ({double position, double thickness})? get strikeout {
    final os2 = _tables['OS/2'];
    if (os2 == null) return null;
    return (
      position: _data.getInt16(os2 + 28).toDouble(),
      thickness: _data.getInt16(os2 + 26).toDouble(),
    );
  }

  /// Whether the font has a letter for [codePoint].
  bool has(int codePoint) => _glyphFor(codePoint) != 0;

  /// The outline of [codePoint] as SVG path data, each point in font
  /// units (y up) placed by [place]; null when the font has no letter for
  /// it, and empty for one with no shape (a space).
  String? outline(int codePoint, Offset Function(double x, double y) place) {
    final glyph = _glyphFor(codePoint);
    if (glyph == 0) return null;
    final out = StringBuffer();
    for (final contour in _shape(glyph, 0)) {
      _writeContour(out, contour, place);
    }
    return out.toString();
  }

  void _readCmap() {
    final cmap = _tables['cmap']!;
    final count = _data.getUint16(cmap + 2);
    int? best, bestRank;
    for (var i = 0; i < count; i++) {
      final at = cmap + 4 + 8 * i;
      final platform = _data.getUint16(at);
      final encoding = _data.getUint16(at + 2);
      final offset = cmap + _data.getUint32(at + 4);
      final format = _data.getUint16(offset);
      // Prefer the full Unicode map (format 12), then the basic one.
      final rank = switch ((platform, encoding, format)) {
        (3, 10, 12) || (0, _, 12) => 0,
        (3, 1, 4) || (0, _, 4) => 1,
        _ => null,
      };
      if (rank != null && (bestRank == null || rank < bestRank)) {
        best = offset;
        bestRank = rank;
      }
    }
    if (best == null) return;
    if (_data.getUint16(best) == 12) {
      final groups = _data.getUint32(best + 12);
      for (var g = 0; g < groups; g++) {
        final at = best + 16 + 12 * g;
        _ranges.add(_Range.sequential(_data.getUint32(at),
            _data.getUint32(at + 4), _data.getUint32(at + 8)));
      }
      return;
    }
    final segments = _data.getUint16(best + 6) ~/ 2;
    final ends = best + 14;
    final starts = ends + 2 * segments + 2;
    final deltas = starts + 2 * segments;
    final rangeOffsets = deltas + 2 * segments;
    for (var s = 0; s < segments; s++) {
      final end = _data.getUint16(ends + 2 * s);
      final start = _data.getUint16(starts + 2 * s);
      if (start > end || start == 0xFFFF) continue;
      _ranges.add(_Range.format4(start, end, _data.getInt16(deltas + 2 * s),
          _data.getUint16(rangeOffsets + 2 * s), rangeOffsets + 2 * s));
    }
  }

  int _glyphFor(int codePoint) => _glyphs[codePoint] ??= () {
        for (final r in _ranges) {
          if (codePoint < r.start || codePoint > r.end) continue;
          final glyph = r.glyphOf(codePoint, _data);
          return glyph < _numGlyphs ? glyph : 0;
        }
        return 0;
      }();

  /// A glyph's closed outlines, each a list of on- and off-curve points.
  List<List<_Point>> _shape(int glyph, int depth) =>
      _shapes[glyph] ??= _readShape(glyph, depth);

  List<List<_Point>> _readShape(int glyph, int depth) {
    final loca = _tables['loca']!;
    final start = _longLoca
        ? _data.getUint32(loca + 4 * glyph)
        : _data.getUint16(loca + 2 * glyph) * 2;
    final end = _longLoca
        ? _data.getUint32(loca + 4 * glyph + 4)
        : _data.getUint16(loca + 2 * glyph + 2) * 2;
    if (end <= start) return const [];
    final at = _tables['glyf']! + start;
    final contours = _data.getInt16(at);
    if (contours >= 0) return _readSimple(at, contours);
    return depth > 8 ? const [] : _readComposite(at, depth);
  }

  List<List<_Point>> _readSimple(int at, int contours) {
    var p = at + 10;
    final ends = [
      for (var i = 0; i < contours; i++) _data.getUint16(p + 2 * i),
    ];
    p += 2 * contours;
    if (ends.isEmpty) return const [];
    final count = ends.last + 1;
    p += 2 + _data.getUint16(p); // Skip the hinting instructions.
    final flags = Uint8List(count);
    for (var i = 0; i < count;) {
      final f = _data.getUint8(p++);
      flags[i++] = f;
      if (f & 8 != 0) {
        for (var r = _data.getUint8(p++); r > 0 && i < count; r--) {
          flags[i++] = f;
        }
      }
    }
    final xs = Int32List(count), ys = Int32List(count);
    for (final (coords, short, same) in [(xs, 2, 16), (ys, 4, 32)]) {
      var v = 0;
      for (var i = 0; i < count; i++) {
        final f = flags[i];
        if (f & short != 0) {
          final d = _data.getUint8(p++);
          v += f & same != 0 ? d : -d;
        } else if (f & same == 0) {
          v += _data.getInt16(p);
          p += 2;
        }
        coords[i] = v;
      }
    }
    final out = <List<_Point>>[];
    var first = 0;
    for (final last in ends) {
      out.add([
        for (var i = first; i <= last; i++)
          _Point(xs[i].toDouble(), ys[i].toDouble(), flags[i] & 1 != 0),
      ]);
      first = last + 1;
    }
    return out;
  }

  List<List<_Point>> _readComposite(int at, int depth) {
    final out = <List<_Point>>[];
    var p = at + 10;
    int flags;
    do {
      flags = _data.getUint16(p);
      final glyph = _data.getUint16(p + 2);
      p += 4;
      double dx, dy;
      if (flags & 1 != 0) {
        dx = _data.getInt16(p).toDouble();
        dy = _data.getInt16(p + 2).toDouble();
        p += 4;
      } else {
        dx = _data.getInt8(p).toDouble();
        dy = _data.getInt8(p + 1).toDouble();
        p += 2;
      }
      // Parts placed by matching points are rare; they stay where they are.
      if (flags & 2 == 0) dx = dy = 0;
      double f2dot14(int at) => _data.getInt16(at) / 16384;
      var (a, b, c, d) = (1.0, 0.0, 0.0, 1.0);
      if (flags & 8 != 0) {
        a = d = f2dot14(p);
        p += 2;
      } else if (flags & 0x40 != 0) {
        a = f2dot14(p);
        d = f2dot14(p + 2);
        p += 4;
      } else if (flags & 0x80 != 0) {
        a = f2dot14(p);
        b = f2dot14(p + 2);
        c = f2dot14(p + 4);
        d = f2dot14(p + 6);
        p += 8;
      }
      for (final contour in _shape(glyph, depth + 1)) {
        out.add([
          for (final q in contour)
            _Point(a * q.x + c * q.y + dx, b * q.x + d * q.y + dy, q.on),
        ]);
      }
    } while (flags & 0x20 != 0);
    return out;
  }

  /// One closed outline: straight lines between on-curve points, curves
  /// bent toward the off-curve ones (two off-curve points in a row have an
  /// on-curve point halfway between them).
  static void _writeContour(StringBuffer out, List<_Point> pts,
      Offset Function(double x, double y) place) {
    if (pts.length < 2) return;
    _Point mid(_Point a, _Point b) =>
        _Point((a.x + b.x) / 2, (a.y + b.y) / 2, true);
    final startIndex = pts.indexWhere((q) => q.on);
    final _Point start;
    final List<_Point> rest;
    if (startIndex >= 0) {
      start = pts[startIndex];
      rest = [...pts.sublist(startIndex + 1), ...pts.sublist(0, startIndex)];
    } else {
      start = mid(pts.last, pts.first);
      rest = pts;
    }
    void point(String command, _Point q) {
      final o = place(q.x, q.y);
      out
        ..write(command)
        ..write(svgNumber(o.dx))
        ..write(' ')
        ..write(svgNumber(o.dy));
    }

    point('M', start);
    _Point? control;
    for (final q in [...rest, start]) {
      if (q.on) {
        if (control == null) {
          point('L', q);
        } else {
          point('Q', control);
          point(' ', q);
          control = null;
        }
      } else {
        if (control != null) {
          point('Q', control);
          point(' ', mid(control, q));
        }
        control = q;
      }
    }
    out.write('Z');
  }
}

class _Point {
  const _Point(this.x, this.y, this.on);

  final double x, y;
  final bool on;
}

/// A run of code points in a font's character map.
class _Range {
  _Range.sequential(this.start, this.end, int firstGlyph)
      : _delta = firstGlyph - start,
        _rangeOffset = 0,
        _rangeOffsetAt = 0,
        _sequential = true;

  _Range.format4(this.start, this.end, this._delta, this._rangeOffset,
      this._rangeOffsetAt)
      : _sequential = false;

  final int start, end;
  final int _delta, _rangeOffset, _rangeOffsetAt;
  final bool _sequential;

  int glyphOf(int codePoint, ByteData data) {
    if (_sequential) return codePoint + _delta;
    if (_rangeOffset == 0) return (codePoint + _delta) & 0xFFFF;
    final at = _rangeOffsetAt + _rangeOffset + 2 * (codePoint - start);
    final glyph = data.getUint16(at);
    return glyph == 0 ? 0 : (glyph + _delta) & 0xFFFF;
  }
}

/// [v] as short as an SVG number can be, to a hundredth.
String svgNumber(double v) {
  final hundredths = (v * 100).round();
  if (hundredths == 0) return '0';
  final sign = hundredths < 0 ? '-' : '';
  final abs = hundredths.abs();
  final whole = abs ~/ 100, frac = abs % 100;
  if (frac == 0) return '$sign$whole';
  if (frac % 10 == 0) return '$sign$whole.${frac ~/ 10}';
  return '$sign$whole.${frac.toString().padLeft(2, '0')}';
}
