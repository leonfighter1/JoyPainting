import 'package:flutter/material.dart';

/// Timings shared by the app's small motions, so things that move together
/// (a slider's thumb, its fill and its number) also move alike.
abstract final class Motion {
  /// How long a slider, and the numbers that go with it, take to reach a
  /// new value.
  static const settle = Duration(milliseconds: 220);

  /// How long a count takes to roll to a new number.
  static const roll = Duration(milliseconds: 600);

  /// Fast at first, slowing down as it arrives.
  static const Curve decelerate = Curves.easeOutCubic;

  /// [duration], or none when the system asks for less motion.
  static Duration of(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
}

/// A number that rolls from its old value to a new one, slowing down as it
/// gets close. [builder] gets the value to show (in between while it
/// rolls), so the number can sit in a sentence; round it there.
///
/// Next to a [LiquidSlider], use [Motion.settle] so the number moves in step
/// with the thumb.
class RollingNumber extends StatelessWidget {
  const RollingNumber({
    super.key,
    required this.value,
    required this.builder,
    this.duration = Motion.roll,
  });

  final double value;
  final Duration duration;
  final Widget Function(BuildContext context, double shown) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value),
    duration: Motion.of(context, duration),
    curve: Motion.decelerate,
    builder: (context, shown, _) => builder(context, shown),
  );
}
