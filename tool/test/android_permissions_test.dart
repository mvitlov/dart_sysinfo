import 'dart:io';

import 'package:test/test.dart';

import '../ci/android_permissions/checker.dart';

void main() {
  group('AndroidPermissionChecker', () {
    test('passes on this repo', () {
      final violations = AndroidPermissionChecker(
        repoRoot: Directory.current,
      ).check();
      expect(violations, isEmpty);
    });

    test('passes on the valid fixture', () {
      final fixture = Directory(
        'tool/test/testdata/android_permissions/valid',
      );
      final violations = AndroidPermissionChecker(repoRoot: fixture).check();
      expect(violations, isEmpty);
    });

    test('fails when example manifest is missing network permissions', () {
      final fixture = Directory(
        'tool/test/testdata/android_permissions/missing_network_perm',
      );
      final violations = AndroidPermissionChecker(repoRoot: fixture).check();
      expect(
        violations.map((v) => v.domain),
        contains('network'),
      );
      expect(
        violations.map((v) => v.message).join('\n'),
        contains('ACCESS_NETWORK_STATE'),
      );
    });

    test('fails when plugin manifest merges permissions', () {
      final fixture = Directory(
        'tool/test/testdata/android_permissions/plugin_has_permission',
      );
      final violations = AndroidPermissionChecker(repoRoot: fixture).check();
      expect(
        violations.map((v) => v.message).join('\n'),
        contains('silent merge forbidden'),
      );
    });
  });
}
