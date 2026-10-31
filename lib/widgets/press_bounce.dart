import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// Gives a button a press you can feel: it shrinks to [pressedScale] while
/// the finger is down, and on release springs back, a little past its size
/// and then to it.
///
/// It only listens to the pointer, so it never competes with the button's
/// own tap. A disabled button stays still, and so does every button when
/// the system asks for less motion.
class PressBounce extends StatefulWidget {
  const PressBounce({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  static const pressedScale = 0.96;

  /// The spring a released button comes back on. Under-damped, so it
  /// overshoots by about 1.5 % before it settles.
  static const spring = SpringDescription(mass: 1, stiffness: 600, damping: 14);

  @override
  State<PressBounce> createState() => _PressBounceState();
}

class _PressBounceState extends State<PressBounce>
    with SingleTickerProviderStateMixin {
  late final _scale = AnimationController.unbounded(vsync: this, value: 1);

  /// Fingers down on the button.
  int _down = 0;

  void _press(PointerDownEvent _) {
    if (!widget.enabled || MediaQuery.disableAnimationsOf(context)) return;
    _down++;
    _scale.animateTo(
      PressBounce.pressedScale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
    );
  }

  void _release(PointerEvent _) {
    if (_down == 0 || --_down > 0) return;
    _scale.animateWith(
      SpringSimulation(PressBounce.spring, _scale.value, 1, _scale.velocity),
    );
  }

  @override
  void dispose() {
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _press,
    onPointerUp: _release,
    onPointerCancel: _release,
    child: ScaleTransition(scale: _scale, child: widget.child),
  );
}

/// `FilledButton(...).bouncy()`: a [PressBounce] around a Material button,
/// still for a disabled one.
extension BouncyButton on Widget {
  Widget bouncy() => PressBounce(
    enabled: switch (this) {
      final ButtonStyleButton b => b.enabled,
      final IconButton b => b.onPressed != null,
      final FloatingActionButton b => b.onPressed != null,
      _ => true,
    },
    child: this,
  );
}
