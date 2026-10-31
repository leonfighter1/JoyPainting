import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// An on/off switch whose knob is a little jelly: while it travels it
/// stretches sideways into a capsule, and at the far end it rounds up
/// again with a small bounce.
///
/// Colors follow Material 3's switch, from the theme's color scheme.
class ElasticSwitch extends StatefulWidget {
  const ElasticSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.interactive = true,
  });

  final bool value;

  /// Null shows the switch disabled.
  final ValueChanged<bool>? onChanged;

  /// False when something around it (a list row) takes the taps and the
  /// focus; the switch then only shows the value.
  final bool interactive;

  /// The spring the knob travels on: it overshoots by about a tenth of the
  /// way, which is the bounce.
  static const spring = SpringDescription(mass: 1, stiffness: 300, damping: 20);

  /// About the knob's top speed on [spring], in whole trips per second; at
  /// this speed it is stretched the most.
  static const _topSpeed = 9.0;

  @override
  State<ElasticSwitch> createState() => _ElasticSwitchState();
}

class _ElasticSwitchState extends State<ElasticSwitch>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );

  @override
  void didUpdateWidget(ElasticSwitch old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    final target = widget.value ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      _position.value = target;
    } else {
      _position.animateWith(SpringSimulation(
        ElasticSwitch.spring,
        _position.value,
        target,
        _position.velocity,
      ));
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = widget.onChanged != null;
    Widget result = AnimatedBuilder(
      animation: _position,
      builder: (context, _) => CustomPaint(
        size: const Size(60, 48),
        painter: _SwitchPainter(
          position: _position.value,
          stretch: (_position.velocity.abs() / ElasticSwitch._topSpeed)
              .clamp(0.0, 1.0),
          scheme: scheme,
          enabled: enabled,
        ),
      ),
    );
    if (widget.interactive) {
      result = FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _toggle(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _toggle : null,
          child: result,
        ),
      );
    }
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      onTap: widget.interactive && enabled ? _toggle : null,
      child: result,
    );
  }
}

class _SwitchPainter extends CustomPainter {
  _SwitchPainter({
    required this.position,
    required this.stretch,
    required this.scheme,
    required this.enabled,
  });

  /// 0 off, 1 on; a little past either end while bouncing.
  final double position;

  /// 0 for a round knob, 1 for the longest capsule.
  final double stretch;
  final ColorScheme scheme;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final on = position.clamp(0.0, 1.0);
    final track = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 52,
      height: 32,
    );
    final trackOn = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.12);
    final trackOff = enabled
        ? scheme.surfaceContainerHighest
        : scheme.surfaceContainerHighest.withValues(alpha: 0.12);
    final outline = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.12);
    final knobOn = enabled ? scheme.onPrimary : scheme.surface;
    final knobOff = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.38);

    final shape = RRect.fromRectAndRadius(track, const Radius.circular(16));
    canvas.drawRRect(shape, Paint()..color = Color.lerp(trackOff, trackOn, on)!);
    // The outline fades as the track fills.
    canvas.drawRRect(
      shape.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = outline.withValues(alpha: outline.a * (1 - on)),
    );

    // The knob grows from 16 to 24 across, as Material's does. While it
    // moves it stretches along the track and flattens a little; when it
    // overshoots the end it squashes against it, which is the bounce.
    final d = lerpDouble(16, 24, on)!;
    final squash = (position > 1 ? position - 1 : -position).clamp(0.0, 1.0) *
        (track.width - 32) *
        1.5;
    final w = d * (1 + 0.45 * stretch) - squash;
    final h = d * (1 - 0.12 * stretch) + squash / 2;
    final x = lerpDouble(track.left + 16, track.right - 16, position)!;
    final knob = Rect.fromCenter(
      center: Offset(x, track.center.dy),
      width: w,
      height: h,
    );
    // Kept inside the track even at the end of a bounce.
    final inside = track.deflate(3);
    final dx = knob.left < inside.left
        ? inside.left - knob.left
        : knob.right > inside.right
        ? inside.right - knob.right
        : 0.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(knob.shift(Offset(dx, 0)), Radius.circular(h / 2)),
      Paint()..color = Color.lerp(knobOff, knobOn, on)!,
    );
  }

  @override
  bool shouldRepaint(_SwitchPainter old) =>
      old.position != position ||
      old.stretch != stretch ||
      old.scheme != scheme ||
      old.enabled != enabled;
}

/// A list row with an [ElasticSwitch] at its end, like [SwitchListTile]:
/// tapping anywhere on the row flips it.
class ElasticSwitchTile extends StatelessWidget {
  const ElasticSwitchTile({
    super.key,
    required this.value,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: ListTile(
      leading: secondary,
      title: title,
      subtitle: subtitle,
      trailing: ElasticSwitch(
        value: value,
        onChanged: onChanged,
        interactive: false,
      ),
      enabled: onChanged != null,
      onTap: onChanged == null ? null : () => onChanged!(!value),
    ),
  );
}
