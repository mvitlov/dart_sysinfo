/// Domain scaffolding generator (M3-01, PRD §10.2).
///
/// Usage:
///   fvm dart run tool/new_domain.dart <name> [options]
library;

import 'dart:io';

import 'new_domain/generator.dart';
import 'new_domain/naming.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
    _printHelp();
    exit(0);
  }

  final positional = <String>[];
  var ttlMs = 500;
  var hasStream = false;
  var streamMethod = 'load';
  var dryRun = false;
  var skipPostSteps = false;
  String? fixtureRoot;

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg == '--dry-run') {
      dryRun = true;
    } else if (arg == '--stream') {
      hasStream = true;
    } else if (arg == '--skip-post-steps') {
      skipPostSteps = true;
    } else if (arg.startsWith('--ttl-ms=')) {
      ttlMs = int.parse(arg.substring('--ttl-ms='.length));
    } else if (arg.startsWith('--stream-method=')) {
      streamMethod = arg.substring('--stream-method='.length);
    } else if (arg.startsWith('--fixture-root=')) {
      fixtureRoot = arg.substring('--fixture-root='.length);
    } else if (arg.startsWith('-')) {
      stderr.writeln('Unknown flag: $arg');
      exit(64);
    } else {
      positional.add(arg);
    }
  }

  if (positional.length != 1) {
    stderr.writeln('Expected exactly one domain name argument.');
    _printHelp();
    exit(64);
  }

  try {
    final naming = DomainNaming.parse(
      rawName: positional.single,
      ttlMs: ttlMs,
      hasStream: hasStream,
      streamMethod: streamMethod,
    );

    final scriptDir = File(Platform.script.toFilePath()).parent;
    final repoRoot = Directory(fixtureRoot ?? scriptDir.parent.path);
    final templatesDir = Directory('${scriptDir.path}/new_domain/templates');

    await DomainGenerator(
      repoRoot: repoRoot,
      templatesDir: templatesDir,
      dryRun: dryRun,
      skipPostSteps: skipPostSteps || dryRun,
    ).run(naming);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exit(64);
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exit(1);
  }
}

void _printHelp() {
  stdout.writeln('''
Domain scaffolding generator (M3-01)

Usage:
  fvm dart run tool/new_domain.dart <name> [options]

Arguments:
  <name>                     Lowercase domain name (e.g. disks, network)

Options:
  --stream                   Include broadcast stream API (CPU pattern)
  --stream-method=<id>       Stream method name (default: load)
  --ttl-ms=<int>             Snapshot cache TTL in ms (default: 500)
  --dry-run                  Print planned writes without modifying files
  --skip-post-steps          Skip melos frb:generate, analyze, and test
  --fixture-root=<path>      Override repo root (for generator tests)
  -h, --help                 Show this help
''');
}
