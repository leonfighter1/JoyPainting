import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../l10n.dart';
import '../../settings.dart';
import '../../skill_level.dart';
import '../stroke.dart';
import 'tool_glyphs.dart';

/// The groups of options in the tools drawer that show only their basic
/// choices until more are added with 添加工具 (see `showAddToolsSheet`).
enum ToolGroup {
  /// What paints: pens, pencils, markers and the rest.
  brushes,

  /// 小帮手: tools that aren't brushes (the eraser, the paint bucket, text,
  /// the color picker). More can join this group.
  helpers,
  shapes,
  stamps,
  gradients,
  blends,
  textures;

  String title(S s) => switch (this) {
    brushes => s.tools,
    helpers => s.helpers,
    shapes => s.shapes,
    stamps => s.brushName(BrushType.stamp),
    gradients => s.gradient,
    blends => s.lightAndShadow,
    textures => s.texture,
  };

  /// Whether [level] offers this group at all.
  bool allowedAt(SkillLevel level) => switch (this) {
    brushes || helpers || shapes || stamps => true,
    gradients => level.gradients,
    blends => level.lightAndShadow,
    textures => level.textures,
  };
}

/// One choice in a group: its name and picture, whether it's chosen now and
/// how to choose it, and whether it's a basic one that always shows.
class ToolOption {
  const ToolOption({
    required this.group,
    required this.name,
    required this.label,
    required this.glyph,
    required this.selected,
    required this.onSelect,
    this.basic = false,
    this.brush,
  });

  final ToolGroup group;
  final String name;
  final String label;

  /// The brush or helper it picks, for the drawer's round brush buttons.
  final BrushType? brush;

  /// Its picture, in the given text color.
  final Widget Function(Color color) glyph;
  final bool selected;
  final VoidCallback onSelect;
  final bool basic;

  /// How it's kept in [AppSettings.addedTools].
  String get key => '${group.name}.$name';

  /// Whether the drawer shows it: basic, added, or chosen now (say, a
  /// texture picked before it was taken out).
  bool shownWith(Set<String> added) => basic || selected || added.contains(key);
}

/// What each group offers, which choices are basic, and which levels can
/// add the rest.
abstract final class ToolCatalog {
  /// The brushes, in order; the first four are there from the start.
  static const brushes = [
    BrushType.pen,
    BrushType.pencil,
    BrushType.marker,
    BrushType.spray,
    BrushType.highlighter,
    BrushType.soft,
    BrushType.rainbow,
    BrushType.stamp,
    BrushType.smudge,
  ];
  static const basicBrushes = {
    BrushType.pen,
    BrushType.pencil,
    BrushType.marker,
    BrushType.spray,
  };

  /// The helpers, in order. The move tool has its own button at the top.
  static const helpers = [
    BrushType.eraser,
    BrushType.bucket,
    BrushType.text,
    BrushType.picker,
  ];
  static const basicHelpers = {
    BrushType.eraser,
    BrushType.bucket,
    BrushType.text,
  };

  /// With freehand, the shapes every level starts with.
  static const basicShapes = {
    ShapeKind.line,
    ShapeKind.rectangle,
    ShapeKind.ellipse,
  };

  /// Shapes that can be added from the beginner level on; the others, and
  /// free shapes, from the intermediate level.
  static const beginnerShapes = {
    ShapeKind.arrow,
    ShapeKind.triangle,
    ShapeKind.star,
    ShapeKind.heart,
    ShapeKind.cloud,
    ShapeKind.moon,
    ShapeKind.drop,
    ShapeKind.arc,
    ShapeKind.wave,
  };

  static const basicStamps = {
    StampShape.heart,
    StampShape.star,
    StampShape.flower,
  };
  static const basicGradients = {GradientStyle.none, GradientStyle.lighter};
  static const basicBlends = {StrokeBlend.normal, StrokeBlend.multiply};
  static const basicTextures = {StrokeTexture.none, StrokeTexture.paper};

