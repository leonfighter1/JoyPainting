import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../settings.dart';
import '../../theme/cute_theme.dart';
import '../../widgets/press_bounce.dart';
import '../../widgets/snap_sheet.dart';
import 'tool_catalog.dart';

/// 添加工具: everything the level offers beyond the basic options, by
/// group ([first] on top), to tick as many as wanted. 完成 puts the ticked
/// ones in their groups in the tools drawer and takes the unticked ones
/// out.
Future<void> showAddToolsSheet(
  BuildContext context,
  AppSettings settings, {
  ToolGroup? first,
}) => showSnapSheet<void>(
  context: context,
  builder: (_) => AddToolsSheet(settings: settings, first: first),
);

class AddToolsSheet extends StatefulWidget {
  const AddToolsSheet({super.key, required this.settings, this.first});

  final AppSettings settings;
  final ToolGroup? first;

  @override
  State<AddToolsSheet> createState() => _AddToolsSheetState();
}

class _AddToolsSheetState extends State<AddToolsSheet> {
  late final Set<String> _picked = widget.settings.addedTools;

  void _toggle(String key) => setState(
    () => _picked.contains(key) ? _picked.remove(key) : _picked.add(key),
  );

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    final scheme = Theme.of(context).colorScheme;
    final level = widget.settings.level;
    final groups = [
      ?widget.first,
      for (final g in ToolGroup.values)
        if (g != widget.first) g,
    ].where((g) => g.allowedAt(level));
    return SnapSheet(
      key: const ValueKey('addToolsList'),
      header: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
        child: Text(
          s.addTools,
          style: TextStyle(
            color: cute.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          sliver: SliverList.list(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(s.addToolsHint, style: TextStyle(color: cute.ink)),
              ),
              for (final group in groups)
                ..._group(context, group, s, cute, scheme),
            ],
          ),
        ),
      ],
      footer: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel),
            ).bouncy(),
            const SizedBox(width: 8),
            FilledButton.icon(
              key: const ValueKey('addToolsDone'),
              icon: const Icon(Icons.check_rounded),
              label: Text(s.done),
              onPressed: () {
                widget.settings.addedTools = _picked;
                Navigator.pop(context);
              },
            ).bouncy(),
          ],
        ),
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    ToolGroup group,
    S s,
    CuteTheme cute,
    ColorScheme scheme,
  ) {
    final options = [
      for (final o in ToolCatalog.options(group, widget.settings, s))
        if (!o.basic) o,
    ];
    if (options.isEmpty) return const [];
    final all = options.every((o) => _picked.contains(o.key));
    return [
      Row(
        children: [
          Expanded(
            child: Text(
              group.title(s),
              style: TextStyle(
                color: cute.ink,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() {
              for (final o in options) {
                all ? _picked.remove(o.key) : _picked.add(o.key);
              }
            }),
            child: Text(all ? s.pickNone : s.pickAll),
          ).bouncy(),
        ],
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final o in options)
            Builder(builder: (context) {
              // Picked ones filled with the theme's color, as chosen chips
              // in the drawer are.
              final picked = _picked.contains(o.key);
              final fg = picked ? scheme.onPrimary : cute.ink;
              return FilterChip(
                key: ValueKey('add.${o.key}'),
                avatar: o.glyph(fg),
                label: Text(o.label),
                labelStyle: TextStyle(color: fg, fontWeight: FontWeight.w600),
                selected: picked,
                selectedColor: scheme.primary,
                backgroundColor: scheme.surface,
                side: BorderSide(color: scheme.primary.withValues(alpha: 0.35)),
                showCheckmark: false,
                onSelected: (_) => _toggle(o.key),
              );
            }),
        ],
      ),
      const SizedBox(height: 14),
    ];
  }
}

/// The last chip of a group in the tools drawer: opens [showAddToolsSheet]
/// at that group.
class AddToolChip extends StatelessWidget {
  const AddToolChip({super.key, required this.group, required this.onTap});

  final ToolGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ActionChip(
      key: ValueKey('addTo.${group.name}'),
      avatar: Icon(Icons.add_rounded, size: 18, color: scheme.primary),
      label: Text(S.of(context).addMore),
      labelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
      side: BorderSide(color: scheme.primary.withValues(alpha: 0.6)),
      backgroundColor: scheme.surface,
      onPressed: onTap,
    ).bouncy();
  }
}
