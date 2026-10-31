import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jingyao_paint/settings_page.dart';

void main() {
  test('Settings shows the version in pubspec.yaml', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    final version = line.substring('version:'.length).trim().split('+').first;
    expect(appVersion, version);
  });
}
