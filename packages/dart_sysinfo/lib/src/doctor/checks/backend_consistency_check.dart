import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';

/// Verifies Cargokit-default backend wiring for M0 (TDD §6).
class BackendConsistencyCheck implements DoctorCheck {
  const BackendConsistencyCheck();

  static const _supportedPlatforms = [
    'android',
    'ios',
    'linux',
    'macos',
    'windows',
  ];

  @override
  String get name => 'Backend consistency';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    final root = context.packageRoot;

    if (!Directory('$root/cargokit').existsSync()) {
      return const DoctorResult(
        ok: false,
        summary: 'Cargokit directory missing (expected default backend for M0)',
        fixCommand:
            'git checkout packages/dart_sysinfo/cargokit/  # restore vendored Cargokit subtree',
      );
    }

    for (final platform in _supportedPlatforms) {
      if (!Directory('$root/$platform').existsSync()) {
        return DoctorResult(
          ok: false,
          summary: 'Platform wiring directory missing: $platform/',
          fixCommand:
              'git checkout packages/dart_sysinfo/$platform/  # restore platform wiring',
        );
      }
    }

    final hookFile = File('$root/hook/build.dart');
    if (!hookFile.existsSync()) {
      return const DoctorResult(
        ok: false,
        summary: 'hook/build.dart missing',
        fixCommand:
            'git checkout packages/dart_sysinfo/hook/build.dart  # restore M0 placeholder',
      );
    }

    final hookContent = hookFile.readAsStringSync();
    if (hookContent.contains('flutter_rust_bridge_hooks')) {
      return const DoctorResult(
        ok: false,
        summary:
            'Native Assets hook activated prematurely (Cargokit is default until M2/M5)',
        fixCommand:
            'git checkout packages/dart_sysinfo/hook/build.dart  # restore M0 Cargokit-default placeholder',
      );
    }

    final gradleFile = File('$root/android/build.gradle');
    if (!gradleFile.existsSync()) {
      return const DoctorResult(
        ok: false,
        summary: 'android/build.gradle missing',
        fixCommand: 'git checkout packages/dart_sysinfo/android/build.gradle',
      );
    }

    final gradleContent = gradleFile.readAsStringSync();
    if (!gradleContent.contains('cargokit')) {
      return const DoctorResult(
        ok: false,
        summary: 'android/build.gradle does not reference Cargokit',
        fixCommand: 'git checkout packages/dart_sysinfo/android/build.gradle',
      );
    }

    final pubspecFile = File('$root/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      return const DoctorResult(
        ok: false,
        summary: 'pubspec.yaml not found in package root',
        fixCommand: 'git checkout packages/dart_sysinfo/pubspec.yaml',
      );
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    for (final platform in _supportedPlatforms) {
      if (!_hasFfiPluginForPlatform(pubspecContent, platform)) {
        return DoctorResult(
          ok: false,
          summary:
              'pubspec.yaml missing ffiPlugin for platform: $platform',
          fixCommand: 'git checkout packages/dart_sysinfo/pubspec.yaml',
        );
      }
    }

    return const DoctorResult(
      ok: true,
      summary:
          'Cargokit-default backend wiring consistent (M0 placeholder hook)',
    );
  }

  static bool _hasFfiPluginForPlatform(String pubspec, String platform) {
    return RegExp(
      '$platform\\s*:\\s*\\n\\s*ffiPlugin:\\s*true',
      multiLine: true,
    ).hasMatch(pubspec);
  }
}
