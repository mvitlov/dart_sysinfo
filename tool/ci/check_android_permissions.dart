/// Android permission lint CI check (M3-05, PRD §2.5).
///
/// Usage:
///   fvm dart run tool/ci/check_android_permissions.dart [--repo-root PATH]
library;

import 'dart:io';

import 'android_permissions/checker.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(
      'Usage: dart run tool/ci/check_android_permissions.dart '
      '[--repo-root PATH]',
    );
    exit(0);
  }

  String? repoRootArg;
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith('--repo-root=')) {
      repoRootArg = arg.substring('--repo-root='.length);
    } else if (arg == '--repo-root') {
      if (i + 1 >= args.length) {
        stderr.writeln('Missing value for --repo-root');
        exit(64);
      }
      repoRootArg = args[++i];
    } else {
      stderr.writeln('Unknown argument: $arg');
      exit(64);
    }
  }

  final scriptDir = File(Platform.script.toFilePath()).parent;
  final repoRoot = Directory(
    repoRootArg ?? scriptDir.parent.parent.path,
  );
  final checker = AndroidPermissionChecker(repoRoot: repoRoot);
  final violations = checker.check();
  if (violations.isEmpty) {
    stdout.writeln('Android permission lint OK');
    exit(0);
  }

  stderr.writeln('Android permission lint failed:');
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  exit(1);
}
