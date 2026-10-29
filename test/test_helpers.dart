import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:jingyao_paint/drawing/canvas/tool_catalog.dart';
import 'package:jingyao_paint/drawing/stroke.dart';
import 'package:jingyao_paint/family.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/music/background_music.dart';
import 'package:jingyao_paint/music/music_library.dart';
import 'package:jingyao_paint/painting_session.dart';
import 'package:jingyao_paint/settings.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A real 1x1 PNG, so code that expects image bytes gets valid ones.
final tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Thumbnails are faked because real PNG encoding never completes under the
/// fake clock widget tests run on.
Future<Uint8List> fakeThumbnailer(
  List<Stroke> strokes,
  Size size,
  Color paper,
  List<PaintingLayer> layers,
) async => tinyPng;

class TestApp {
  TestApp(this.settings, this.backend, this.session);

  final AppSettings settings;
  final MemoryStoreBackend backend;
  final PaintingSession session;
  final musicFiles = MemoryMusicFiles();
  late final music = MusicLibrary(musicFiles);
  final engine = FakeMusicEngine();
  late final player = BackgroundMusic(
    settings: settings,
    library: music,
    engine: engine,
  );

  /// The storage all kids' paintings share.
  late StoreBackend base;
  late final family = Family(
    settings: settings,
    backend: base,
    session: session,
    music: music,
  );

  PaintingStore get store => session.store;
}

/// Most tests run in Chinese with the first-start setup already done, as
/// the app was used before v2.1. [prefs] can change either.
final testDefaults = <String, Object>{
  'flutter.language': 'zh',
  'flutter.onboarded': true,
  // Most tests use every tool; v4_test covers the levels.
  'flutter.level': 'advanced',
  // Most tests count what My Paintings shows; backup_test covers the
  // backup reminder.
  'flutter.backupReminders': false,
  ...allSectionsOpen,
  ...allToolsAdded,
};

/// Every option added to the drawer, as before 6.0: most tests pick shapes,
/// textures and the rest directly. add_tools_test covers the basic ones.
final allToolsAdded = <String, Object>{
  'flutter.addedTools': ToolCatalog.addableKeys(),
};

/// Every tools drawer section open, as before 5.4: most tests pick options
/// from all of them. drawer_test covers which ones start closed.
const allSectionsOpen = <String, Object>{
  'flutter.toolSection.gradient': true,
  'flutter.toolSection.lightAndShadow': true,
  'flutter.toolSection.texture': true,
};

Future<TestApp> createTestApp({
  Map<String, Object> prefs = const {},
  StoreBackend? backend,
  bool fresh = false,
}) async {
  SharedPreferences.setMockInitialValues(
    fresh ? prefs : {...testDefaults, ...prefs},
  );
  final settings = await AppSettings.load();
  final memory = MemoryStoreBackend();
  final base = backend ?? memory;
  final session = PaintingSession(
    store: Family.storeFor(base, settings.currentKid),
    settings: settings,
    thumbnailer: fakeThumbnailer,
  );
  return TestApp(settings, memory, session)..base = base;
}

Stroke sampleStroke({BrushType brush = BrushType.pen, Color? color}) => Stroke(
  brush: brush,
  color: color ?? const Color(0xFFFF5A5F),
  size: 8,
  usesRealPressure: false,
  isComplete: true,
  points: const [
    PointVector(10, 10, 0.5),
    PointVector(40, 25, 0.6),
    PointVector(80, 60, 0.7),
  ],
);

PaintingDoc sampleDoc(String id, DateTime created, {int strokes = 1}) =>
    PaintingDoc(
      meta: PaintingMeta(
        id: id,
        createdAt: created,
        updatedAt: created.add(const Duration(hours: 1)),
        width: 400,
        height: 300,
        strokeCount: strokes,
      ),
      strokes: [for (var i = 0; i < strokes; i++) sampleStroke()],
    );

/// A backend whose writes always fail, for testing save errors.
class FailingBackend extends MemoryStoreBackend {
  @override
  Future<void> writeText(String name, String value) async =>
      throw Exception('disk full');
}

/// Records what the background music was told to do, instead of playing.
class FakeMusicEngine implements MusicEngine {
  final List<String> calls = [];
  MusicSource? source;
  double volume = 0;
  VoidCallback? _onComplete;

  @override
  set onComplete(VoidCallback? callback) => _onComplete = callback;

  /// The track playing reached its end.
  void finishTrack() => _onComplete?.call();

  /// Makes the next [play] fail, like an unplayable file.
  bool failNext = false;

  /// Makes the next [play] never finish, like a browser that hasn't been
  /// touched yet.
  bool hangNext = false;

  @override
  Future<void> play(MusicSource source, double volume) async {
    if (failNext) {
      failNext = false;
      throw Exception('cannot play');
    }
    if (hangNext) {
      hangNext = false;
      return Completer<void>().future;
    }
    this.source = source;
    this.volume = volume;
    calls.add('play');
  }

  @override
  Future<void> pause() async => calls.add('pause');

  @override
  Future<void> resume() async => calls.add('resume');

  @override
  Future<void> setVolume(double volume) async {
    this.volume = volume;
    calls.add('volume');
  }

  @override
  Future<void> dispose() async {}
}
