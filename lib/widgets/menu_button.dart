import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/cute_theme.dart';
import 'press_bounce.dart';

/// The menu button at the top right of a page: an outlined pill with a menu
/// icon and a small arrow saying it unfolds, so it stands out on the header
/// more than three faint dots would.
///
/// While the menu is open (until [onPressed]'s future completes) its three
/// lines turn into a cross: the top and bottom ones swing together, the
/// middle one fades, and the arrow turns up. Closing turns them back.
class MenuButton extends StatefulWidget {
  const MenuButton({super.key, required this.tooltip, required this.onPressed});

  final String tooltip;

  /// Opens the menu; completes when it has closed.
  final Future<void> Function() onPressed;

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  // As long as the menu takes to unfold (showDropMenu).
  late final _open = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final _turn = CurvedAnimation(
    parent: _open,
    curve: Curves.easeInOutCubic,
  );

  Future<void> _press() async {
    _open.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 280);
    _open.forward();
    await widget.onPressed();
    if (mounted) _open.reverse();
  }

  @override
  void dispose() {
    _turn.dispose();
    _open.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = CuteTheme.of(context).onHeader;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: widget.tooltip,
        child: PressBounce(
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: _press,
            // The whole 48px-high area takes the tap; the pill is drawn
            // inside it.
            child: SizedBox(
              height: 48,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    color: fg.withValues(alpha: 0.16),
                    shape: StadiumBorder(
                      side: BorderSide(
                          color: fg.withValues(alpha: 0.7), width: 1.5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomPaint(
                          size: const Size.square(24),
                          painter: _MenuLines(open: _turn, color: fg),
                        ),
                        RotationTransition(
                          turns: Tween(begin: 0.0, end: 0.5).animate(_turn),
                          child: Icon(Icons.arrow_drop_down_rounded,
                              color: fg, size: 22),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three menu lines (Material's menu icon) at [open] 0, a cross at 1.
class _MenuLines extends CustomPainter {
  _MenuLines({required this.open, required this.color})
    : super(repaint: open);

  final Animation<double> open;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final t = open.value;
    final s = size.width / 24;
    final center = size.center(Offset.zero);
    final pen = Paint()
      ..color = color
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    // First the outer lines slide to the middle, then they turn.
    final slide = Curves.easeOut.transform((t / 0.6).clamp(0.0, 1.0));
    final turn = Curves.easeOut.transform(((t - 0.3) / 0.7).clamp(0.0, 1.0));
    for (final side in const [-1, 1]) {
      canvas.save();
      canvas.translate(center.dx, center.dy + side * lerpDouble(6, 0, slide)! * s);
      canvas.rotate(side * turn * math.pi / 4);
      canvas.drawLine(Offset(-8 * s, 0), Offset(8 * s, 0), pen);
      canvas.restore();
    }
    final middle = 1 - (t / 0.4).clamp(0.0, 1.0);
    if (middle > 0) {
      canvas.drawLine(
        center + Offset(-8 * s, 0),
        center + Offset(8 * s, 0),
        pen..color = color.withValues(alpha: color.a * middle),
      );
    }
  }

  @override
  bool shouldRepaint(_MenuLines old) => old.open != open || old.color != color;
}
