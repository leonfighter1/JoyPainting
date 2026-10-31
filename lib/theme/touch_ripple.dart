import 'dart:math' as math;

import 'package:flutter/material.dart';

/// An ink ripple that starts exactly where the finger went down and spreads
/// from there until it covers the whole button. Material's own ripples
/// drift toward the button's middle as they grow; this one stays under the
/// finger.
///
/// Use it for the whole app with `ThemeData(splashFactory:
/// TouchRipple.splashFactory)`.
class TouchRipple extends InteractiveInkFeature {
  TouchRipple({
    required super.controller,
    required super.referenceBox,
    required Offset position,
    required super.color,
    required this._textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    super.customBorder,
    double? radius,
    super.onRemoved,
  }) : _position = position,
       _borderRadius = borderRadius ?? BorderRadius.zero,
       _clip = rectCallback ??
           (containedInkWell ? () => Offset.zero & referenceBox.size : null) {
    final box = rectCallback?.call() ?? Offset.zero & referenceBox.size;
    // Far enough to reach the corner furthest from the finger.
    final reach = [
      box.topLeft,
      box.topRight,
      box.bottomLeft,
      box.bottomRight,
    ].map((corner) => (corner - position).distance).reduce(math.max);
    final target = containedInkWell || radius == null ? reach : radius;

    _fadeIn = AnimationController(duration: _fadeInDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _grow = AnimationController(duration: _heldDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _radius = _grow.drive(
      Tween<double>(begin: target * 0.1, end: target)
          .chain(CurveTween(curve: Curves.ease)),
    );
    _fadeOut = AnimationController(duration: _fadeOutDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) dispose();
      });
    controller.addInkFeature(this);
  }

  static const InteractiveInkFeatureFactory splashFactory = _TouchRippleFactory();

  static const _fadeInDuration = Duration(milliseconds: 75);
  static const _growDuration = Duration(milliseconds: 225);
  // Grows slowly while the finger stays down.
  static const _heldDuration = Duration(seconds: 1);
  static const _fadeOutDuration = Duration(milliseconds: 375);

  final Offset _position;
  final TextDirection _textDirection;
  final BorderRadius _borderRadius;
  final RectCallback? _clip;

  late final AnimationController _fadeIn;
  late final AnimationController _grow;
  late final AnimationController _fadeOut;
  late final Animation<double> _radius;

  @override
  void confirm() {
    _grow
      ..duration = _growDuration
      ..forward();
    _fadeIn.forward();
    _fadeOut.forward();
  }

  @override
  void cancel() {
    _fadeIn.stop();
    // Fades from as strong as it got. Reaching the end disposes this
    // ripple, so a ripple that never showed must not animate after it.
    final from = 1 - _fadeIn.value;
    _fadeOut.value = from;
    if (from < 1) _fadeOut.forward();
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _grow.dispose();
    _fadeOut.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final strength = _fadeIn.value * (1 - _fadeOut.value);
    paintInkCircle(
      canvas: canvas,
      transform: transform,
      paint: Paint()..color = color.withValues(alpha: color.a * strength),
      center: _position,
      textDirection: _textDirection,
      radius: _radius.value,
      customBorder: customBorder,
      borderRadius: _borderRadius,
      clipCallback: _clip,
    );
  }
}

class _TouchRippleFactory extends InteractiveInkFeatureFactory {
  const _TouchRippleFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) => TouchRipple(
    controller: controller,
    referenceBox: referenceBox,
    position: position,
    color: color,
    textDirection: textDirection,
    containedInkWell: containedInkWell,
    rectCallback: rectCallback,
    borderRadius: borderRadius,
    customBorder: customBorder,
    radius: radius,
    onRemoved: onRemoved,
  );
}
