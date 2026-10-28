import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../settings.dart';
import 'music_library.dart';

/// Plays one track once. Behind an interface so tests can use a fake:
/// there's no sound hardware in a widget test.
abstract class MusicEngine {
  /// Starts [source] from the beginning at [volume] (0 to 1).
  Future<void> play(MusicSource source, double volume);

  /// Called when the track reaches its end.
  set onComplete(VoidCallback? callback);
  Future<void> pause();
  Future<void> resume();
  Future<void> setVolume(double volume);
  Future<void> dispose();
}

/// The real player (audioplayers: Android's media player, Windows Media
/// Foundation, or the browser's audio element).
class AudioPlayersEngine implements MusicEngine {
  AudioPlayersEngine() {
    _completions = _player.onPlayerComplete.listen((_) => _onComplete?.call());
  }

  final _player = AudioPlayer(playerId: 'backgroundMusic');
  late final StreamSubscription<void> _completions;
  VoidCallback? _onComplete;
  bool _contextSet = false;

  @override
  set onComplete(VoidCallback? callback) => _onComplete = callback;

  /// On iOS, background music uses the "ambient" audio session, as games
  /// do: the silent switch mutes it, and it plays along with other apps'
  /// audio instead of stopping it. (audioplayers' default would ignore the
  /// silent switch.) Android keeps its usual media playback.
  static final _iosContext = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.ambient),
  );

  @override
  Future<void> play(MusicSource source, double volume) async {
    if (!_contextSet && defaultTargetPlatform == TargetPlatform.iOS) {
      await _player.setAudioContext(_iosContext);
      _contextSet = true;
    }
    await _player.stop();
    // Once: BackgroundMusic adds a pause before the next one (or this one
    // again on repeat).
    await _player.setReleaseMode(ReleaseMode.stop);
    await _player.play(
      switch (source) {
        AssetMusic(:final path) => AssetSource(path),
        FileMusic(:final path) => DeviceFileSource(path),
        BytesMusic(:final bytes) => BytesSource(bytes),
      },
      volume: volume,
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.resume();

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> dispose() async {
    await _completions.cancel();
    await _player.dispose();
  }
}

/// Keeps the background music in step with the settings (on/off, track,
/// volume, play order) and pauses it while the app is in the background.
class BackgroundMusic with WidgetsBindingObserver {
  BackgroundMusic({
    required this.settings,
    required this.library,
    required this.engine,
    this.needsTouchToPlay = kIsWeb,
    math.Random? random,
  }) : _random = random ?? math.Random();

  final math.Random _random;

  final AppSettings settings;
  final MusicLibrary library;
  final MusicEngine engine;

  /// Browsers only play sound once the user has touched or clicked the
  /// page. Until then a failed start just waits for [userTouched] instead of
  /// reporting an error.
  final bool needsTouchToPlay;

  /// Called when a track can't be played (say, an unsupported file); the
  /// music then switches back to the first built-in track.
  void Function(Object error)? onError;

  /// How long a player call may take. A browser that hasn't been touched yet
  /// can leave a start pending forever; without a limit that would hold up
  /// every later change.
  static const callTimeout = Duration(seconds: 8);

  /// On the web, how many failed starts after touches count as "the browser
  /// still says no" (a finger landing isn't enough for some browsers, only
  /// lifting it is) before a real error is reported.
  static const touchRetries = 3;

  /// The quiet after each track before the next one (or, on repeat, the
  /// same one again) starts.
  static const gap = Duration(seconds: 3);

  bool _foreground = true;
  bool _touched = false;
  int _failedAfterTouch = 0;
  bool _waitingForTouch = false;
  bool _playing = false;
  String? _loaded;
  double? _volume;
  Timer? _quiet;
  Future<void> _queue = Future.value();

  void start() {
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_sync);
    library.addListener(_sync);
    engine.onComplete = _ended;
    // A saved choice can point to a track that's gone (an upload on the web
    // lasts only until the page is reloaded): back to a bundled one.
    if (!library.tracks.any((t) => t.id == settings.musicTrack)) {
      settings.musicTrack = MusicLibrary.builtIn.first.id;
    }
    // Shuffle starts somewhere new each time the app opens.
    if (settings.musicMode == MusicMode.shuffle && library.tracks.length > 1) {
      settings.musicTrack =
          library.tracks[_random.nextInt(library.tracks.length)].id;
    }
    // Browsers refuse sound before the first touch, and a start tried then
    // can hang: wait for the touch instead of trying.
    if (needsTouchToPlay) _waitingForTouch = true;
    _sync();
  }

  /// A track ended: the next one starts after [gap]. Music turned off (or
  /// the app left) meanwhile starts with that one when it comes back; a
  /// track picked meanwhile plays at once and ends the quiet.
  void _ended() {
    _quiet?.cancel();
    _quiet = Timer(gap, _next);
  }

  /// Picks the track after the one that ended: the next one, a random other
  /// one, or the same one on repeat. Setting it starts it, even when it's
  /// the same track again.
  void _next() {
    _quiet = null;
    final tracks = library.tracks;
    final current = library.trackById(settings.musicTrack);
    final at = tracks.indexWhere((t) => t.id == current.id);
    final MusicTrack next;
    if (settings.musicMode == MusicMode.repeatOne) {
      next = current;
    } else if (settings.musicMode == MusicMode.shuffle && tracks.length > 1) {
      final others = [for (final t in tracks) if (t.id != current.id) t];
      next = others[_random.nextInt(others.length)];
    } else {
      next = tracks[(at + 1) % tracks.length];
    }
    _loaded = null;
    settings.musicTrack = next.id;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    settings.removeListener(_sync);
    library.removeListener(_sync);
    _quiet?.cancel();
    engine.onComplete = null;
    engine.dispose();
  }

  /// The user touched or clicked the app (see [needsTouchToPlay]): music that
  /// was waiting for it starts now.
  void userTouched() {
    _touched = true;
    if (_waitingForTouch) {
      _waitingForTouch = false;
      _sync();
    }
  }

  /// Paused or hidden means the user left the app (or turned the screen
  /// off). "Inactive" alone is a dialog or the notification shade on top,
  /// so the music keeps going.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _sync();
  }

  /// Settings can change many times a second (the volume slider), so the
  /// player calls run one after another, never overlapping.
  void _sync() => _queue = _queue.then((_) => _apply());

  /// A future that completes when every change so far has reached the
  /// player. For tests.
  Future<void> get settled => _queue;

  Future<void> _apply() async {
    if (!settings.musicOn || !_foreground) {
      if (_playing) {
        _playing = false;
        await engine.pause();
      }
      return;
    }
    // Blocked by the browser: only a touch can start it (userTouched).
    if (_waitingForTouch) return;
    if (!library.tracks.any((t) => t.id == settings.musicTrack)) {
      // Removed or forgotten: this change comes back through _sync.
      settings.musicTrack = MusicLibrary.builtIn.first.id;
      return;
    }
    final track = library.trackById(settings.musicTrack);
    final volume = settings.musicVolume;
    try {
      if (_loaded != track.id) {
        _quiet?.cancel();
        _quiet = null;
        _loaded = track.id;
        _volume = volume;
        _playing = true;
        await engine.play(track.source, volume).timeout(callTimeout);
        _failedAfterTouch = 0;
        return;
      }
      // Between two tracks: nothing to resume.
      if (_quiet != null) return;
      if (!_playing) {
        _playing = true;
        await engine.resume().timeout(callTimeout);
      }
      if (_volume != volume) {
        _volume = volume;
        await engine.setVolume(volume);
      }
    } catch (e) {
      _loaded = null;
      _playing = false;
      if (needsTouchToPlay &&
          (!_touched || ++_failedAfterTouch < touchRetries)) {
        _waitingForTouch = true;
        return;
      }
      _failedAfterTouch = 0;
      onError?.call(e);
      if (!track.builtIn) {
        // Falls back to a track that always works (and plays it).
        settings.musicTrack = MusicLibrary.builtIn.first.id;
      }
    }
  }
}
