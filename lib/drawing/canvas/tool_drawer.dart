import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../l10n.dart';
import '../../settings.dart';
import '../../theme/cute_theme.dart';
import '../../widgets/liquid_slider.dart';
import '../../widgets/press_bounce.dart';
import '../stroke.dart';
import 'brush_tile.dart';
import 'canvas_keys.dart';
import 'add_tools_sheet.dart';
import 'color_widgets.dart';
import 'my_brushes.dart';
import 'palette_strip.dart';
import 'tool_catalog.dart';
import 'tool_section.dart';

/// The tools drawer that slides in from the side the tools button is on.
class ToolDrawer extends StatelessWidget {
  const ToolDrawer({
    required this.settings,
    required this.palette,
    required this.fromLeft,
    required this.locked,
    required this.pinned,
    required this.onToggleLock,
    required this.onClose,
    required this.onMoreColors,
    required this.onDrag,
    required this.onDragEnd,
    super.key,
  });

  final AppSettings settings;
  final List<Color> palette;
  final bool fromLeft;

  /// Pinned beside the paper (no close button, no swipe to close).
  final bool locked;

  /// Whether the palette is pinned (the 📌 shows it), also when this is
  /// the full drawer opened from the strip on a phone.
  final bool pinned;
  final VoidCallback onToggleLock;
  final VoidCallback onClose;
  final VoidCallback onMoreColors;
  final ValueChanged<double> onDrag;
  final ValueChanged<double> onDragEnd;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return Material(
      elevation: 16,
      shadowColor: cute.spec.primary.withValues(alpha: 0.4),
      color: Theme.of(context).colorScheme.surface,
      // Rounded on the side facing the paper.
      shape: RoundedRectangleBorder(
        borderRadius: fromLeft
            ? BorderRadius.horizontal(right: Radius.circular(cute.radius))
            : BorderRadius.horizontal(left: Radius.circular(cute.radius)),
      ),
      child: SafeArea(
        left: fromLeft,
        right: !fromLeft,
        child: Column(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) => onDrag(d.primaryDelta ?? 0),
              onHorizontalDragEnd: (d) => onDragEnd(d.primaryVelocity ?? 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 4, 0),
                child: Row(
                  children: [
                    Icon(Icons.palette_rounded, color: cute.spec.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        s.toolsTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: pinned ? s.unpinPalette : s.pinPalette,
                      icon: Icon(
                        pinned
                            ? Icons.push_pin_rounded
                            : Icons.push_pin_outlined,
                      ),
                      color: pinned ? cute.spec.primary : null,
                      isSelected: pinned,
                      onPressed: onToggleLock,
                    ).bouncy(),
                    if (!locked)
                      IconButton(
                        tooltip: s.closeTools,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onClose,
                      ).bouncy(),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ToolPanel(
                settings: settings,
                palette: palette,
                onMoreColors: onMoreColors,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brushes (the everyday ones, then the rest of the level's), colors with
/// size and opacity right under them, shapes, stamp shapes, and the looks
/// (gradient, light and shadow, texture), each a [ToolSection], in a
/// scrolling column inside the tools drawer.
class ToolPanel extends StatelessWidget {
  const ToolPanel({
    super.key,
    required this.settings,
    required this.palette,
    required this.onMoreColors,
  });

  final AppSettings settings;
  final List<Color> palette;
  final VoidCallback onMoreColors;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    final brush = settings.brush;
    final accent = AppTheme.brushColor(brush);
    final custom = [
      for (final c in settings.customColors)
        if (!palette.any((p) => p.toARGB32() == c.toARGB32())) c,
    ];
    /// [section]'s heading and, while it's open, its [items]. While it's
    /// closed the heading shows what's [chosen] in it (or a [swatch]).
    List<Widget> section(
      ToolSection section,
      String title,
      List<Widget> items, {
      String? chosen,
      Color? swatch,
    }) {
      final open = section.isOpen(settings);
      return [
        SectionHeading(
          key: ValueKey('section.${section.name}'),
          title: title,
          open: open,
          chosen: chosen,
          swatch: swatch,
          onTap: () => settings.setSectionOpen(section.name, !open),
        ),
        if (open) Wrap(spacing: 0, runSpacing: 6, children: items),
      ];
    }

    /// [group]'s options the drawer shows (the basic ones, the added ones
    /// and the one chosen), then [extra], then a chip to add more.
    final added = settings.addedTools;
    List<Widget> options(ToolGroup group, {List<Widget> extra = const []}) => [
          for (final o in ToolCatalog.options(group, settings, s))
            if (o.shownWith(added))
              ToolChip(
                glyph: o.glyph,
                label: o.label,
                selected: o.selected,
                onTap: o.onSelect,
              ),
          ...extra,
          AddToolChip(
            group: group,
            onTap: () => showAddToolsSheet(context, settings, first: group),
          ),
        ];

    /// The brushes or helpers the drawer shows, as round buttons, then
    /// [extra] and a chip to add more.
    List<Widget> tiles(ToolGroup group, {List<Widget> extra = const []}) => [
          for (final o in ToolCatalog.options(group, settings, s))
            if (o.shownWith(added))
              BrushTile(
                brush: o.brush!,
                label: o.label,
                selected: o.selected,
                onTap: o.onSelect,
              ),
          ...extra,
          Padding(
            padding: const EdgeInsets.only(top: 14, left: 4),
            child: AddToolChip(
              group: group,
              onTap: () => showAddToolsSheet(context, settings, first: group),
            ),
          ),
        ];
    String? chosenIn(List<BrushType> list) =>
        list.contains(brush) ? s.brushName(brush) : null;
    // 我的画笔 the level can use, after the brushes.
    final presets = [
      for (final p in settings.brushPresets)
        if (settings.level.allows(p.brush)) p,
    ];
    final preset = presets.where(settings.isPreset).firstOrNull;

    return ListView(
      key: CanvasKeys.toolsList,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      children: [
        ...section(
          ToolSection.brushes,
          s.tools,
          tiles(ToolGroup.brushes, extra: [
            for (final p in presets)
              BrushTile(
                key: ValueKey('preset.${p.id}'),
                brush: p.brush,
                label: p.name,
                dot: p.brush.usesColor ? p.color : null,
                selected: p == preset,
                onTap: () => settings.usePreset(p),
                onLongPress: () => deleteMyBrush(context, settings, p),
              ),
          ]),
          chosen: preset?.name ?? chosenIn(ToolCatalog.brushes),
        ),
        // Saving the brush in use as one's own, right under the brushes.
        if (ToolSection.brushes.isOpen(settings) && !brush.drawsNothing &&
            ToolCatalog.brushes.contains(brush))
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SaveBrushChip(settings: settings),
            ),
          ),
        ...section(
          ToolSection.helpers,
          s.helpers,
          tiles(ToolGroup.helpers),
          chosen: chosenIn(ToolCatalog.helpers),
        ),
        // How to use the tool just picked, right under it.
        if (switch (brush) {
              BrushType.text => s.textHint,
              BrushType.move => s.moveHint,
              BrushType.picker => s.pickerHint,
              BrushType.bucket => s.bucketHint,
              BrushType.eraser => s.eraserHint,
              BrushType.smudge => s.smudgeHint,
              _ => null,
            }
            case final hint?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 4),
                Icon(Icons.touch_app_rounded, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(color: cute.ink, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        // Only the options that apply: the eraser, rainbow and move tools
        // ignore colors; the eraser, text and move tools draw no shapes.
        if (brush.usesColor)
          ...section(ToolSection.colors, s.colors, [
            MoreColorsButton(tooltip: s.moreColors, onTap: onMoreColors),
            for (final c in [...custom, ...palette])
              Swatch(
                color: c,
                label: s.colorLabel(c),
                selected: c.toARGB32() == settings.color.toARGB32(),
                onTap: () => settings.color = c,
              ),
          ], swatch: settings.color),
        // Size and opacity right under the colors, always in reach. They
        // mean nothing to the move tool and the picker.
        if (!brush.drawsNothing) ...[
          const SizedBox(height: 8),
          // The paint bucket has no size; it can close gaps in lines.
          if (brush == BrushType.bucket && settings.level.freeShape)
            Row(
              children: [
                SliderLabel(
                  icon: Icons.join_full_rounded,
                  tooltip: s.fillGap,
                  color: accent,
                ),
                Expanded(
                  child: LiquidSlider(
                    min: 0,
                    max: AppSettings.maxFillGap.toDouble(),
                    divisions: AppSettings.maxFillGap,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    value: settings.fillGap.toDouble(),
                    label: (v) => v.round().toString(),
                    semanticFormatterCallback: (v) =>
                        '${s.fillGap} ${v.round()}',
                    activeColor: accent,
                    onChanged: (v) => settings.fillGap = v.round(),
                  ),
                ),
              ],
            ),
          if (brush.usesSize)
            Row(
              children: [
                SliderLabel(
                  icon: Icons.line_weight_rounded,
                  tooltip: s.brushSize,
                  color: accent,
                ),
                Expanded(
                  child: LiquidSlider(
                    min: 1,
                    max: 60,
                    divisions: 59,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    value: settings.size.clamp(1, 60),
                    label: (v) => v.round().toString(),
                    semanticFormatterCallback: (v) =>
                        '${s.brushSize} ${v.round()}',
                    activeColor: accent,
                    onChanged: (v) => settings.size = v,
                  ),
                ),
                SizePreview(settings: settings),
              ],
            ),
          if (settings.level.opacity)
            Row(
              children: [
                SliderLabel(
                  icon: Icons.opacity_rounded,
                  tooltip: s.opacity,
                  color: accent,
                ),
                Expanded(
                  child: LiquidSlider(
                    min: AppSettings.minOpacity,
                    max: 1,
                    divisions: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    value: settings.opacity,
                    label: s.percent,
                    semanticFormatterCallback: (v) =>
                        '${s.opacity} ${s.percent(v)}',
                    activeColor: accent,
                    onChanged: (v) => settings.opacity = v,
                  ),
                ),
              ],
            ),
        ],
        if (brush.usesShapes)
          ...section(
            ToolSection.shapes,
            s.shapes,
            options(ToolGroup.shapes, extra: [
              ToolChip(
                icon: Icons.format_color_fill_rounded,
                label: s.fillShape,
                selected: settings.fill,
                // Only closed shapes can be filled.
                enabled: settings.shape?.closed ?? false,
                onTap: () => settings.fill = !settings.fill,
              ),
            ]),
            chosen: settings.freeShape
                ? s.freeShape
                : settings.shape == null
                ? null
                : s.shapeName(settings.shape),
          ),
        // Always there (not only with the stamp brush): a stamp picked here
        // picks the stamp brush.
        if (settings.level.allows(BrushType.stamp))
          ...section(ToolSection.stamps, s.brushName(BrushType.stamp),
              options(ToolGroup.stamps),
              chosen: brush == BrushType.stamp
                  ? s.stampName(settings.stamp)
                  : null),
        if (settings.level.gradients &&
            brush.usesColor &&
            brush.kind == BrushKind.outline)
          ...section(
            ToolSection.gradient,
            s.gradient,
            options(ToolGroup.gradients),
            chosen: settings.gradient == GradientStyle.none
                ? null
                : s.gradientName(settings.gradient),
          ),
        if (settings.level.lightAndShadow && brush.usesColor)
          ...section(
            ToolSection.lightAndShadow,
            s.lightAndShadow,
            options(ToolGroup.blends),
            chosen: settings.blend == StrokeBlend.normal
                ? null
                : s.blendName(settings.blend),
          ),
        if (settings.level.textures && brush.usesTexture)
          ...section(
            ToolSection.texture,
            s.texture,
            options(ToolGroup.textures),
            chosen: settings.texture == StrokeTexture.none
                ? null
                : s.textureName(settings.texture),
          ),
        // More shapes, stamps, gradients, light and textures, all at once.
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: OutlinedButton.icon(
            key: const ValueKey('addToolsButton'),
            icon: const Icon(Icons.add_box_rounded),
            label: Text(s.addTools),
            onPressed: () => showAddToolsSheet(context, settings),
          ).bouncy(),
        ),
        const Divider(height: 28),
        Row(
          children: [
            const SizedBox(width: 4),
            Icon(Icons.pinch_rounded, color: cute.spec.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.pinchHint,
                style: TextStyle(color: cute.ink, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A shape or option chip, with an [icon] or a [glyph] (a little picture
/// in the chip's text color). Colors come from the theme's contrast-checked
/// primary pair.
class ToolChip extends StatelessWidget {
  const ToolChip({
    super.key,
    this.icon,
    this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  }) : assert(icon != null || glyph != null);

  final IconData? icon;
  final Widget Function(Color color)? glyph;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onPrimary : cute.ink;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: PressBounce(
        enabled: enabled,
        child: ChoiceChip(
          avatar: glyph?.call(fg) ?? Icon(icon, size: 18, color: fg),
          label: Text(label),
          selected: selected && enabled,
          showCheckmark: false,
          selectedColor: scheme.primary,
          backgroundColor: scheme.surface,
          side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
          labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
          onSelected: enabled ? (_) => onTap() : null,
        ),
      ),
    );
  }
}

class SliderLabel extends StatelessWidget {
  const SliderLabel({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
  });

  final IconData icon;
  final String tooltip;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 22),
    ),
  );
}

/// Shows how big, what color and how see-through the next stroke will be,
/// with its gradient and soft edge.
class SizePreview extends StatelessWidget {
  const SizePreview({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final brush = settings.brush;
    final d = (settings.size * brush.sizeFactor).clamp(4, 36).toDouble();
    final Color fill = switch (brush) {
      BrushType.eraser => Colors.white,
      BrushType.rainbow => Colors.white,
      BrushType.smudge => Colors.grey,
      _ => settings.color,
    };
    final alpha = settings.opacity * brush.opacity;
    final gradient = brush.usesColor && brush.kind == BrushKind.outline
        ? settings.gradient.forColor(settings.color)
        : null;
    Widget dot = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        color: fill.withValues(alpha: alpha),
        gradient: brush == BrushType.rainbow
            ? SweepGradient(
                colors: [
                  for (var h = 0; h <= 360; h += 60)
                    HSVColor.fromAHSV(
                      settings.opacity,
                      h % 360,
                      0.6,
                      0.97,
                    ).toColor(),
                ],
              )
            : gradient == null
            ? null
            : _boxGradient(gradient, alpha),
        shape: BoxShape.circle,
        border: brush.blur > 0 ? null : Border.all(color: Colors.black26),
      ),
    );
    if (brush.blur > 0) {
      final sigma = d * brush.blur / 2;
      dot = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: dot,
      );
    }
    return SizedBox(width: 44, height: 48, child: Center(child: dot));
  }

  /// [g] as a box decoration's gradient, faded by [alpha].
  static Gradient _boxGradient(StrokeGradient g, double alpha) {
    Alignment at(Offset f) => Alignment(f.dx * 2 - 1, f.dy * 2 - 1);
    final colors = [for (final c in g.colors) c.withValues(alpha: c.a * alpha)];
    return g.radial
        ? RadialGradient(
            center: at(g.from),
            radius: (g.to - g.from).distance,
            colors: colors,
            stops: g.stops,
          )
        : LinearGradient(
            begin: at(g.from),
            end: at(g.to),
            colors: colors,
            stops: g.stops,
          );
  }
}

/// The tools drawer sliding in over the paper from the side the tools
/// button is on, over a dimmed backdrop that closes it. [progress] is the
/// drawer's own animation (0 hidden, 1 open), which dragging its header
/// moves directly.
class SlidingToolDrawer extends StatelessWidget {
  const SlidingToolDrawer({
    super.key,
    required this.progress,
    required this.slide,
    required this.width,
    required this.settings,
    required this.pinned,
    required this.onOpen,
    required this.onClose,
    required this.onTogglePin,
    required this.onMoreColors,
  });

  final AnimationController progress;

  /// [progress] with easing.
  final Animation<double> slide;
  final double width;
  final AppSettings settings;

  /// Whether the palette is pinned (an upright phone's strip "More" opens
  /// this drawer).
  final bool pinned;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final VoidCallback onTogglePin;
  final VoidCallback onMoreColors;

  @override
  Widget build(BuildContext context) {
    final fromLeft = settings.toolsCorner.isLeft;
    return Stack(
      children: [
        Positioned.fill(
          child: FadeTransition(
            opacity: slide,
            child: ModalBarrier(
              color: Colors.black.withValues(alpha: 0.22),
              dismissible: true,
              onDismiss: onClose,
              semanticsLabel: S.of(context).closeTools,
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          left: fromLeft ? 0 : null,
          right: fromLeft ? null : 0,
          width: width,
          child: SlideTransition(
            position: Tween(
              begin: Offset(fromLeft ? -1 : 1, 0),
              end: Offset.zero,
            ).animate(slide),
            child: ToolDrawer(
              settings: settings,
              palette: AppPalette.colors,
              fromLeft: fromLeft,
              locked: false,
              pinned: pinned,
              onToggleLock: onTogglePin,
              onClose: onClose,
              onMoreColors: onMoreColors,
              // Dragging the header back toward its edge closes it.
              onDrag: (dx) => progress.value -= (fromLeft ? -dx : dx) / width,
              onDragEnd: (velocity) =>
                  (fromLeft ? -velocity : velocity) > 300 ||
                      progress.value < 0.6
                  ? onClose()
                  : onOpen(),
            ),
          ),
        ),
      ],
    );
  }
}

/// The pinned palette: beside [stage] (the paper) where there's room
/// (tablets, phones turned sideways), or a one-row strip under it on a
/// phone held upright, whose "More" slides in the full drawer.
class PinnedPaletteLayout extends StatelessWidget {
  const PinnedPaletteLayout({
    super.key,
    required this.stage,
    required this.availableWidth,
    required this.maxPanelWidth,
    required this.panelKey,
    required this.settings,
    required this.onUnpin,
    required this.onMore,
    required this.onMoreColors,
  });

  final Widget stage;
  final double availableWidth;
  final double maxPanelWidth;
  final Key panelKey;
  final AppSettings settings;
  final VoidCallback onUnpin;
  final VoidCallback onMore;
  final VoidCallback onMoreColors;

  /// Narrower than this, the palette is a strip under the paper.
  static const besideMinWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    if (availableWidth < besideMinWidth) {
      return Column(
        children: [
          Expanded(child: stage),
          PaletteStrip(
            key: panelKey,
            settings: settings,
            palette: AppPalette.colors,
            onMore: onMore,
            onUnpin: onUnpin,
          ),
        ],
      );
    }
    final fromLeft = settings.toolsCorner.isLeft;
    final panel = SizedBox(
      width: math.min(maxPanelWidth, availableWidth * 0.4),
      child: ToolDrawer(
        key: panelKey,
        settings: settings,
        palette: AppPalette.colors,
        fromLeft: fromLeft,
        locked: true,
        pinned: true,
        onToggleLock: onUnpin,
        onClose: onUnpin,
        onMoreColors: onMoreColors,
        onDrag: (_) {},
        onDragEnd: (_) {},
      ),
    );
    return Row(
      children: [
        if (fromLeft) panel,
        Expanded(child: stage),
        if (!fromLeft) panel,
      ],
    );
  }
}
