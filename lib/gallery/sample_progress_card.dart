import 'package:flutter/material.dart';

import '../l10n.dart';
import '../painting_session.dart';
import '../theme/cute_theme.dart';
import '../widgets/motion.dart';

/// A card at the top of the screen, over every page, while the sample
/// painting [name] is being put into My Paintings: a big one takes a
/// moment, and without it the app just seems to stall. Taps go through.
class SampleProgressCard extends StatelessWidget {
  const SampleProgressCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) =>
      ProgressCard(text: S.of(context).makingSample(name));
}

/// The same card while a painting is being opened: its name and how much
/// is done, with the percentage.
class OpeningProgressCard extends StatelessWidget {
  const OpeningProgressCard({super.key, required this.progress});

  final OpeningProgress progress;

  @override
  Widget build(BuildContext context) => ProgressCard(
        text: S.of(context).openingPainting(progress.name),
        value: progress.done,
      );
}

/// A card at the top of the screen saying what's going on, with a bar
/// that fills up to [value] (0 to 1), or moves to and fro without one.
/// Taps go through it; screen readers read it out.
class ProgressCard extends StatelessWidget {
  const ProgressCard({super.key, required this.text, this.value});

  final String text;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    final percent = value == null ? null : '${(value! * 100).clamp(0, 100).round()}%';
    final style = TextStyle(color: cute.ink, fontWeight: FontWeight.w700);
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: IgnorePointer(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  elevation: 6,
                  color: Theme.of(context).colorScheme.surface,
                  shadowColor: cute.spec.primary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(text, style: style)),
                            if (value case final value?) ...[
                              const SizedBox(width: 12),
                              RollingNumber(
                                value: value.clamp(0, 1),
                                builder: (context, v) =>
                                    Text('${(v * 100).round()}%', style: style),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: value,
                          semanticsValue: percent,
                          color: cute.spec.primary,
                          borderRadius: BorderRadius.circular(4),
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
