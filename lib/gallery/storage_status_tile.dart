import 'package:flutter/material.dart';

import '../l10n.dart';
import 'storage_risk.dart';

/// In a browser: whether it promised to keep the paintings, with a button
/// to ask it to while it hasn't. Shown with the backup reminders setting.
class StorageStatusTile extends StatefulWidget {
  const StorageStatusTile({
    super.key,
    this.atRisk = storageAtRisk,
    this.askToKeep = askToKeepStorage,
  });

  /// Whether the paintings could be cleared (see [storageAtRisk]).
  final Future<bool> Function() atRisk;

  /// Asks the browser to keep them; whether it will.
  final Future<bool> Function() askToKeep;

  @override
  State<StorageStatusTile> createState() => _StorageStatusTileState();
}

class _StorageStatusTileState extends State<StorageStatusTile> {
  /// Null until the browser has answered.
  bool? _atRisk;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    widget.atRisk().then((risk) {
      if (mounted) setState(() => _atRisk = risk);
    });
  }

  Future<void> _ask() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _asking = true);
    final kept = await widget.askToKeep();
    if (!mounted) return;
    setState(() {
      _asking = false;
      if (kept) _atRisk = false;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(kept ? s.keepGranted : s.keepRefused)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final colors = Theme.of(context).colorScheme;
    final atRisk = _atRisk;
    if (atRisk == null) return const SizedBox.shrink();
    if (!atRisk) {
      return ListTile(
        leading: Icon(Icons.verified_user_rounded, color: colors.primary),
        title: Text(s.storageKept),
        subtitle: Text(s.storageKeptHint),
      );
    }
    return ListTile(
      leading: Icon(Icons.warning_amber_rounded, color: colors.error),
      title: Text(s.storageAtRisk),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.storageAtRiskHint),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: FilledButton.tonal(
              onPressed: _asking ? null : _ask,
              child: Text(s.askToKeep),
            ),
          ),
        ],
      ),
    );
  }
}
