/// Orchestrates domain scaffold generation.
library;

import 'dart:io';

import 'naming.dart';
import 'patcher.dart';
import 'template_context.dart';
import 'writer.dart';

class DomainGenerator {
  DomainGenerator({
    required this.repoRoot,
    required this.templatesDir,
    required this.dryRun,
    required this.skipPostSteps,
  });

  final Directory repoRoot;
  final Directory templatesDir;
  final bool dryRun;
  final bool skipPostSteps;

  Future<void> run(DomainNaming naming) async {
    final writer = DomainWriter(repoRoot: repoRoot, dryRun: dryRun);
    writer.assertDomainAbsent(naming.name);

    final context = TemplateContext(naming);
    _writeDomainFiles(writer, naming, context);
    _writeRustApi(writer, naming, context);
    _applyPatches(writer, naming);

    if (skipPostSteps) {
      stdout.writeln('Skipped post-steps (--skip-post-steps).');
      _printManualChecklist(naming);
      return;
    }

    await _runPostSteps(naming);
  }

  void _writeDomainFiles(
    DomainWriter writer,
    DomainNaming naming,
    TemplateContext context,
  ) {
    final name = naming.name;
    final domainDir = 'lib/src/domains/$name';

    writer.writeNewFile(
      '$domainDir/${name}_domain.dart',
      context.render(_loadTemplate(
        naming.hasStream ? 'dart_domain_stream.dart.tmpl' : 'dart_domain.dart.tmpl',
      )),
    );
    writer.writeNewFile(
      '$domainDir/${name}_info.dart',
      context.render(_loadTemplate('dart_info.dart.tmpl')),
    );
    if (naming.hasStream) {
      writer.writeNewFile(
        '$domainDir/${name}_stream_sample.dart',
        context.render(_loadTemplate('dart_stream_sample.dart.tmpl')),
      );
    }
    writer.writeNewFile(
      '$domainDir/${name}_domain_impl.dart',
      context.render(_loadTemplate(
        naming.hasStream
            ? 'dart_domain_impl_stream.dart.tmpl'
            : 'dart_domain_impl.dart.tmpl',
      )),
    );
    writer.writeNewFile(
      '$domainDir/${name}_mapper.dart',
      context.render(_loadTemplate(
        naming.hasStream ? 'dart_mapper_stream.dart.tmpl' : 'dart_mapper.dart.tmpl',
      )),
    );
    writer.writeNewFile(
      'lib/src/testing/fake_${name}_domain.dart',
      context.render(_loadTemplate(
        naming.hasStream ? 'fake_domain_stream.dart.tmpl' : 'fake_domain.dart.tmpl',
      )),
    );
    writer.writeNewFile(
      'test/domains/${name}_domain_test.dart',
      context.render(_loadTemplate(
        naming.hasStream ? 'domain_test_stream.dart.tmpl' : 'domain_test.dart.tmpl',
      )),
    );
  }

  void _writeRustApi(
    DomainWriter writer,
    DomainNaming naming,
    TemplateContext context,
  ) {
    writer.writeNewFile(
      'packages/native/src/api/${naming.name}.rs',
      context.render(_loadTemplate(
        naming.hasStream ? 'rust_api_stream.rs.tmpl' : 'rust_api.rs.tmpl',
      )),
    );
  }

  void _applyPatches(DomainWriter writer, DomainNaming naming) {
    final patcher = DomainPatcher(naming);
    for (final entry in patcher.buildPatches().entries) {
      final file = writer.repoFile(entry.key);
      if (!file.existsSync()) {
        throw StateError('Patch target missing: ${file.path}');
      }
      final updated = entry.value(file.readAsStringSync());
      writer.writePatch(entry.key, updated);
    }
  }

  Future<void> _runPostSteps(DomainNaming naming) async {
    stdout.writeln('Running FRB codegen...');
    final frb = await Process.run(
      'fvm',
      ['dart', 'run', 'melos', 'frb:generate'],
      workingDirectory: repoRoot.path,
      runInShell: true,
    );
    stdout.write(frb.stdout);
    stderr.write(frb.stderr);
    if (frb.exitCode != 0) {
      throw StateError('melos frb:generate failed (exit ${frb.exitCode})');
    }

    _verifyBridgeApi(naming);

    stdout.writeln('Running dart analyze...');
    final analyze = await Process.run(
      'fvm',
      ['dart', 'analyze', '--fatal-warnings', 'packages/dart_sysinfo'],
      workingDirectory: repoRoot.path,
      runInShell: true,
    );
    stdout.write(analyze.stdout);
    stderr.write(analyze.stderr);
    if (analyze.exitCode != 0) {
      throw StateError('dart analyze failed (exit ${analyze.exitCode})');
    }

    stdout.writeln('Running domain test...');
    final test = await Process.run(
      'fvm',
      [
        'dart',
        'test',
        'packages/dart_sysinfo/test/domains/${naming.name}_domain_test.dart',
      ],
      workingDirectory: repoRoot.path,
      runInShell: true,
    );
    stdout.write(test.stdout);
    stderr.write(test.stderr);
    if (test.exitCode != 0) {
      throw StateError('dart test failed (exit ${test.exitCode})');
    }

    _printManualChecklist(naming);
  }

  void _verifyBridgeApi(DomainNaming naming) {
    final bridgeFile = File(
      '${repoRoot.path}/packages/dart_sysinfo/lib/src/bridge/api/${naming.name}.dart',
    );
    if (!bridgeFile.existsSync()) {
      throw StateError('Expected generated bridge API at ${bridgeFile.path}');
    }
    final content = bridgeFile.readAsStringSync();
    if (!content.contains('${naming.snapshotFnDart}()')) {
      throw StateError(
        'FRB bridge missing ${naming.snapshotFnDart}(); check api/${naming.name}.rs',
      );
    }
    if (naming.hasStream && !content.contains('${naming.streamFnDart}(')) {
      throw StateError(
        'FRB bridge missing ${naming.streamFnDart}(); check stream wiring',
      );
    }
  }

  void _printManualChecklist(DomainNaming naming) {
    stdout.writeln('');
    stdout.writeln('Next steps for ${naming.name}:');
    stdout.writeln('  1. Author TDD field table and replace placeholder model/DTO fields.');
    stdout.writeln('  2. Implement Rust api/${naming.name}.rs (remove unimplemented!).');
    if (_cargoFeatureHint(naming.name) case final hint?) {
      stdout.writeln('  3. Enable Cargo feature: $hint');
    }
    stdout.writeln('  4. Run: fvm dart run melos frb:generate');
    stdout.writeln('  5. Fill capability-matrix TBD rows when domain ships.');
  }

  String? _cargoFeatureHint(String name) {
    return switch (name) {
      'disks' => 'disk = ["sysinfo/disk"] in packages/native/Cargo.toml',
      'network' => 'network = ["sysinfo/network"] in packages/native/Cargo.toml',
      'component' || 'components' =>
        'component = ["sysinfo/component"] in packages/native/Cargo.toml',
      _ => null,
    };
  }

  String _loadTemplate(String fileName) {
    final file = File('${templatesDir.path}/$fileName');
    if (!file.existsSync()) {
      throw StateError('Missing template: ${file.path}');
    }
    return file.readAsStringSync();
  }
}
