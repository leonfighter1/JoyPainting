import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/cute_theme.dart';
import 'motion.dart';

/// A slider whose filled track, thumb and value bubble glide to a new value
/// together: one animation ([Motion.settle] on [Motion.decelerate]) moves
/// all three, so the number above never runs ahead of the thumb. A number
/// shown beside it moves in step when it is a [RollingNumber] with
/// [Motion.settle].
///
/// Drag it or tap it, or step it one division at a time with the arrow
/// keys or a screen reader. Looks like Material 3's slider.
class LiquidSlider extends StatefulWidget {
  const LiquidSlider({
    super.key,
    required this.value,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.semanticFormatterCallback,
    this.activeColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
  });

  final double value;
  final double min;
  final double max;
  final int? divisions;

  /// The text in the bubble above the thumb while it's held; no bubble if
  /// null.
  final String Function(double value)? label;
  final String Function(double value)? semanticFormatterCallback;
  final Color? activeColor;

  /// Room at each end of the track for the thumb and its halo.
  final EdgeInsets padding;

  /// Null shows the slider disabled.
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<LiquidSlider> createState() => _LiquidSliderState();
}

class _StepIntent extends Intent {
  const _StepIntent(this.steps);

  /// Toward the end of the track: +1; toward its start: -1.
  final int steps;
}

