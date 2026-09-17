import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';

/// Writes a single formatted doctor result line.
typedef DoctorWriter = void Function(String line);

/// Runs all [DoctorCheck]s in order and aggregates the exit code.
class DoctorRunner {
  DoctorRunner({
    required this.checks,
    this.context,
    DoctorWriter? writeLine,
  }) : _writeLine = writeLine ?? _stdoutWriteLine;

  final List<DoctorCheck> checks;
  final DoctorContext? context;
  final DoctorWriter _writeLine;

  static void _stdoutWriteLine(String line) => stdout.writeln(line);

  Future<int> run() async {
    final ctx = context ?? DoctorContext.fromScript();
    var allOk = true;

    for (final check in checks) {
      final result = await check.run(ctx);
      _writeLine(result.format());
      if (!result.ok) {
        allOk = false;
      }
    }

    return allOk ? 0 : 1;
  }
}
