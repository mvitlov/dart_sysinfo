import 'package:dart_sysinfo/src/doctor/doctor_check.dart' show DoctorCheck;

/// Result of a single [DoctorCheck] run.
class DoctorResult {
  const DoctorResult({
    required this.ok,
    required this.summary,
    this.fixCommand,
    this.skipped = false,
  });

  final bool ok;
  final String summary;
  final String? fixCommand;
  final bool skipped;

  /// Formats output per TDD §6: `[OK]` / `[FAIL]` / `[SKIP]` lines.
  String format() {
    if (skipped) {
      return '[SKIP]  $summary';
    }
    if (ok) {
      return '[OK]    $summary';
    }
    if (fixCommand != null) {
      return '[FAIL]  $summary -> fix: $fixCommand';
    }
    return '[FAIL]  $summary';
  }
}
