import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';

/// Verifies Xcode on macOS hosts (TDD §6).
class XcodeCheck implements DoctorCheck {
  const XcodeCheck();

  @override
  String get name => 'Xcode';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    if (!context.host.isMacOS) {
      return DoctorResult(
        ok: true,
        skipped: true,
        summary: 'Xcode: not applicable on ${context.host.operatingSystem}',
      );
    }

    final result = await context.processRunner.run('xcodebuild', [
      '-version',
    ]);
    if (result.exitCode != 0) {
      return const DoctorResult(
        ok: false,
        summary: 'xcodebuild not available',
        fixCommand: 'xcode-select --install',
      );
    }

    final output = result.stdout.toString().trim();
    final versionMatch =
        RegExp(r'Xcode (\d+\.\d+)').firstMatch(output);
    if (versionMatch == null) {
      return const DoctorResult(
        ok: false,
        summary: 'Could not parse Xcode version',
        fixCommand: 'xcode-select --install',
      );
    }

    return DoctorResult(
      ok: true,
      summary: 'Xcode ${versionMatch.group(1)} installed',
    );
  }
}
