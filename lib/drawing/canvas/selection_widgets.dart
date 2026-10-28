import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../settings.dart';
import '../../theme/cute_theme.dart';
import '../stroke.dart';
import 'canvas_keys.dart';
import 'overlay_painter.dart';
import 'selection_controller.dart';
import 'color_widgets.dart';
import 'tool_drawer.dart';

/// The move tool's buttons for the selected strokes: how many are selected,
/// then copy, bigger, smaller, turn, color and delete.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    super.key,
    required this.selected,
    required this.hide,
    required this.actions,
  });

  final ValueListenable<List<Stroke>> selected;

  /// Fades away while the tools drawer is open.
  final Animation<double> hide;
  final List<(IconData, String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return ValueListenableBuilder(
      valueListenable: selected,
      builder: (context, sel, _) {
        if (sel.isEmpty) return const SizedBox.shrink();
        return AnimatedBuilder(
          animation: hide,
          builder: (context, child) => IgnorePointer(
            ignoring: hide.value > 0,
            child: Opacity(opacity: 1 - hide.value, child: child),
          ),
          child: Material(
            key: CanvasKeys.selectionBar,
            color: Theme.of(context).colorScheme.surface,
            elevation: 6,
            shadowColor: cute.spec.primary.withValues(alpha: 0.4),
            shape: StadiumBorder(
              side: BorderSide(
                color: cute.spec.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            // Scrolls sideways on narrow phones instead of shrinking the
            // buttons below their 48px tap size.
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      s.selectedCount(sel.length),
                      style: TextStyle(
                        color: cute.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  for (final (icon, label, onTap) in actions)
                    IconButton(
                      tooltip: label,
                      icon: Icon(icon),
                      color: cute.ink,
                      onPressed: onTap,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A sheet that recolors the selection and sets how see-through it is.
class SelectionStyleSheet extends StatefulWidget {
  const SelectionStyleSheet({
    super.key,
    required this.palette,
    required this.customColors,
    required this.color,
    required this.opacity,
    required this.onColor,
    required this.onMoreColors,
    required this.onOpacity,
  });

  final List<Color> palette;
  final List<Color> customColors;
  final Color color;
  final double opacity;
  final ValueChanged<Color> onColor;

  /// Opens the full picker; returns the color used, or null.
  final Future<Color?> Function() onMoreColors;
  final void Function(double opacity, {required bool recordUndo}) onOpacity;

  @override
  State<SelectionStyleSheet> createState() => _SelectionStyleSheetState();
}

class _SelectionStyleSheetState extends State<SelectionStyleSheet> {
  late Color _color = widget.color;
  late double _opacity = widget.opacity;

  /// One slider drag is one undo step.
  bool _dragging = false;
  bool _recorded = false;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final colors = [
      for (final c in widget.customColors)
        if (!widget.palette.any((p) => p.toARGB32() == c.toARGB32())) c,
      ...widget.palette,
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.colorAndOpacity,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              children: [
                MoreColorsButton(
                  tooltip: s.moreColors,
                  onTap: () async {
                    final c = await widget.onMoreColors();
                    if (c != null && mounted) setState(() => _color = c);
                  },
                ),
                for (final c in colors)
                  Swatch(
                    color: c,
                    label: s.colorLabel(c),
                    selected: c.toARGB32() == _color.toARGB32(),
                    onTap: () {
                      setState(() => _color = c);
                      widget.onColor(c);
                    },
                  ),
              ],
            ),
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
                    value: _opacity.clamp(AppSettings.minOpacity, 1),
                    label: s.percent(_opacity),
                    semanticFormatterCallback: (v) =>
                        '${s.opacity} ${s.percent(v)}',
                    activeColor: accent,
                    onChangeStart: (_) {
                      _dragging = true;
                      _recorded = false;
                    },
                    onChanged: (v) {
                      setState(() => _opacity = v);
                      widget.onOpacity(v, recordUndo: !_recorded);
                      if (_dragging) _recorded = true;
                    },
                    onChangeEnd: (_) => _dragging = false,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: Text(
                    s.percent(_opacity),
                    style: TextStyle(color: cute.ink),
                  ),
                ),
              ],
            ),
            Text(
              s.rainbowKeepsColors,
              style: TextStyle(color: cute.ink, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puts the selection bar just below the selection, or above it when there
/// isn't room, keeping clear of the corner controls at the top and bottom.
class NextToSelection extends SingleChildLayoutDelegate {
  NextToSelection(this.anchor);

  /// The selection (with its handles) on screen.
  final Rect anchor;

  /// Room left for the corner controls (undo, tools button).
  static const reserve = 72.0;
  static const gap = 8.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(math.max(0, constraints.maxWidth - 32), constraints.maxHeight),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final x = (anchor.center.dx - childSize.width / 2)
        .clamp(16.0, math.max(16.0, size.width - 16 - childSize.width))
        .toDouble();
    final below = anchor.bottom + gap;
    final above = anchor.top - gap - childSize.height;
    final double y;
    if (below + childSize.height <= size.height - reserve) {
      y = below;
    } else if (above >= reserve) {
      y = above;
    } else {
      // A selection as big as the screen: the top, below the corners.
      y = math.min(reserve, math.max(0.0, size.height - childSize.height));
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(NextToSelection old) => old.anchor != anchor;
}


/// The selection bar's buttons: copy, bigger, smaller, turn left and
/// right, color and opacity ([onStyle]), and delete.
List<(IconData, String, VoidCallback)> selectionActions(
        S s, SelectionController selection,
        {required VoidCallback onStyle}) =>
    [
      (Icons.copy_rounded, s.duplicate, selection.duplicate),
      (
        Icons.open_in_full_rounded,
        s.makeBigger,
        () => selection.transform(scale: 1.25),
      ),
      (
        Icons.close_fullscreen_rounded,
        s.makeSmaller,
        () => selection.transform(scale: 0.8),
      ),
      (
        Icons.rotate_left_rounded,
        s.turnLeft,
        () => selection.transform(angle: -math.pi / 12),
      ),
      (
        Icons.rotate_right_rounded,
        s.turnRight,
        () => selection.transform(angle: math.pi / 12),
      ),
      (Icons.palette_rounded, s.colorAndOpacity, onStyle),
      (Icons.delete_outline_rounded, s.deleteSelection, selection.delete),
    ];

/// Where the selection [f] is on screen, in [stack]'s coordinates (through
/// the zoom and the paper's fit-to-screen scaling), with room around its
/// corners and turn handle, so the selection bar can sit next to it.
Rect selectionAnchor(SelectionFrame f, RenderBox paper, RenderBox stack) {
  final toStack = paper.getTransformTo(stack);
  final corners = [
    f.box.topLeft,
    f.box.topRight,
    f.box.bottomLeft,
    f.box.bottomRight,
    f.box.topCenter - const Offset(0, SelectionFrameHandles.rotateHandleGap),
  ].map((p) => MatrixUtils.transformPoint(toStack, f.transform.apply(p)));
  return corners
      .map((p) => Rect.fromCenter(center: p, width: 36, height: 36))
      .reduce((a, b) => a.expandToInclude(b));
}

/// The sheet that recolors and fades the selection; "more colors" opens
/// the full picker from [context].
Future<void> showSelectionStyleSheet(BuildContext context,
    SelectionController selection, AppSettings settings) async {
  final sel = selection.selected.value;
  if (sel.isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SelectionStyleSheet(
      palette: AppPalette.colors,
      customColors: settings.customColors,
      color: sel.first.color,
      opacity: sel.first.opacity,
      onColor: selection.recolor,
      onMoreColors: () async {
        final picked = await showAppColorPicker(context, sel.first.color);
        if (picked == null) return null;
        settings.addCustomColor(picked);
        selection.recolor(picked);
        return picked;
      },
      onOpacity: selection.fade,
    ),
  );
}
