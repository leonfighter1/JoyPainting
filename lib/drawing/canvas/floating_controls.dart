import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../l10n.dart';
import '../../settings.dart';
import '../../theme/cute_theme.dart';
import '../../widgets/menu_button.dart';
import '../drawing_controller.dart';
import '../stroke.dart';
import 'canvas_view.dart';

/// The button that brings out the tools drawer. It shows the current brush
/// and color, so it's obvious what it opens and what's selected.
class ToolsLauncher extends StatelessWidget {
  const ToolsLauncher({
    super.key,
    required this.settings,
    required this.fromLeft,
    required this.hide,
    required this.onTap,
  });

  final AppSettings settings;

  /// The drawer opens from the left: the arrow points that way.
  final bool fromLeft;

  /// The drawer's slide animation: the button fades out as it comes in.
  final Animation<double> hide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brush = settings.brush;
    final accent = AppTheme.brushColor(brush);
    return AnimatedBuilder(
      animation: hide,
      builder: (context, child) => IgnorePointer(
        ignoring: hide.value > 0,
        child: Opacity(
          opacity: 1 - hide.value,
          child: Transform.scale(scale: 1 - 0.3 * hide.value, child: child),
        ),
      ),
      // excludeSemantics drops the InkWell's own tap action, so the action is
      // given here; otherwise screen readers can't activate the button.
      child: Semantics(
        button: true,
        label: s.openTools,
        onTap: onTap,
        excludeSemantics: true,
        child: Material(
          color: scheme.surface,
          elevation: 8,
          shadowColor: cute.spec.primary.withValues(alpha: 0.4),
          shape: StadiumBorder(
            side: BorderSide(
              color: cute.spec.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: accent,
                    child: Icon(
                      AppTheme.brushIcon(brush),
                      color: cute.onColor(accent),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (brush.usesColor) ...[
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: settings.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    s.toolsButton,
                    style: TextStyle(
                      color: cute.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  // Points to where the drawer will come from.
                  Icon(
                    fromLeft
                        ? Icons.chevron_right_rounded
                        : Icons.chevron_left_rounded,
                    color: cute.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Undo and redo, floating at the top left of the paper.
/// Fades away while the tools drawer is open, like the tools button.
class UndoRedoBar extends StatelessWidget {
  const UndoRedoBar({super.key, required this.drawing, required this.hide});

  final DrawingController drawing;
  final Animation<double> hide;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return AnimatedBuilder(
      animation: hide,
      builder: (context, child) => IgnorePointer(
        ignoring: hide.value > 0,
        child: Opacity(opacity: 1 - hide.value, child: child),
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        shadowColor: cute.spec.primary.withValues(alpha: 0.4),
        shape: StadiumBorder(
          side: BorderSide(
            color: cute.spec.primary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: ListenableBuilder(
          listenable: drawing,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: s.undo,
                icon: const Icon(Icons.undo_rounded),
                color: cute.ink,
                onPressed: drawing.canUndo ? drawing.undo : null,
              ),
              IconButton(
                tooltip: s.redo,
                icon: const Icon(Icons.redo_rounded),
                color: cute.ink,
                onPressed: drawing.canRedo ? drawing.redo : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the zoom level while the paper is zoomed or moved; tap to fit the
/// whole paper back on screen.
class ZoomChip extends StatelessWidget {
  const ZoomChip({super.key, required this.view, required this.onReset});

  final ValueListenable<Matrix4> view;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return ValueListenableBuilder(
      valueListenable: view,
      builder: (context, matrix, _) {
        final zoom = zoomOf(matrix);
        final degrees = (rotationOf(matrix) * 180 / math.pi).round();
        final moved = matrix.getTranslation().length > 1;
        final show = (zoom - 1).abs() > 0.01 || moved || degrees != 0;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: !show
              ? const SizedBox.shrink()
              : ActionChip(
                  key: const ValueKey('zoomChip'),
                  avatar: Icon(
                    Icons.fit_screen_rounded,
                    color: cute.ink,
                    size: 18,
                  ),
                  label: Text([
                    '${(zoom * 100).round()}%',
                    if (degrees != 0) '$degrees°',
                    s.fitScreen,
                  ].join(' · ')),
                  labelStyle: TextStyle(
                    color: cute.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  elevation: 4,
                  onPressed: onReset,
                ),
        );
      },
    );
  }
}


/// The painting's own actions in the title bar, one tap away: the move tool
/// (选择移动, from the intermediate level), clear, ✋ (move the paper) and
/// the ☰ menu. Paintings save themselves; a new one is in the menu. Undo
/// and redo float on the paper.
class CanvasBarActions extends StatelessWidget {
  const CanvasBarActions({
    super.key,
    required this.changes,
    required this.settings,
    required this.canClear,
    required this.panMode,
    required this.onMove,
    required this.onClear,
    required this.onMenu,
  });

  /// Whatever changes [canClear] and the brush.
  final Listenable changes;
  final AppSettings settings;
  final bool Function() canClear;
  final ValueNotifier<bool> panMode;

  /// Picks the move tool, or goes back to the brush used before it.
  final VoidCallback onMove;
  final VoidCallback onClear;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    ButtonStyle? on(bool active) => active
        ? IconButton.styleFrom(
            backgroundColor: cute.onHeader.withValues(alpha: 0.18),
          )
        : null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: changes,
          builder: (context, _) {
            final moving = settings.brush == BrushType.move;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (settings.level.allows(BrushType.move))
                  IconButton(
                    key: const ValueKey('moveToolButton'),
                    tooltip: s.brushName(BrushType.move),
                    isSelected: moving,
                    icon: Icon(AppTheme.brushIcon(BrushType.move)),
                    style: on(moving),
                    onPressed: onMove,
                  ),
                IconButton(
                  tooltip: s.clear,
                  icon: const Icon(Icons.layers_clear_rounded),
                  onPressed: canClear() ? onClear : null,
                ),
              ],
            );
          },
        ),
        // ✋ Move the paper: one tap away, and in the title bar it never
        // crowds the corner controls on a narrow phone.
        ValueListenableBuilder(
          valueListenable: panMode,
          builder: (context, panning, _) => IconButton(
            tooltip: s.panCanvas,
            isSelected: panning,
            icon: const Icon(Icons.pan_tool_outlined),
            selectedIcon: const Icon(Icons.pan_tool_rounded),
            style: on(panning),
            onPressed: () => panMode.value = !panning,
          ),
        ),
        MenuButton(tooltip: s.more, onPressed: onMenu),
      ],
    );
  }
}
