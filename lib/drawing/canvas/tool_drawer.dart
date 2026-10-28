import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../l10n.dart';
import '../../settings.dart';
import '../../skill_level.dart';
import '../../theme/cute_theme.dart';
import '../stroke.dart';
import 'brush_tile.dart';
import 'canvas_keys.dart';
import 'color_widgets.dart';
import 'palette_strip.dart';
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
                    ),
                    if (!locked)
                      IconButton(
                        tooltip: s.closeTools,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: onClose,
                      ),
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
    final brushes = settings.level.brushes;
    final everyday = [
      for (final b in brushes)
        if (SkillLevel.beginner.allows(b)) b,
    ];
    final more = [
      for (final b in brushes)
        if (!SkillLevel.beginner.allows(b)) b,
    ];
    Widget tile(BrushType b) => BrushTile(
      brush: b,
      label: s.brushName(b),
      selected: brush == b,
      onTap: () => settings.brush = b,
    );

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

    return ListView(
      key: CanvasKeys.toolsList,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
      children: [
        ...section(ToolSection.brushes, s.tools, [
          for (final b in everyday) tile(b),
        ], chosen: everyday.contains(brush) ? s.brushName(brush) : null),
        if (more.isNotEmpty)
          ...section(ToolSection.moreBrushes, s.moreBrushes, [
            for (final b in more) tile(b),
          ], chosen: more.contains(brush) ? s.brushName(brush) : null),
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
                  child: Slider(
                    min: 0,
                    max: AppSettings.maxFillGap.toDouble(),
                    divisions: AppSettings.maxFillGap,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    value: settings.fillGap.toDouble(),
                    label: settings.fillGap.toString(),
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
                  child: Slider(
                    min: 1,
                    max: 60,
                    divisions: 59,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    value: settings.size.clamp(1, 60),
                    label: settings.size.round().toString(),
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
                  child: Slider(
                    min: AppSettings.minOpacity,
                    max: 1,
                    divisions: 19,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    value: settings.opacity,
                    label: s.percent(settings.opacity),
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
            [
              ToolChip(
                icon: AppTheme.shapeIcon(null),
                label: s.shapeName(null),
                selected: settings.shape == null && !settings.freeShape,
                onTap: () => settings.shape = null,
              ),
              if (settings.level.freeShape)
                ToolChip(
                  icon: Icons.format_shapes_rounded,
                  label: s.freeShape,
                  selected: settings.freeShape,
                  onTap: () => settings.freeShape = true,
                ),
              for (final shape in ShapeKind.values)
                ToolChip(
                  icon: AppTheme.shapeIcon(shape),
                  label: s.shapeName(shape),
                  selected: settings.shape == shape,
                  onTap: () => settings.shape = shape,
                ),
              ToolChip(
                icon: Icons.format_color_fill_rounded,
                label: s.fillShape,
                selected: settings.fill,
                // Only closed shapes can be filled.
                enabled: settings.shape?.closed ?? false,
                onTap: () => settings.fill = !settings.fill,
              ),
            ],
            chosen: settings.freeShape
                ? s.freeShape
                : settings.shape == null
                ? null
                : s.shapeName(settings.shape),
          ),
        if (brush == BrushType.stamp)
          ...section(ToolSection.stamps, s.brushName(BrushType.stamp), [
            for (final shape in StampShape.values)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(
                    AppTheme.stampIcon(shape),
                    size: 18,
                    color: settings.stamp == shape
                        ? cute.onColor(accent)
                        : accent,
                  ),
                  label: Text(s.stampName(shape)),
                  selected: settings.stamp == shape,
                  showCheckmark: false,
                  selectedColor: accent,
                  labelStyle: TextStyle(
                    color: settings.stamp == shape
                        ? cute.onColor(accent)
                        : cute.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => settings.stamp = shape,
                ),
              ),
          ], chosen: s.stampName(settings.stamp)),
        if (settings.level.gradients &&
            brush.usesColor &&
            brush.kind == BrushKind.outline)
          ...section(
            ToolSection.gradient,
            s.gradient,
            [
              for (final g in GradientStyle.values)
                ToolChip(
                  icon: AppTheme.gradientIcon(g),
                  label: s.gradientName(g),
                  selected: settings.gradient == g,
                  onTap: () => settings.gradient = g,
                ),
            ],
            chosen: settings.gradient == GradientStyle.none
                ? null
                : s.gradientName(settings.gradient),
          ),
        if (settings.level.lightAndShadow && brush.usesColor)
          ...section(
            ToolSection.lightAndShadow,
            s.lightAndShadow,
            [
              for (final b in AppTheme.blends)
                ToolChip(
                  icon: AppTheme.blendIcon(b),
                  label: s.blendName(b),
                  selected: settings.blend == b,
                  onTap: () => settings.blend = b,
                ),
            ],
            chosen: settings.blend == StrokeBlend.normal
                ? null
                : s.blendName(settings.blend),
          ),
        if (settings.level.textures && brush.usesTexture)
          ...section(
            ToolSection.texture,
            s.texture,
            [
              for (final t in StrokeTexture.values)
                ToolChip(
                  icon: AppTheme.textureIcon(t),
                  label: s.textureName(t),
                  selected: settings.texture == t,
                  onTap: () => settings.texture = t,
                ),
            ],
            chosen: settings.texture == StrokeTexture.none
                ? null
                : s.textureName(settings.texture),
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

/// A shape or option chip. Colors come from the theme's contrast-checked
/// primary pair.
class ToolChip extends StatelessWidget {
  const ToolChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
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
      child: ChoiceChip(
        avatar: Icon(icon, size: 18, color: fg),
        label: Text(label),
        selected: selected && enabled,
        showCheckmark: false,
        selectedColor: scheme.primary,
        backgroundColor: scheme.surface,
        side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
        labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
        onSelected: enabled ? (_) => onTap() : null,
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