  /// Every option of [group] that [settings]' level offers, in order.
  static List<ToolOption> options(ToolGroup group, AppSettings settings, S s) {
    final intermediate = settings.level.index >= SkillLevel.intermediate.index;
    ToolOption tool(BrushType b, Set<BrushType> basic) => ToolOption(
      group: group,
      name: b.name,
      label: s.brushName(b),
      glyph: (c) => Icon(AppTheme.brushIcon(b), size: 18, color: c),
      selected: settings.brush == b,
      onSelect: () => settings.brush = b,
      basic: basic.contains(b),
      brush: b,
    );
    return switch (group) {
      ToolGroup.brushes => [
        for (final b in brushes)
          if (settings.level.allows(b)) tool(b, basicBrushes),
      ],
      ToolGroup.helpers => [
        for (final b in helpers)
          if (settings.level.allows(b)) tool(b, basicHelpers),
      ],
      ToolGroup.shapes => [
        ToolOption(
          group: group,
          name: 'freehand',
          label: s.shapeName(null),
          glyph: (c) => Icon(AppTheme.shapeIcon(null), size: 18, color: c),
          selected: settings.shape == null && !settings.freeShape,
          onSelect: () => settings.shape = null,
          basic: true,
        ),
        if (settings.level.freeShape)
          ToolOption(
            group: group,
            name: 'free',
            label: s.freeShape,
            glyph: (c) => Icon(Icons.format_shapes_rounded, size: 18, color: c),
            selected: settings.freeShape,
            onSelect: () => settings.freeShape = true,
          ),
        for (final k in ShapeKind.values)
          if (basicShapes.contains(k) ||
              beginnerShapes.contains(k) ||
              intermediate)
            ToolOption(
              group: group,
              name: k.name,
              label: s.shapeName(k),
              glyph: (c) => ShapeGlyph(k, c),
              selected: settings.shape == k,
              onSelect: () => settings.shape = k,
              basic: basicShapes.contains(k),
            ),
      ],
      ToolGroup.stamps => [
        for (final st in StampShape.values)
          ToolOption(
            group: group,
            name: st.name,
            label: s.stampName(st),
            glyph: (c) => Icon(AppTheme.stampIcon(st), size: 18, color: c),
            // Picking a stamp picks the stamp brush too, so the group works
            // from any brush.
            selected:
                settings.brush == BrushType.stamp && settings.stamp == st,
            onSelect: () {
              settings.brush = BrushType.stamp;
              settings.stamp = st;
            },
            basic: basicStamps.contains(st),
          ),
      ],
      ToolGroup.gradients => [
        for (final g in GradientStyle.values)
          ToolOption(
            group: group,
            name: g.name,
            label: s.gradientName(g),
            // Gray, black or white show no gradient well: a blue instead.
            glyph: (c) => GradientGlyph(
              g,
              HSLColor.fromColor(settings.color).saturation < 0.15
                  ? const Color(0xFF3F7FD8)
                  : settings.color,
              c,
            ),
            selected: settings.gradient == g,
            onSelect: () => settings.gradient = g,
            basic: basicGradients.contains(g),
          ),
      ],
      ToolGroup.blends => [
        for (final b in StrokeBlend.values)
          ToolOption(
            group: group,
            name: b.name,
            label: s.blendName(b),
            glyph: (c) => Icon(AppTheme.blendIcon(b), size: 18, color: c),
            selected: settings.blend == b,
            onSelect: () => settings.blend = b,
            basic: basicBlends.contains(b),
          ),
      ],
      ToolGroup.textures => [
        for (final t in StrokeTexture.values)
          ToolOption(
            group: group,
            name: t.name,
            label: s.textureName(t),
            glyph: (c) => TextureGlyph(t, c),
            selected: settings.texture == t,
            onSelect: () => settings.texture = t,
            basic: basicTextures.contains(t),
          ),
      ],
    };
  }

  /// The keys of every option that can be added, at the advanced level.
  static List<String> addableKeys() => [
    for (final b in brushes)
      if (!basicBrushes.contains(b)) 'brushes.${b.name}',
    for (final b in helpers)
      if (!basicHelpers.contains(b)) 'helpers.${b.name}',
    'shapes.free',
    for (final k in ShapeKind.values)
      if (!basicShapes.contains(k)) 'shapes.${k.name}',
    for (final st in StampShape.values)
      if (!basicStamps.contains(st)) 'stamps.${st.name}',
    for (final g in GradientStyle.values)
      if (!basicGradients.contains(g)) 'gradients.${g.name}',
    for (final b in StrokeBlend.values)
      if (!basicBlends.contains(b)) 'blends.${b.name}',
    for (final t in StrokeTexture.values)
      if (!basicTextures.contains(t)) 'textures.${t.name}',
  ];
}
