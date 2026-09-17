import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';

/// Verifies CocoaPods on macOS hosts (TDD §6).
class CocoaPodsCheck implements DoctorCheck {
  const CocoaPodsCheck();

  @override
  String get name => 'CocoaPods';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    if (!context.host.isMacOS) {
      return DoctorResult(
        ok: true,
        skipped: true,
        summary:
            'CocoaPods: not applicable on ${context.host.operatingSystem}',
      );
    }

    final result = await context.processRunner.run('pod', ['--version']);
    if (result.exitCode != 0) {
      return const DoctorResult(
        ok: false,
        summary: 'CocoaPods (pod) not found',
        fixCommand: 'sudo gem install cocoapods',
      );
    }

    final version = result.stdout.toString().trim();
    return DoctorResult(
      ok: true,
      summary: 'CocoaPods $version installed',
    );
  }
}
