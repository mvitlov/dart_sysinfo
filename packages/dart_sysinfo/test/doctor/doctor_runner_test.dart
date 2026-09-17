import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';
import 'package:dart_sysinfo/src/doctor/doctor_runner.dart';
import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:dart_sysinfo/src/doctor/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('DoctorRunner', () {
    late List<String> lines;

    setUp(() {
      lines = [];
    });

    test('returns 0 when all checks pass', () async {
      final runner = DoctorRunner(
        checks: [_FakeCheck(ok: true, summary: 'pass')],
        context: _testContext(),
        writeLine: lines.add,
      );

      expect(await runner.run(), 0);
      expect(lines, ['[OK]    pass']);
    });

    test('returns 1 when any check fails', () async {
      final runner = DoctorRunner(
        checks: [
          _FakeCheck(ok: true, summary: 'pass'),
          _FakeCheck(
            ok: false,
            summary: 'fail',
            fixCommand: 'fix-it',
          ),
        ],
        context: _testContext(),
        writeLine: lines.add,
      );

      expect(await runner.run(), 1);
      expect(
        lines,
        [
          '[OK]    pass',
          '[FAIL]  fail -> fix: fix-it',
        ],
      );
    });

    test('skipped checks do not fail the run', () async {
      final runner = DoctorRunner(
        checks: [
          _FakeCheck(
            ok: true,
            skipped: true,
            summary: 'skipped item',
          ),
        ],
        context: _testContext(),
        writeLine: lines.add,
      );

      expect(await runner.run(), 0);
      expect(lines, ['[SKIP]  skipped item']);
    });
  });
}

DoctorContext _testContext() {
  return DoctorContext(
    packageRoot: '/tmp/dart_sysinfo',
    processRunner: const _NoopProcessRunner(),
    host: const HostEnvironment(operatingSystem: 'linux'),
    environment: {},
  );
}

class _FakeCheck implements DoctorCheck {
  _FakeCheck({
    required this.ok,
    required this.summary,
    this.fixCommand,
    this.skipped = false,
  });

  final bool ok;
  final String summary;
  final String? fixCommand;
  final bool skipped;

  @override
  String get name => 'Fake';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    return DoctorResult(
      ok: ok,
      summary: summary,
      fixCommand: fixCommand,
      skipped: skipped,
    );
  }
}

class _NoopProcessRunner implements ProcessRunner {
  const _NoopProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) {
    return Future.value(ProcessResult(0, 0, '', ''));
  }
}
