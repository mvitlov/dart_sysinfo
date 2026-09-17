import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';

/// Verifies Android NDK presence, version, and env vars (TDD §6).
class AndroidNdkCheck implements DoctorCheck {
  const AndroidNdkCheck();

  static const _ndkInstallFix = r'sdkmanager --install "ndk;28.2.13676358" && '
      r'export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk/28.2.13676358"';

  @override
  String get name => 'Android NDK';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    final ndkRoot = context.env('ANDROID_NDK_ROOT') ??
        context.env('ANDROID_NDK_HOME');

    if (ndkRoot == null || ndkRoot.isEmpty) {
      return const DoctorResult(
        ok: false,
        summary: 'ANDROID_NDK_ROOT (or ANDROID_NDK_HOME) is not set',
        fixCommand: _ndkInstallFix,
      );
    }

    final sourceProperties = File('$ndkRoot/source.properties');
    if (!sourceProperties.existsSync()) {
      return const DoctorResult(
        ok: false,
        summary: 'NDK source.properties not found at ANDROID_NDK_ROOT',
        fixCommand:
            'Reinstall NDK r28+ via Android SDK Manager and set ANDROID_NDK_ROOT',
      );
    }

    final content = sourceProperties.readAsStringSync();
    final revisionMatch =
        RegExp(r'^Pkg\.Revision\s*=\s*(.+)$', multiLine: true)
            .firstMatch(content);
    if (revisionMatch == null) {
      return const DoctorResult(
        ok: false,
        summary: 'Could not parse Pkg.Revision from NDK source.properties',
        fixCommand:
            'Reinstall NDK r28+ via Android SDK Manager and set ANDROID_NDK_ROOT',
      );
    }

    final revision = revisionMatch.group(1)!.trim();
    final major = int.tryParse(revision.split('.').first);
    if (major == null || major < 28) {
      return DoctorResult(
        ok: false,
        summary: 'NDK version r$revision is below required r28',
        fixCommand: _ndkInstallFix,
      );
    }

    return DoctorResult(
      ok: true,
      summary: 'Android NDK r$revision at $ndkRoot',
    );
  }
}
