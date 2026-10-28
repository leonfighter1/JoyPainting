import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../l10n.dart';
import '../../theme/cute_theme.dart';
import '../../widgets/name_dialog.dart';
import '../drawing_controller.dart';
import '../layers.dart';

/// The name a layer shows: its own, or "Layer N" counted from the bottom.
String layerTitle(S s, List<PaintingLayer> layers, PaintingLayer layer) =>
    layer.name.isNotEmpty ? layer.name : s.layerName(layers.indexOf(layer) + 1);

/// The row at the top of the tools drawer (advanced level): the active
/// layer and how many there are; a tap opens the layers.
class LayersRow extends StatelessWidget {
  const LayersRow({super.key, required this.drawing, required this.onOpen});

  final DrawingController drawing;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return ListenableBuilder(
      listenable: drawing,
      builder: (context, _) {
        final layers = drawing.layers;
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Material(
            color: cute.spec.primary.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: Icon(Icons.layers_rounded, color: cute.spec.primary),
              title: Text(s.layers,
                  style: TextStyle(
                      color: cute.ink, fontWeight: FontWeight.w800)),
              subtitle: Text(
                  s.layersButton(
                      layerTitle(s, layers, drawing.active), layers.length),
                  style: TextStyle(color: cute.ink)),
              trailing: Icon(Icons.chevron_right_rounded, color: cute.ink),
              onTap: onOpen,
            ),
          ),
        );
      },
    );
  }
}

/// Opens the layers of [drawing]. [thumbnail] gives a layer's kept picture
/// (null if there is none) for the small previews.
Future<void> showLayerSheet(
  BuildContext context, {
  required DrawingController drawing,
  required Size paperSize,
  required ui.Image? Function(String layerId) thumbnail,
}) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => LayerSheet(
          drawing: drawing, paperSize: paperSize, thumbnail: thumbnail),
    );

/// The layers, top first: tap one to draw on it; drag to reorder; each can
/// be shown or hidden, locked, renamed, merged down or deleted. Below the
/// list, the active layer's opacity.
class LayerSheet extends StatelessWidget {
  const LayerSheet({
    super.key,
    required this.drawing,
    required this.paperSize,
    required this.thumbnail,
  });

