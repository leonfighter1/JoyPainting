import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/cute_theme.dart';

/// A card at the top of the screen, over every page, while the sample
/// painting [name] is being put into My Paintings: a big one takes a
/// moment, and without it the app just seems to stall. Taps go through.
class SampleProgressCard extends StatelessWidget {
  const SampleProgressCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
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
                        Text(
                          S.of(context).makingSample(name),
                          style: TextStyle(
                            color: cute.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
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
