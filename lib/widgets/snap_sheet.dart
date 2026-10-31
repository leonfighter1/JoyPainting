import 'package:flutter/material.dart';

/// Opens a [SnapSheet] built by [builder] as a modal bottom sheet.
Future<T?> showSnapSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  // The sheet's own scrolling does the dragging.
  enableDrag: false,
  builder: builder,
);

/// A bottom sheet with two resting heights: it opens at half the screen,
/// pulled up it goes to the whole screen, and pulled down past half its
/// height (or flung down) from half, it closes.
///
/// [header] stays at the top under the grab handle; [slivers] scroll below
/// it; [footer] (buttons) stays at the bottom. Dragging the header or the
/// list moves the sheet until it rests, then scrolls the list. Tapping the
/// handle switches between the two heights.
class SnapSheet extends StatefulWidget {
  const SnapSheet({
    super.key,
    required this.header,
    required this.slivers,
    this.footer,
    this.contentKey,
  });

  final Widget header;
  final List<Widget> slivers;
  final Widget? footer;

  /// When it changes (other content), the list goes back to its top.
  final Object? contentKey;

  static const half = 0.5;
  static const full = 1.0;

  /// The grab handle at the top.
  static const handleKey = Key('snapSheetHandle');

  @override
  State<SnapSheet> createState() => _SnapSheetState();
}

class _SnapSheetState extends State<SnapSheet> {
  final _sheet = DraggableScrollableController();
  ScrollController? _list;

  @override
  void didUpdateWidget(SnapSheet old) {
    super.didUpdateWidget(old);
    if (old.contentKey != widget.contentKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final list = _list;
        if (mounted && list != null && list.hasClients) list.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  void _toggleHeight() {
    if (!_sheet.isAttached) return;
    _sheet.animateTo(
      _sheet.size < (SnapSheet.half + SnapSheet.full) / 2
          ? SnapSheet.full
          : SnapSheet.half,
      duration: MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 1)
          : const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.bottomSheetTheme.backgroundColor ??
        theme.colorScheme.surfaceContainerLow;
    final strings = MaterialLocalizations.of(context);
    return DraggableScrollableSheet(
      controller: _sheet,
      expand: false,
      initialChildSize: SnapSheet.half,
      minChildSize: 0,
      maxChildSize: SnapSheet.full,
      snap: true,
      snapSizes: const [SnapSheet.half],
      builder: (context, list) {
        _list = list;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CustomScrollView(
                controller: list,
                slivers: [
                  PinnedHeaderSliver(
                    child: ColoredBox(
                      color: background,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ListenableBuilder(
                            listenable: _sheet,
                            builder: (context, handle) => Semantics(
                              button: true,
                              label: _sheet.isAttached &&
                                      _sheet.size > SnapSheet.half + 0.01
                                  ? strings.expandedIconTapHint
                                  : strings.collapsedIconTapHint,
                              child: handle,
                            ),
                            child: GestureDetector(
                              key: SnapSheet.handleKey,
                              behavior: HitTestBehavior.opaque,
                              onTap: _toggleHeight,
                              // Material's handle: 32 × 4 in a 48 high
                              // tap area.
                              child: SizedBox(
                                height: 48,
                                child: Center(
                                  child: Container(
                                    width: 32,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          widget.header,
                        ],
                      ),
                    ),
                  ),
                  ...widget.slivers,
                  if (widget.footer == null)
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).bottom,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.footer case final footer?)
              SafeArea(top: false, child: footer),
          ],
        );
      },
    );
  }
}
