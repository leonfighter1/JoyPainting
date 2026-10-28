import 'package:flutter/foundation.dart';

/// One layer of a painting. Its strokes are painted together on their own
/// sheet: an eraser on it only cuts into it, and the whole layer can be
/// hidden, locked or made see-through. Strokes name their layer
/// (`Stroke.layer`); null means the [base] layer every painting starts
/// with.
@immutable
class PaintingLayer {
  const PaintingLayer({
    required this.id,
    this.name = '',
    this.visible = true,
    this.opacity = 1,
    this.locked = false,
  });

  static const baseId = 'base';

  /// The one layer of a painting that has never had more.
  static const base = PaintingLayer(id: baseId);

  /// The most layers a painting can have.
  static const maxLayers = 10;

  final String id;

  /// Given by the user; empty shows a numbered name.
  final String name;
  final bool visible;
  final double opacity;

  /// Locked layers can't be drawn on or picked from.
  final bool locked;

  bool get isBase => id == baseId;

  PaintingLayer copyWith(
          {String? name, bool? visible, double? opacity, bool? locked}) =>
      PaintingLayer(
        id: id,
        name: name ?? this.name,
        visible: visible ?? this.visible,
        opacity: opacity ?? this.opacity,
        locked: locked ?? this.locked,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        if (name.isNotEmpty) 'name': name,
        if (!visible) 'visible': false,
        if (opacity != 1) 'opacity': (opacity * 100).round() / 100,
        if (locked) 'locked': true,
      };

  static PaintingLayer? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    return PaintingLayer(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      visible: json['visible'] as bool? ?? true,
      opacity: ((json['opacity'] as num?) ?? 1).toDouble().clamp(0, 1),
      locked: json['locked'] as bool? ?? false,
    );
  }

  /// The layers saved in a painting, bottom first: always at least the
  /// base layer, each id once. Paintings from before v5 have none saved.
  static List<PaintingLayer> listFromJson(Object? json) {
    final out = <PaintingLayer>[];
    if (json is List) {
      for (final item in json) {
        final layer = fromJson(item);
        if (layer != null && !out.any((l) => l.id == layer.id)) out.add(layer);
      }
    }
    if (!out.any((l) => l.isBase)) out.insert(0, base);
    return out;
  }

  /// Whether [layers] is just the untouched base layer, so nothing about
  /// layers needs saving.
  static bool isPlain(List<PaintingLayer> layers) =>
      layers.length == 1 && layers.single == base;

  @override
  bool operator ==(Object other) =>
      other is PaintingLayer &&
      other.id == id &&
      other.name == name &&
      other.visible == visible &&
      other.opacity == opacity &&
      other.locked == locked;

  @override
  int get hashCode => Object.hash(id, name, visible, opacity, locked);
}