class _LiquidSliderState extends State<LiquidSlider>
    with TickerProviderStateMixin {
  // Where the thumb is shown, as a fraction of the way from min to max: it
  // goes from _from to _to while _glide runs.
  late final _glide = AnimationController(
    vsync: this,
    duration: Motion.settle,
    value: 1,
  );
  late double _from = _fraction(widget.value);
  late double _to = _from;

  /// Held by a finger or the mouse: shows the halo and the bubble.
  late final _held = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  )..addStatusListener((status) {
      if (status == AnimationStatus.dismissed) _bubble.hide();
    });
  late final _heldCurve = CurvedAnimation(parent: _held, curve: Curves.easeOut);
  final _bubble = OverlayPortalController();
  final _link = LayerLink();
  bool _focused = false;
  bool _hovered = false;
  bool _dragging = false;

  // The track's ends, from the last layout.
  double _start = 0;
  double _end = 1;

  /// The value last sent during a drag.
  double _sent = 0;

  static const Map<ShortcutActivator, Intent> _keys = {
    SingleActivator(LogicalKeyboardKey.arrowRight): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowUp): _StepIntent(1),
    SingleActivator(LogicalKeyboardKey.arrowLeft): _StepIntent(-1),
    SingleActivator(LogicalKeyboardKey.arrowDown): _StepIntent(-1),
  };

  double get _shown =>
      lerpDouble(_from, _to, Motion.decelerate.transform(_glide.value))!;

  bool get _enabled => widget.onChanged != null;
  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  double _fraction(double value) => widget.max > widget.min
      ? ((value - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0)
      : 0;

  double _valueAt(double fraction) =>
      widget.min + fraction * (widget.max - widget.min);

  double _snap(double fraction) {
    final d = widget.divisions;
    return d == null || d <= 0 ? fraction : (fraction * d).round() / d;
  }

  /// The value [steps] divisions (or 5 % steps) away from the current one.
  double _stepped(int steps) {
    final d = widget.divisions;
    final unit = d == null || d <= 0 ? 0.05 : 1 / d;
    return _valueAt(
      _snap((_fraction(widget.value) + steps * unit).clamp(0.0, 1.0)),
    );
  }

  /// Where on the track [fraction] is drawn.
  double _x(double fraction) => _rtl
      ? _end - fraction * (_end - _start)
      : _start + fraction * (_end - _start);

  @override
  void didUpdateWidget(LiquidSlider old) {
    super.didUpdateWidget(old);
    final to = _fraction(widget.value);
    if (to == _to) return;
    _from = _shown;
    _to = to;
    _glide
      ..duration = Motion.of(context, Motion.settle)
      ..forward(from: 0);
  }

  @override
  void dispose() {
    _glide.dispose();
    _heldCurve.dispose();
    _held.dispose();
    super.dispose();
  }

  void _hold() {
    if (widget.label != null) _bubble.show();
    _held.forward();
  }

  void _dragStart(Offset at) {
    _dragging = true;
    widget.onChangeStart?.call(widget.value);
    _hold();
    _dragTo(at);
  }

  void _dragTo(Offset at) {
    if (_end <= _start) return;
    var fraction = ((at.dx - _start) / (_end - _start)).clamp(0.0, 1.0);
    if (_rtl) fraction = 1 - fraction;
    _sent = _valueAt(_snap(fraction));
    if (_sent != widget.value) widget.onChanged!(_sent);
  }

  void _dragEnd() {
    if (!_dragging) return;
    _dragging = false;
    widget.onChangeEnd?.call(_sent);
    _held.reverse();
  }

  void _step(int steps) {
    if (!_enabled) return;
    final value = _stepped(steps);
    widget.onChangeStart?.call(widget.value);
    if (value != widget.value) widget.onChanged!(value);
    widget.onChangeEnd?.call(value);
  }

  String _describe(double value) =>
      widget.semanticFormatterCallback?.call(value) ??
      '${(_fraction(value) * 100).round()}%';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = _enabled;
    final active = enabled
        ? widget.activeColor ?? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.38);
    final glide = Listenable.merge([_glide, _held]);
    final onBubble = CuteTheme.of(context).onColor(active);

    Widget bubble(BuildContext context) {
      return Positioned(
        left: 0,
        top: 0,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: glide,
            builder: (context, _) => CompositedTransformFollower(
              link: _link,
              showWhenUnlinked: false,
              followerAnchor: Alignment.bottomCenter,
              // Just above the thumb, which is 20 across in a 48 high row.
              offset: Offset(_x(_shown), 24 - 14),
              child: ScaleTransition(
                scale: _heldCurve,
                alignment: Alignment.bottomCenter,
                child: _Bubble(
                  // The value where the thumb is now, so the number glides
                  // with it.
                  text: widget.label!(_valueAt(_shown)),
                  color: active,
                  style: theme.textTheme.labelLarge!.copyWith(color: onBubble),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      slider: true,
      enabled: enabled,
      value: _describe(widget.value),
      increasedValue: _describe(_stepped(1)),
      decreasedValue: _describe(_stepped(-1)),
      onIncrease: enabled ? () => _step(1) : null,
      onDecrease: enabled ? () => _step(-1) : null,
      textDirection: Directionality.of(context),
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor:
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (on) => setState(() => _focused = on),
        onShowHoverHighlight: (on) => setState(() => _hovered = on),
        shortcuts: _keys,
        actions: {
          _StepIntent: CallbackAction<_StepIntent>(
            onInvoke: (intent) {
              // Left and right follow the reading direction.
              _step(_rtl ? -intent.steps : intent.steps);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          // Screen readers step it with increase and decrease instead.
          excludeFromSemantics: true,
          dragStartBehavior: DragStartBehavior.down,
          onHorizontalDragStart:
              enabled ? (d) => _dragStart(d.localPosition) : null,
          onHorizontalDragUpdate:
              enabled ? (d) => _dragTo(d.localPosition) : null,
          onHorizontalDragEnd: enabled ? (_) => _dragEnd() : null,
          onHorizontalDragCancel: enabled ? _dragEnd : null,
          onTapUp: enabled
              ? (d) {
                  _dragStart(d.localPosition);
                  _dragEnd();
                }
              : null,
          child: CompositedTransformTarget(
            link: _link,
            child: OverlayPortal(
              controller: _bubble,
              overlayChildBuilder: bubble,
              child: SizedBox(
                height: kMinInteractiveDimension,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth.isFinite
                        ? constraints.maxWidth
                        : 200.0;
                    _start = widget.padding.left;
                    _end = math.max(_start, width - widget.padding.right);
                    return AnimatedBuilder(
                      animation: glide,
                      builder: (context, _) => CustomPaint(
                        size: Size(width, kMinInteractiveDimension),
                        painter: _SliderPainter(
                          x: _x(_shown),
                          start: _start,
                          end: _end,
                          rtl: _rtl,
                          divisions: widget.divisions,
                          trackHeight: SliderTheme.of(context).trackHeight ?? 4,
                          active: active,
                          inactive: enabled
                              ? scheme.secondaryContainer
                              : scheme.onSurface.withValues(alpha: 0.12),
                          thumb: enabled
                              ? active
                              : Color.alphaBlend(active, scheme.surface),
                          tickOnActive: scheme.onPrimary.withValues(alpha: 0.6),
                          tickOnInactive:
                              scheme.onSurfaceVariant.withValues(alpha: 0.38),
                          shadow: theme.shadowColor,
                          held: _held.value,
                          highlight: _focused ? 1 : (_hovered ? 0.66 : 0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.color, required this.style});

  final String text;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      DecoratedBox(
        decoration: ShapeDecoration(color: color, shape: const StadiumBorder()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(text, style: style, maxLines: 1),
        ),
      ),
      CustomPaint(size: const Size(10, 5), painter: _TailPainter(color)),
    ],
  );
}

/// The bubble's little point, down toward the thumb.
class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_TailPainter old) => old.color != color;
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.x,
    required this.start,
    required this.end,
    required this.rtl,
    required this.divisions,
    required this.trackHeight,
    required this.active,
    required this.inactive,
    required this.thumb,
    required this.tickOnActive,
    required this.tickOnInactive,
    required this.shadow,
    required this.held,
    required this.highlight,
  });

  /// The thumb's center.
  final double x;
  final double start;
  final double end;
  final bool rtl;
  final int? divisions;
  final double trackHeight;
  final Color active;
  final Color inactive;
  final Color thumb;
  final Color tickOnActive;
  final Color tickOnInactive;
  final Color shadow;

  /// 0 to 1 as the thumb is taken hold of.
  final double held;

  /// 1 with keyboard focus, less under the mouse.
  final double highlight;

  static const _thumbRadius = 10.0;
  static const _haloRadius = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final r = trackHeight / 2;
    canvas.drawRRect(
      RRect.fromLTRBR(start, y - r, end, y + r, Radius.circular(r)),
      Paint()..color = inactive,
    );
    // The filled part, a little thicker, rounded at its outer end only.
    final a = r + 1;
    final fill = Paint()..color = active;
    if (rtl) {
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(x, y - a, end, y + a,
            topRight: Radius.circular(a), bottomRight: Radius.circular(a)),
        fill,
      );
    } else {
      canvas.drawRRect(
        RRect.fromLTRBAndCorners(start, y - a, x, y + a,
            topLeft: Radius.circular(a), bottomLeft: Radius.circular(a)),
        fill,
      );
    }

    // Tick marks where there's room for them, as Material shows.
    final d = divisions;
    if (d != null && d > 0 && (end - start) / d >= 9) {
      for (var i = 0; i <= d; i++) {
        final tx = start + i / d * (end - start);
        final filled = rtl ? tx >= x : tx <= x;
        canvas.drawCircle(
          Offset(tx, y),
          trackHeight / 4,
          Paint()..color = filled ? tickOnActive : tickOnInactive,
        );
      }
    }

    final halo = math.max(held, highlight);
    if (halo > 0) {
      canvas.drawCircle(
        Offset(x, y),
        _haloRadius,
        Paint()..color = active.withValues(alpha: 0.12 * halo),
      );
    }
    final knob = Path()
      ..addOval(Rect.fromCircle(center: Offset(x, y), radius: _thumbRadius));
    canvas.drawShadow(knob, shadow, lerpDouble(1, 6, held)!, true);
    canvas.drawPath(knob, Paint()..color = thumb);
  }

  @override
  bool shouldRepaint(_SliderPainter old) =>
      old.x != x ||
      old.start != start ||
      old.end != end ||
      old.rtl != rtl ||
      old.divisions != divisions ||
      old.trackHeight != trackHeight ||
      old.active != active ||
      old.inactive != inactive ||
      old.thumb != thumb ||
      old.held != held ||
      old.highlight != highlight;
}
