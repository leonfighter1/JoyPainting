import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../l10n.dart';
import '../painting_session.dart';
import '../share/import_actions.dart';
import '../share/share_actions.dart';
import '../widgets/drop_menu.dart';
import '../widgets/name_dialog.dart';
import '../theme/cute_theme.dart';
import 'painting_store.dart';

/// Every saved painting, newest first, filterable by the year it was started.
class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    required this.session,
    required this.onOpened,
    required this.onOpenSettings,
  });

  final PaintingSession session;

  /// Called after a painting is opened, so the shell can switch to the canvas.
  final VoidCallback onOpened;

  /// Opens the settings page (from the ⋮ menu).
  final VoidCallback onOpenSettings;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List<PaintingMeta>? _paintings;

  /// null shows every year.
  int? _year;

  /// Choosing paintings to export: tapping a card checks it.
  bool _selecting = false;
  final Set<String> _picked = {};

  void _startSelecting([String? first]) => setState(() {
    _selecting = true;
    _picked.clear();
    if (first != null) _picked.add(first);
  });

  void _stopSelecting() => setState(() {
    _selecting = false;
    _picked.clear();
  });

  void _toggle(String id) => setState(
    () => _picked.contains(id) ? _picked.remove(id) : _picked.add(id),
  );

  /// All shown (the year filter applies), or none if they all are already.
  void _toggleAll(List<PaintingMeta> shown) => setState(() {
    final ids = {for (final p in shown) p.id};
    if (_picked.containsAll(ids)) {
      _picked.removeAll(ids);
    } else {
      _picked.addAll(ids);
    }
  });

  /// Exports the checked paintings, in gallery order. The open one is taken
  /// live from the canvas, so unsaved strokes are included.
  Future<void> _exportPicked() async {
    final docs = <PaintingDoc>[];
    for (final meta in _paintings ?? const <PaintingMeta>[]) {
      if (!_picked.contains(meta.id)) continue;
      final doc = meta.id == widget.session.id
          ? widget.session.currentDoc()
          : await _store.load(meta.id);
      if (doc != null) docs.add(doc);
    }
    if (!mounted) return;
    await exportPaintings(context, docs);
    if (mounted) _stopSelecting();
  }

  PaintingStore get _store => widget.session.store;

  /// The store being listened to; it changes when another kid is chosen.
  late PaintingStore _listening;

  @override
  void initState() {
    super.initState();
    _listening = _store..addListener(_reload);
    widget.session.addListener(_onSessionChanged);
    _reload();
  }

  @override
  void dispose() {
    _listening.removeListener(_reload);
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  /// Moves the "Editing" badge when a different painting is opened, and
  /// shows the other kid's paintings after a switch.
  void _onSessionChanged() {
    if (!identical(_listening, _store)) {
      _listening.removeListener(_reload);
      _listening = _store..addListener(_reload);
      _year = null;
      _reload();
    }
    setState(() {});
  }

  Future<void> _rename(PaintingMeta meta) async {
    final s = S.of(context);
    final name = await showNameDialog(
      context,
      title: s.renameTitle,
      initial: meta.name,
    );
    if (name != null) await widget.session.rename(meta.id, name);
  }

  Future<void> _reload() async {
    final list = await _store.list();
    if (!mounted) return;
    setState(() {
      _paintings = list;
      // Drop a year filter once its last painting is deleted.
      if (_year != null && !list.any((p) => p.createdAt.year == _year)) {
        _year = null;
      }
      // Forget checks on paintings that are gone.
      _picked.retainWhere((id) => list.any((p) => p.id == id));
    });
  }

  Future<void> _open(PaintingMeta meta) async {
    final messenger = ScaffoldMessenger.of(context);
    final s = S.of(context);
    if (await widget.session.open(meta.id)) {
      widget.onOpened();
    } else {
      messenger.showSnackBar(SnackBar(content: Text(s.openFailed)));
    }
  }

  Future<void> _newPainting() async {
    if (await widget.session.newPainting()) widget.onOpened();
  }

  Future<void> _confirmDelete(PaintingMeta meta) async {
    final s = S.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.deleteTitle),
        content: Text(s.deleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (ok == true) await widget.session.delete(meta.id);
  }

  /// Sends or prints a saved painting. The open one is taken live from the
  /// canvas, so unsaved strokes are included.
  Future<void> _withDoc(
    PaintingMeta meta,
    Future<void> Function(BuildContext, PaintingDoc) action,
  ) async {
    final doc = meta.id == widget.session.id
        ? widget.session.currentDoc()
        : await _store.load(meta.id);
    if (doc != null && mounted) await action(context, doc);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final all = _paintings;
    final years = <int, int>{};
    for (final p in all ?? const <PaintingMeta>[]) {
      years.update(p.createdAt.year, (n) => n + 1, ifAbsent: () => 1);
    }
    final sortedYears = years.keys.toList()..sort((a, b) => b.compareTo(a));
    final shown = [
      for (final p in all ?? const <PaintingMeta>[])
        if (_year == null || p.createdAt.year == _year) p,
    ];

    final cute = CuteTheme.of(context);
    return PopScope(
      // Back leaves choosing before it leaves the page.
      canPop: !_selecting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopSelecting();
      },
      child: Scaffold(
        appBar: GradientAppBar(
          title: AppLogoTitle(
            text: all == null
                ? s.navGallery
                : '${s.navGallery} (${all.length})',
          ),
          actions: [
            // Same unfolding menu as the canvas page.
            IconButton(
              tooltip: s.more,
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: () => showDropMenu(context, [
                DropMenuSection(
                  items: [
                    DropMenuItem(
                      icon: Icons.settings_rounded,
                      label: s.navSettings,
                      onSelected: widget.onOpenSettings,
                    ),
                  ],
                ),
              ]),
            ),
          ],
        ),
        // Colors come from the theme's contrast-checked secondary pair.
        floatingActionButton: _selecting
            ? null
            : FloatingActionButton.extended(
                onPressed: _newPainting,
                icon: const Icon(Icons.add_rounded),
                label: Text(s.newPainting),
              ),
        body: all == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _GalleryActions(
                    selecting: _selecting,
                    picked: _picked.length,
                    allShownPicked:
                        shown.isNotEmpty &&
                        shown.every((p) => _picked.contains(p.id)),
                    canExport: all.isNotEmpty,
                    onImport: () =>
                        pickAndImport(context, widget.session, widget.onOpened),
                    onStartExport: () => _startSelecting(),
                    onCancel: _stopSelecting,
                    onToggleAll: () => _toggleAll(shown),
                    onExport: _exportPicked,
                  ),
                  if (all.isNotEmpty)
                    SizedBox(
                      // Chips need 48px of height for an accessible tap area.
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        children: [
                          _YearChip(
                            label: '${s.allYears} (${all.length})',
                            selected: _year == null,
                            color: cute.spec.primary,
                            onTap: () => setState(() => _year = null),
                          ),
                          for (final (i, y) in sortedYears.indexed)
                            _YearChip(
                              label: '${s.year(y)} (${years[y]})',
                              selected: _year == y,
                              color: cute.nav[i % cute.nav.length],
                              onTap: () => setState(() => _year = y),
                            ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: shown.isEmpty
                        ? _EmptyState(
                            text: all.isEmpty ? s.emptyGallery : s.emptyYear,
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 96),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 240,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.72,
                                ),
                            itemCount: shown.length,
                            itemBuilder: (context, i) => _PaintingCard(
                              meta: shown[i],
                              store: _store,
                              isCurrent: shown[i].id == widget.session.id,
                              onOpen: () => _open(shown[i]),
                              onDelete: () => _confirmDelete(shown[i]),
                              onRename: () => _rename(shown[i]),
                              onSend: () => _withDoc(shown[i], showSendSheet),
                              onPrint: () => _withDoc(shown[i], printPainting),
                              selecting: _selecting,
                              picked: _picked.contains(shown[i].id),
                              onToggle: () => _toggle(shown[i].id),
                              onLongPress: _selecting
                                  ? null
                                  : () => _startSelecting(shown[i].id),
                            ),
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The row under the title: Import and Export, or while choosing what to
/// export: cancel, how many are checked, select all and Export.
class _GalleryActions extends StatelessWidget {
  const _GalleryActions({
    required this.selecting,
    required this.picked,
    required this.allShownPicked,
    required this.canExport,
    required this.onImport,
    required this.onStartExport,
    required this.onCancel,
    required this.onToggleAll,
    required this.onExport,
  });

  final bool selecting;
  final int picked;
  final bool allShownPicked;
  final bool canExport;
  final VoidCallback onImport;
  final VoidCallback onStartExport;
  final VoidCallback onCancel;
  final VoidCallback onToggleAll;
  final VoidCallback onExport;

  static const importKey = Key('galleryImport');
  static const exportKey = Key('galleryExport');

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    if (!selecting) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Align(
          // In line with the year chips below.
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              Tooltip(
                message: s.importHint,
                child: OutlinedButton.icon(
                  key: importKey,
                  icon: const Icon(Icons.file_open_rounded),
                  label: Text(s.importButton),
                  onPressed: onImport,
                ),
              ),
              OutlinedButton.icon(
                key: exportKey,
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(s.exportButton),
                onPressed: canExport ? onStartExport : null,
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: s.cancel,
            icon: const Icon(Icons.close_rounded),
            onPressed: onCancel,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.paintingsSelected(picked),
                  style: TextStyle(
                    color: cute.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  s.exportPickHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: cute.ink, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onToggleAll,
            child: Text(allShownPicked ? s.selectNone : s.selectAll),
          ),
          const SizedBox(width: 4),
          FilledButton.icon(
            icon: const Icon(Icons.ios_share_rounded),
            label: Text(s.exportSelected(picked)),
            onPressed: picked > 0 ? onExport : null,
          ),
        ],
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  const _YearChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        selectedColor: color,
        backgroundColor: cute.spec.surface,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        labelStyle: TextStyle(
          color: selected ? cute.onColor(color) : cute.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaintingCard extends StatefulWidget {
  const _PaintingCard({
    required this.meta,
    required this.store,
    required this.isCurrent,
    required this.onOpen,
    required this.onDelete,
    required this.onRename,
    required this.onSend,
    required this.onPrint,
    required this.selecting,
    required this.picked,
    required this.onToggle,
    required this.onLongPress,
  });

  final PaintingMeta meta;
  final PaintingStore store;
  final bool isCurrent;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onSend;
  final VoidCallback onPrint;

  /// Choosing paintings to export: a tap checks or unchecks this one.
  final bool selecting;
  final bool picked;
  final VoidCallback onToggle;

  /// Starts choosing, with this painting checked.
  final VoidCallback? onLongPress;

  @override
  State<_PaintingCard> createState() => _PaintingCardState();
}

class _PaintingCardState extends State<_PaintingCard> {
  late Future<Uint8List?> _thumbnail;

  @override
  void initState() {
    super.initState();
    _thumbnail = widget.store.thumbnail(widget.meta.id);
  }

  @override
  void didUpdateWidget(_PaintingCard old) {
    super.didUpdateWidget(old);
    // A newer save means a newer thumbnail.
    if (old.meta.id != widget.meta.id ||
        old.meta.updatedAt != widget.meta.updatedAt) {
      _thumbnail = widget.store.thumbnail(widget.meta.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final meta = widget.meta;
    final theme = Theme.of(context);
    final cute = CuteTheme.of(context);
    return Card(
      shape: widget.picked
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(cute.radius),
              side: BorderSide(color: theme.colorScheme.primary, width: 3),
            )
          : null,
      child: InkWell(
        onTap: widget.selecting ? widget.onToggle : widget.onOpen,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.white,
                    child: FutureBuilder(
                      future: _thumbnail,
                      builder: (context, snap) => snap.data == null
                          ? Icon(
                              Icons.image_outlined,
                              size: 48,
                              color: theme.colorScheme.outlineVariant,
                            )
                          : Image.memory(
                              snap.data!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.broken_image_outlined),
                            ),
                    ),
                  ),
                  if (widget.selecting)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Semantics(
                        checked: widget.picked,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.picked
                                ? theme.colorScheme.primary
                                : Colors.white,
                            border: Border.all(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: widget.picked
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 20,
                                  color: theme.colorScheme.onPrimary,
                                )
                              : null,
                        ),
                      ),
                    ),
                  if (widget.isCurrent)
                    Positioned(
                      left: 8,
                      top: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: cute.headerGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          child: Text(
                            s.editing,
                            style: TextStyle(
                              color: cute.onHeader,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          meta.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          formatDateTime(meta.createdAt).split(' ').first,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (widget.selecting)
                    const SizedBox(width: 48, height: 48)
                  else
                    PopupMenuButton<VoidCallback>(
                      onSelected: (action) => action(),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: widget.onOpen,
                          child: ListTile(
                            leading: const Icon(Icons.brush_rounded),
                            title: Text(s.continuePainting),
                          ),
                        ),
                        PopupMenuItem(
                          value: widget.onRename,
                          child: ListTile(
                            leading: const Icon(
                              Icons.drive_file_rename_outline_rounded,
                            ),
                            title: Text(s.rename),
                          ),
                        ),
                        PopupMenuItem(
                          value: widget.onSend,
                          child: ListTile(
                            leading: const Icon(Icons.send_rounded),
                            title: Text(s.send),
                          ),
                        ),
                        PopupMenuItem(
                          value: widget.onPrint,
                          child: ListTile(
                            leading: const Icon(Icons.print_rounded),
                            title: Text(s.print),
                          ),
                        ),
                        PopupMenuItem(
                          value: widget.onDelete,
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(s.delete),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cute = CuteTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: cute.headerGradient,
            ),
            child: Icon(
              Icons.palette_rounded,
              size: 64,
              color: cute.spec.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${cute.spec.emoji} $text',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
