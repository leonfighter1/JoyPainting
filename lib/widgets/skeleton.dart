import 'package:flutter/material.dart';

/// Placeholders shown while something loads. Each one ([SkeletonBox],
/// [SkeletonLine]) takes the size of what will replace it, so nothing
/// moves when the real thing arrives. Under one [Skeleton] they all
/// breathe together.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  final Widget child;

  static Animation<double>? _of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SkeletonScope>()
      ?.notifier;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final _breath = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _breath.value = 0;
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonScope(notifier: _breath, child: widget.child);
}

class _SkeletonScope extends InheritedNotifier<Animation<double>> {
  const _SkeletonScope({required super.notifier, required super.child});
}

/// The placeholder's color, a little lighter at the top of each breath.
Color _tone(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  final t = Curves.easeInOut.transform(Skeleton._of(context)?.value ?? 0);
  return Color.lerp(
    scheme.surfaceContainerHighest,
    scheme.surfaceContainerLow,
    t * 0.8,
  )!;
}

/// A placeholder block: [width] × [height], or as big as it may be.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 8});

  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width ?? double.infinity,
    height: height ?? double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: _tone(context),
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

/// A placeholder for one line of text in [style]: as tall as that line
/// (with the app's text size) and [widthFactor] of the width there is.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, this.style, this.widthFactor = 1});

  final TextStyle? style;
  final double widthFactor;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    widthFactor: widthFactor,
    child: CustomPaint(
      painter: _BarPainter(_tone(context)),
      // An empty line in the same style gives the exact height.
      child: Text(' ', style: style, maxLines: 1),
    ),
  );
}

class _BarPainter extends CustomPainter {
  _BarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Letters fill the middle of a line, not its leading.
    final bar = Rect.fromLTRB(
      0,
      size.height * 0.2,
      size.width,
      size.height * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, Radius.circular(bar.height / 2)),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.color != color;
}
