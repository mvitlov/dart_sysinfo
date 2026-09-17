import 'dart:io';

/// Abstraction over [Process.run] for testability.
abstract interface class ProcessRunner {
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  });
}

/// Production [ProcessRunner] backed by [Process.run].
class IoProcessRunner implements ProcessRunner {
  const IoProcessRunner();

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    Map<String, String>? environment,
  }) {
    return Process.run(
      executable,
      arguments,
      environment: environment,
      runInShell: true,
    );
  }
}
