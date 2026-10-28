import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../app_theme.dart';
import '../../gallery/painting_store.dart';
import '../../l10n.dart';
import '../../share/painting_export.dart';
import '../../share/share_actions.dart';
import '../render/layer_cache.dart';
import '../stroke.dart';
import 'replay_gif.dart';
import 'replay_timeline.dart';

/// Opens the replay of [doc]: the painting drawing itself again, stroke by
/// stroke, in the order it was made.
Future<void> showReplay(BuildContext context, PaintingDoc doc) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReplayPage(doc: doc),
    ));

/// Plays a painting back: play and pause, speed (½× to 4×), a slider to
/// jump anywhere, and saving the replay as an animated GIF.
class ReplayPage extends StatefulWidget {
  const ReplayPage({super.key, required this.doc});

  final PaintingDoc doc;

  /// Finds the replayed painting in tests.
  static const paperKey = Key('replayPaper');

  @override
  State<ReplayPage> createState() => ReplayPageState();
}

class ReplayPageState extends State<ReplayPage>
    with SingleTickerProviderStateMixin {
  late final timeline = ReplayTimeline(widget.doc.strokes);
  late final Size _size = paintingSize(widget.doc);

  /// Seconds into the replay.
  final time = ValueNotifier<double>(0);
  final _cache = LayeredCache();
  late final Ticker _ticker = createTicker(_tick);
  Duration _last = Duration.zero;
  double speed = 1;
  static const speeds = [0.5, 1.0, 2.0, 4.0];

  bool get playing => _ticker.isActive;

  /// Saving the GIF: how far along, or null when not saving.
  final _saving = ValueNotifier<double?>(null);
  bool _cancelSave = false;

  @override
  void initState() {
    super.initState();
    // Pictures are decoded first time round; then paint them for real.
    Photos.ready([for (final s in widget.doc.strokes) ?s.photo]).then((_) {
      if (!mounted) return;
      _cache.dispose();
      setState(() {});
    });
    _play();
  }

  @override
  void dispose() {
    _cancelSave = true;
    _ticker.dispose();
    time.dispose();
    _saving.dispose();
    _cache.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    final next = time.value + dt * speed;
    if (next >= timeline.total) {
      time.value = timeline.total;
      _pause();
    } else {
      time.value = next;
    }
  }

  void _play() {
    // At the end, play from the start again.
    if (time.value >= timeline.total) time.value = 0;
    _last = Duration.zero;
    _ticker.start();
    setState(() {});
  }

  void _pause() {
    _ticker.stop();
    if (mounted) setState(() {});
  }

  Future<void> _saveGif() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final origin = shareOrigin(context);
    _cancelSave = false;
    _saving.value = 0;
    try {
      final gif = await replayGif(
        widget.doc.strokes,
        _size,
        widget.doc.paper,
        layers: widget.doc.layers,
        // Browsers encode on the screen's thread: fewer, smaller frames.
        maxSide: kIsWeb ? 320 : 400,
        fps: kIsWeb ? 8 : 10,
        onProgress: (p) => _saving.value = p,
        cancelled: () => _cancelSave,
      );
      if (gif == null || !mounted) return;
      await shareExportedFile(
          ExportedFile(gif, s.replayFileName(widget.doc.meta.name), 'image/gif'),
          origin);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(s.exportFailed(e))));
    } finally {
      if (mounted) _saving.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: AppLogoTitle(
          text: s.replay,
          subtitle: widget.doc.meta.name,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _size.width / _size.height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.14),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        child: SizedBox.fromSize(
                          size: _size,
                          child: Semantics(
                            label: s.replayLabel(widget.doc.meta.name),
                            child: RepaintBoundary(
                              child: CustomPaint(
                                key: ReplayPage.paperKey,
                                size: _size,
                                painter: _ReplayPainter(this),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _controls(s),
          ],
        ),
      ),
    );
  }

  Widget _controls(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        children: [
          IconButton.filled(
            tooltip: playing ? s.pause : s.play,
            iconSize: 28,
            icon: Icon(
                playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
            onPressed: playing ? _pause : _play,
          ),
          SizedBox(
            width: 260,
            child: ValueListenableBuilder(
              valueListenable: time,
              builder: (context, t, _) => Slider(
                value: t.clamp(0, timeline.total),
                max: math.max(timeline.total, 0.001),
                semanticFormatterCallback: (v) =>
                    s.percent(timeline.total == 0 ? 1 : v / timeline.total),
                onChanged: (v) {
                  _pause();
                  time.value = v;
                },
              ),
            ),
          ),
          SegmentedButton<double>(
            showSelectedIcon: false,
            segments: [
              for (final x in speeds)
                ButtonSegment(value: x, label: Text(_speedLabel(x))),
            ],
            selected: {speed},
            onSelectionChanged: (picked) =>
                setState(() => speed = picked.first),
          ),
          ValueListenableBuilder(
            valueListenable: _saving,
            builder: (context, saving, _) => saving == null
                ? FilledButton.tonalIcon(
                    icon: const Icon(Icons.gif_box_rounded),
                    label: Text(s.saveGif),
                    onPressed: widget.doc.strokes.isEmpty ? null : _saveGif,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                            value: saving, semanticsLabel: s.makingGif),
                      ),
                      IconButton(
                        tooltip: s.cancel,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => _cancelSave = true,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  static String _speedLabel(double x) =>
      x == 0.5 ? '½×' : '${x.toStringAsFixed(0)}×';
}

class _ReplayPainter extends CustomPainter {
  _ReplayPainter(this.page) : super(repaint: page.time);

  final ReplayPageState page;

  @override
  void paint(Canvas canvas, Size size) {
    final ratio = math.min(
        3.0, 2048 / math.max(size.width, size.height));
    paintReplayFrame(canvas, size, page.timeline, page.time.value,
        page.widget.doc.paper, page.widget.doc.layers, page._cache, ratio);
  }

  @override
  bool shouldRepaint(_ReplayPainter old) => old.page != page;
}