  final DrawingController drawing;
  final Size paperSize;
  final ui.Image? Function(String layerId) thumbnail;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return ListenableBuilder(
      listenable: drawing,
      builder: (context, _) {
        final layers = drawing.layers;
        final active = drawing.active;
        // Shown top first, as they stack.
        final shown = layers.reversed.toList();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(s.layers,
                            style: TextStyle(
                                color: cute.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800)),
                      ),
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.add_rounded),
                        label: Text(s.addLayer),
                        onPressed: layers.length >= PaintingLayer.maxLayers
                            ? null
                            : drawing.addLayer,
                      ),
                    ],
                  ),
                ),
                if (layers.length >= PaintingLayer.maxLayers)
                  Text(s.tooManyLayers, style: TextStyle(color: cute.ink)),
                Flexible(
                  child: ReorderableListView.builder(
                    shrinkWrap: true,
                    buildDefaultDragHandles: false,
                    itemCount: shown.length,
                    onReorderItem: (from, to) => drawing.moveLayer(
                        shown[from].id, layers.length - 1 - to),
                    itemBuilder: (context, i) => _LayerTile(
                      key: ValueKey(shown[i].id),
                      index: i,
                      drawing: drawing,
                      layer: shown[i],
                      title: layerTitle(s, layers, shown[i]),
                      selected: shown[i].id == active.id,
                      isBottom: i == shown.length - 1,
                      image: thumbnail(shown[i].id),
                      paperSize: paperSize,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Tooltip(
                        message: s.layerOpacity,
                        child: Icon(Icons.opacity_rounded,
                            color: cute.spec.primary),
                      ),
                      Expanded(
                        child: Slider(
                          value: active.opacity,
                          divisions: 20,
                          label: s.percent(active.opacity),
                          semanticFormatterCallback: (v) =>
                              '${s.layerOpacity} ${s.percent(v)}',
                          // One undo for a whole drag.
                          onChangeStart: (v) => drawing
                              .updateLayer(active.copyWith(opacity: v)),
                          onChanged: (v) => drawing.updateLayer(
                              drawing.active.copyWith(opacity: v),
                              recordUndo: false),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: Text(s.percent(active.opacity),
                            style: TextStyle(color: cute.ink)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LayerTile extends StatelessWidget {
  const _LayerTile({
    super.key,
    required this.index,
    required this.drawing,
    required this.layer,
    required this.title,
    required this.selected,
    required this.isBottom,
    required this.image,
    required this.paperSize,
  });

  final int index;
  final DrawingController drawing;
  final PaintingLayer layer;
  final String title;
  final bool selected;
  final bool isBottom;
  final ui.Image? image;
  final Size paperSize;

  Future<void> _rename(BuildContext context) async {
    final name = await showNameDialog(context,
        title: S.of(context).renameLayer, initial: title);
    if (name != null) drawing.updateLayer(layer.copyWith(name: name));
  }

  Future<void> _delete(BuildContext context) async {
    final s = S.of(context);
    if (drawing.strokesOn(layer.id).isNotEmpty) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(s.deleteLayer),
          content: Text(s.deleteLayerBody(title)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(s.cancel)),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(s.delete)),
          ],
        ),
      );
      if (ok != true) return;
    }
    drawing.deleteLayer(layer.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cute = CuteTheme.of(context);
    return Material(
      color: selected
          ? cute.spec.primary.withValues(alpha: 0.14)
          : Colors.transparent,
      child: ListTile(
        selected: selected,
        onTap: () => drawing.selectLayer(layer.id),
        leading: ReorderableDragStartListener(
          index: index,
          child: _Thumbnail(image: image, paperSize: paperSize),
        ),
        title: Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: cute.ink,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
        subtitle: Text(s.percent(layer.opacity),
            style: TextStyle(color: cute.ink)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: layer.visible ? s.hideLayer : s.showLayer,
              icon: Icon(layer.visible
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded),
              onPressed: () => drawing
                  .updateLayer(layer.copyWith(visible: !layer.visible)),
            ),
            IconButton(
              tooltip: layer.locked ? s.unlockLayer : s.lockLayer,
              icon: Icon(
                  layer.locked ? Icons.lock_rounded : Icons.lock_open_rounded),
              onPressed: () =>
                  drawing.updateLayer(layer.copyWith(locked: !layer.locked)),
            ),
            PopupMenuButton<VoidCallback>(
              tooltip: s.more,
              onSelected: (action) => action(),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: () => _rename(context),
                  child: ListTile(
                    leading: const Icon(Icons.drive_file_rename_outline_rounded),
                    title: Text(s.renameLayer),
                  ),
                ),
                PopupMenuItem(
                  enabled: !isBottom,
                  value: () => drawing.mergeDown(layer.id),
                  child: ListTile(
                    leading: const Icon(Icons.vertical_align_bottom_rounded),
                    title: Text(s.mergeDown),
                  ),
                ),
                PopupMenuItem(
                  enabled: drawing.layers.length > 1,
                  value: () => _delete(context),
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text(s.deleteLayer),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A layer's picture in a small rounded box (paper-white behind it), or a
/// layers icon when it has none kept.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.image, required this.paperSize});

  final ui.Image? image;
  final Size paperSize;

  @override
  Widget build(BuildContext context) {
    const side = 48.0;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black26),
      ),
      clipBehavior: Clip.antiAlias,
      child: image == null
          ? const Icon(Icons.layers_outlined, color: Colors.black38)
          : FittedBox(
              child: SizedBox.fromSize(
                size: paperSize,
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
            ),
    );
  }
}
