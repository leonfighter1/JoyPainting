import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme/cute_theme.dart';
import 'painting_store.dart';

/// When to remind a grown-up to back up a kid's paintings: they live only
/// on this device (or in this browser), so a lost phone or cleared browser
/// data takes them along.
abstract final class BackupReminder {
  /// How long after a backup (or the first paintings) to remind again.
  static const every = Duration(days: 14);

  /// The same in a browser that hasn't promised to keep its storage.
  static const everyAtRisk = Duration(days: 7);

  /// How long "later" puts the reminder off.
  static const later = Duration(days: 7);

  /// Never backed up: no reminder until there are this many paintings.
  static const firstAfter = 3;

  /// Whether to remind now, for [paintings] last all exported at
  /// [lastBackup] (null: never).
  static bool due({
    required List<PaintingMeta> paintings,
    required DateTime now,
    DateTime? lastBackup,
    DateTime? snoozedUntil,
    bool atRisk = false,
  }) {
    if (paintings.isEmpty) return false;
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;
    final wait = atRisk ? everyAtRisk : every;
    if (lastBackup == null) {
      if (paintings.length < firstAfter) return false;
      final first = paintings
          .map((p) => p.createdAt)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      return now.difference(first) >= wait;
    }
    // Nothing new since the backup: nothing to lose.
    final changed = paintings.any((p) => p.updatedAt.isAfter(lastBackup));
    return changed && now.difference(lastBackup) >= wait;
  }
}

/// The reminder at the top of My Paintings: when the paintings were last
/// backed up, why it matters, a one-tap backup and "later".
class BackupBanner extends StatelessWidget {
  const BackupBanner({
    super.key,
    required this.lastBackup,
    required this.now,
    required this.atRisk,
    required this.onBackup,
    required this.onLater,
  });

  final DateTime? lastBackup;
  final DateTime now;

  /// A browser that may clear its storage.
  final bool atRisk;
  final VoidCallback onBackup;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    final last = lastBackup;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.cloud_upload_rounded, color: cute.spec.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        last == null
                            ? s.neverBackedUp
                            : s.lastBackedUp(now.difference(last).inDays),
                        style: TextStyle(
                            color: cute.ink, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(atRisk ? s.backupWhyBrowser : s.backupWhyDevice,
                          style: TextStyle(color: cute.ink)),
                    ],
                  ),
                ),
              ],
            ),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(onPressed: onLater, child: Text(s.later)),
                FilledButton.icon(
                  icon: const Icon(Icons.save_alt_rounded),
                  label: Text(s.backupNow),
                  onPressed: onBackup,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
