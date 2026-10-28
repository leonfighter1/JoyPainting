import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/gallery/backup_reminder.dart';
import 'package:jingyao_paint/gallery/painting_store.dart';
import 'package:jingyao_paint/gallery/storage_status_tile.dart';
import 'package:jingyao_paint/share/painting_export.dart';
import 'package:jingyao_paint/share/share_actions.dart';

import 'test_helpers.dart';
import 'widget_test.dart' show openTab, pumpApp;

final _now = DateTime(2026, 10, 28, 12);

/// [n] painting entries made [daysAgo] days ago (and changed an hour later).
List<PaintingMeta> made(int n, int daysAgo) => [
  for (var i = 0; i < n; i++)
    sampleDoc('p$i', _now.subtract(Duration(days: daysAgo))).meta,
];

void main() {
  group('When to remind', () {
    test('never backed up: once there are three paintings, two weeks on', () {
      expect(BackupReminder.due(paintings: const [], now: _now), isFalse);
      expect(BackupReminder.due(paintings: made(2, 30), now: _now), isFalse);
      expect(BackupReminder.due(paintings: made(3, 10), now: _now), isFalse);
      expect(BackupReminder.due(paintings: made(3, 15), now: _now), isTrue);
    });

    test('a browser that may clear its storage: after one week', () {
      expect(
        BackupReminder.due(paintings: made(3, 8), now: _now, atRisk: true),
        isTrue,
      );
    });

    test('backed up: only when something changed since, two weeks on', () {
      final paintings = made(3, 20);
      expect(
        BackupReminder.due(
          paintings: paintings,
          now: _now,
          lastBackup: _now.subtract(const Duration(days: 30)),
        ),
        isTrue,
      );
      expect(
        BackupReminder.due(
          paintings: paintings,
          now: _now,
          lastBackup: _now.subtract(const Duration(days: 19)),
        ),
        isFalse,
        reason: 'nothing changed since that backup',
      );
      expect(
        BackupReminder.due(
          paintings: made(3, 5),
          now: _now,
          lastBackup: _now.subtract(const Duration(days: 10)),
        ),
        isFalse,
        reason: 'changed, but backed up only ten days ago',
      );
    });

    test('"later" puts it off', () {
      expect(
        BackupReminder.due(
          paintings: made(3, 30),
          now: _now,
          snoozedUntil: _now.add(const Duration(days: 1)),
        ),
        isFalse,
      );
    });
  });

  test('backups and "later" are kept per kid', () async {
    final settings = (await createTestApp(fresh: true)).settings;
    expect(settings.lastBackup, isNull);
    expect(settings.backupReminders, isTrue, reason: 'on by default');
    settings
      ..snoozeBackup(_now)
      ..markBackedUp(_now);
    expect(settings.lastBackup, _now);
    expect(settings.backupSnoozedUntil, isNull, reason: 'a backup ends it');
    final other = settings.addKid('Momo');
    settings.currentKidId = other.id;
    expect(settings.lastBackup, isNull);
  });

  group('The reminder in My Paintings', () {
    Future<TestApp> withOldPaintings(WidgetTester tester) async {
      final app = await createTestApp(prefs: {'flutter.backupReminders': true});
      for (var i = 0; i < 3; i++) {
        await app.store.save(
          sampleDoc('old$i', DateTime.now().subtract(const Duration(days: 40))),
          tinyPng,
        );
      }
      await pumpApp(tester, app: app);
      await openTab(tester, 1);
      return app;
    }

    testWidgets('one tap backs every painting up, and the reminder goes', (
      tester,
    ) async {
      final delivered = <ExportedFile>[];
      deliverExport = (file, origin) async => delivered.add(file);
      final app = await withOldPaintings(tester);
      expect(find.text('这些画还没有备份过'), findsOneWidget);
      await tester.tap(find.text('一键备份'));
      await tester.pumpAndSettle();
      expect(delivered, hasLength(1));
      final zip = ZipDecoder().decodeBytes(delivered.single.bytes);
      expect(zip.files.where((f) => f.isFile), hasLength(3));
      expect(app.settings.lastBackup, isNotNull);
      expect(find.text('一键备份'), findsNothing);
    });

    testWidgets('"later" hides it for a week; Settings turns it off', (
      tester,
    ) async {
      final app = await withOldPaintings(tester);
      await tester.tap(find.text('以后再说'));
      await tester.pumpAndSettle();
      expect(find.text('一键备份'), findsNothing);
      expect(
        app.settings.backupSnoozedUntil!.difference(DateTime.now()).inDays,
        inInclusiveRange(6, 7),
      );
      app.settings
        ..snoozeBackup(DateTime.now())
        ..backupReminders = false;
      await tester.pumpAndSettle();
      expect(find.text('一键备份'), findsNothing);
      app.settings.backupReminders = true;
      await tester.pumpAndSettle();
      expect(find.text('一键备份'), findsOneWidget);
    });
  });

  group("The browser's promise to keep the paintings", () {
    Future<void> pumpTile(
      WidgetTester tester, {
      required bool atRisk,
      required bool grants,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StorageStatusTile(
              atRisk: () async => atRisk,
              askToKeep: () async => grants,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('kept: says so, with nothing to ask', (tester) async {
      await pumpTile(tester, atRisk: false, grants: true);
      expect(find.text('This browser keeps the paintings'), findsOneWidget);
      expect(find.text('Ask to keep them'), findsNothing);
    });

    testWidgets('at risk: asks; a no says how to get a yes', (tester) async {
      await pumpTile(tester, atRisk: true, grants: false);
      expect(
        find.text('The browser may clear the paintings when space runs low'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ask to keep them'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Bookmark this page'), findsOneWidget);
      expect(
        find.text('Ask to keep them'),
        findsOneWidget,
        reason: 'try again',
      );
    });

    testWidgets('at risk: a yes turns it into kept', (tester) async {
      await pumpTile(tester, atRisk: true, grants: true);
      await tester.tap(find.text('Ask to keep them'));
      await tester.pumpAndSettle();
      expect(find.text('This browser keeps the paintings'), findsOneWidget);
      expect(find.text('The browser will keep the paintings'), findsOneWidget);
    });
  });
}
