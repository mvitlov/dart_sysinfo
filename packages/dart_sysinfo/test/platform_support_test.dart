import 'dart:io';

import 'package:test/test.dart';

/// Native platforms supported by dart_sysinfo (PRD §1.6).
const _supportedPlatforms = {
  'android',
  'ios',
  'linux',
  'macos',
  'windows',
};

void main() {
  group('Platform support declarations (M0-07, PRD §1.6)', () {
    final dartSysinfoPubspec = File('pubspec.yaml');
    final flutterPubspec = File('../dart_sysinfo_flutter/pubspec.yaml');

    test(
      'dart_sysinfo pubspec declares exactly 5 native platforms, no web',
      () {
        _assertPlatforms(dartSysinfoPubspec, _supportedPlatforms);
      },
    );

    test(
      'dart_sysinfo_flutter pubspec declares 5 native platforms, no web',
      () {
        _assertPlatforms(flutterPubspec, _supportedPlatforms);
      },
      tags: ['monorepo'],
    );

    test('dart_sysinfo flutter.plugin.platforms excludes web', () {
      final content = dartSysinfoPubspec.readAsStringSync();
      final pluginPlatforms = _extractYamlMapKeys(
        content,
        afterKey: 'flutter:',
        nestedPath: ['plugin', 'platforms'],
      );
      expect(pluginPlatforms, _supportedPlatforms);
      expect(pluginPlatforms, isNot(contains('web')));
    });

    test(
      'neither package declares web plugin implementation',
      () {
        for (final file in [dartSysinfoPubspec, flutterPubspec]) {
          final content = file.readAsStringSync();
          expect(content, isNot(contains('fileName:')));
          expect(content, isNot(contains('pluginClass:')));
          final webPluginBlock = RegExp(
            r'web:\s*\n\s*(pluginClass|dartPluginClass|fileName):',
          );
          expect(webPluginBlock.hasMatch(content), isFalse);
        }
      },
      tags: ['monorepo'],
    );
  });
}

void _assertPlatforms(File pubspec, Set<String> expected) {
  final content = pubspec.readAsStringSync();
  final platforms = _extractYamlMapKeys(content, topLevelKey: 'platforms');
  expect(platforms, expected);
  expect(platforms, isNot(contains('web')));
}

/// Extracts keys from a YAML map at [topLevelKey] or nested under [nestedPath]
/// after finding [afterKey].
Set<String> _extractYamlMapKeys(
  String content, {
  String? topLevelKey,
  String? afterKey,
  List<String>? nestedPath,
}) {
  final lines = content.split('\n');
  var startIndex = -1;
  var baseIndent = 0;

  if (topLevelKey != null) {
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trimLeft().startsWith('$topLevelKey:')) {
        startIndex = i + 1;
        baseIndent = _leadingSpaces(lines[i]) + 2;
        break;
      }
    }
  } else if (afterKey != null && nestedPath != null) {
    var depth = 0;
    final targetDepth = nestedPath.length;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      if (depth == 0 && trimmed.startsWith(afterKey)) {
        baseIndent = _leadingSpaces(line) + 2;
        depth = 1;
        continue;
      }
      if (depth > 0 && depth <= targetDepth) {
        final key = nestedPath[depth - 1];
        if (trimmed.startsWith('$key:')) {
          if (depth == targetDepth) {
            startIndex = i + 1;
            baseIndent = _leadingSpaces(line) + 2;
            break;
          }
          depth++;
        }
      }
    }
  }

  if (startIndex < 0) {
    fail('Could not find platforms map in pubspec');
  }

  final keys = <String>{};
  for (var i = startIndex; i < lines.length; i++) {
    final line = lines[i];
    if (line.trim().isEmpty || line.trimLeft().startsWith('#')) {
      continue;
    }
    final indent = _leadingSpaces(line);
    if (indent < baseIndent) {
      break;
    }
    if (indent == baseIndent) {
      final match = RegExp(r'^(\w+):').firstMatch(line.trimLeft());
      if (match != null) {
        keys.add(match.group(1)!);
      }
    }
  }
  return keys;
}

int _leadingSpaces(String line) {
  var count = 0;
  for (final c in line.codeUnits) {
    if (c == 32) {
      count++;
    } else {
      break;
    }
  }
  return count;
}
