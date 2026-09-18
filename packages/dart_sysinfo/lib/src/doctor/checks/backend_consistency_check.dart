import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';

/// Verifies dual-backend wiring: Cargokit (default) + Native Assets hook (M2).
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
        summary: 'Cargokit directory missing (expected default backend)',
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
            'git checkout packages/dart_sysinfo/hook/build.dart  # restore build hook',
      );
    }

    final hookContent = hookFile.readAsStringSync();
    if (!hookContent.contains('flutter_rust_bridge_hooks') ||
        !hookContent.contains('FlutterRustBridgeNativeAssetsBuilder')) {
      return const DoctorResult(
        ok: false,
        summary:
            'Native Assets hook missing (expected FlutterRustBridgeNativeAssetsBuilder)',
        fixCommand:
            'git checkout packages/dart_sysinfo/hook/build.dart  # restore M2 build hook',
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
    if (!pubspecContent.contains('flutter_rust_bridge_hooks')) {
      return const DoctorResult(
        ok: false,
        summary: 'pubspec.yaml missing flutter_rust_bridge_hooks dependency',
        fixCommand: 'git checkout packages/dart_sysinfo/pubspec.yaml',
      );
    }

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
          'Dual-backend wiring OK (Cargokit default + Native Assets hook)',
    );
  }

  static bool _hasFfiPluginForPlatform(String pubspec, String platform) {
    return RegExp(
      '$platform\\s*:\\s*\\n\\s*ffiPlugin:\\s*true',
      multiLine: true,
    ).hasMatch(pubspec);
  }
}
