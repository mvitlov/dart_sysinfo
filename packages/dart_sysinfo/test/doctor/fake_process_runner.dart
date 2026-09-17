import 'dart:io';

import 'package:dart_sysinfo/src/doctor/process_runner.dart';

/// Test double for [ProcessRunner].
class FakeProcessRunner implements ProcessRunner {
  FakeProcessRunner(this._handlers);

  final Map<String, ProcessResult Function(List<String> args)> _handlers;

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) async {
    final handler = _handlers[executable];
    if (handler == null) {
      return ProcessResult(
        0,
        127,
        '',
        'Command not found: $executable',
      );
    }
    return handler(arguments);
  }
}

ProcessResult okResult(String stdout, {int exitCode = 0}) {
  return ProcessResult(0, exitCode, stdout, '');
}

ProcessResult failResult({String stderr = '', int exitCode = 1}) {
  return ProcessResult(0, exitCode, '', stderr);
}
