import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';
import 'package:dart_sysinfo/src/prebuilt/manifest.dart';
import 'package:dart_sysinfo/src/prebuilt/prebuilt_runner.dart';

/// Reports prebuilt manifest version, ABI, and target availability (M3-06).
class PrebuiltCheck implements DoctorCheck {
  const PrebuiltCheck();

  @override
  String get name => 'Prebuilt manifest';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    final manifestPath =
        '${context.packageRoot}${Platform.pathSeparator}$defaultManifestRelativePath';
    final manifestFile = File(manifestPath);
    if (!manifestFile.existsSync()) {
      return DoctorResult(
        ok: false,
        summary: 'prebuilt/manifest.json missing',
        fixCommand:
            'restore packages/dart_sysinfo/prebuilt/manifest.json from git',
      );
    }

    try {
      final manifest = PrebuiltManifest.loadFile(manifestFile.path);
      final packageVersion = readPackageVersion(
        packageRoot: Uri.directory(context.packageRoot),
      );
      final targets = manifest.artifacts.keys.toList()..sort();
      final targetSummary = targets.isEmpty
          ? 'no artifacts pinned yet'
          : 'artifacts: ${targets.join(", ")}';

      final versionOk = manifest.packageVersion.isEmpty ||
          packageVersion.isEmpty ||
          manifest.packageVersion == packageVersion;
      final abiOk = manifest.abi == prebuiltExpectedAbi;

      if (!versionOk || !abiOk) {
        return DoctorResult(
          ok: false,
          summary:
              'manifest mismatch (packageVersion=${manifest.packageVersion}, '
              'abi=${manifest.abi}; pubspec=$packageVersion, '
              'expectedAbi=$prebuiltExpectedAbi; $targetSummary)',
          fixCommand:
              'cut a new prebuilt-v* release or run '
              'tool/release/build_linux_prebuilt.sh',
        );
      }

      return DoctorResult(
        ok: true,
        summary:
            'manifest ok (packageVersion=${manifest.packageVersion}, '
            'abi=${manifest.abi}; $targetSummary)',
      );
    } on Object catch (error) {
      return DoctorResult(
        ok: false,
        summary: 'invalid prebuilt/manifest.json: $error',
        fixCommand: 'fix JSON schema per TDD §9.4',
      );
    }
  }
}
