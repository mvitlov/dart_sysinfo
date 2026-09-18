import 'dart:io';

import 'package:test/test.dart';

import '../new_domain/naming.dart';
import '../new_domain/template_context.dart';

void main() {
  final fixtureSource = Directory('tool/test/fixtures/minimal_repo');

  group('DomainNaming', () {
    test('rejects invalid and existing names', () {
      expect(
        () => DomainNaming.parse(
          rawName: '',
          ttlMs: 500,
          hasStream: false,
          streamMethod: 'load',
        ),
        throwsFormatException,
      );
      expect(
        () => DomainNaming.parse(
          rawName: 'cpu',
          ttlMs: 500,
          hasStream: false,
          streamMethod: 'load',
        ),
        throwsFormatException,
      );
      expect(
        () => DomainNaming.parse(
          rawName: 'bad-name',
          ttlMs: 500,
          hasStream: false,
          streamMethod: 'load',
        ),
        throwsFormatException,
      );
    });

    test('derives PascalCase and FRB mock method names', () {
      final naming = DomainNaming.parse(
        rawName: 'foo_bar',
        ttlMs: 500,
        hasStream: true,
        streamMethod: 'throughput',
      );

      expect(naming.pascal, 'FooBar');
      expect(naming.snapshotFnDart, 'fooBarSnapshot');
      expect(naming.crateApiSnapshot, 'crateApiFooBarFooBarSnapshot');
      expect(naming.crateApiStream, 'crateApiFooBarFooBarThroughputStream');
    });

    test('renders template tokens', () {
      final context = TemplateContext(
        DomainNaming.parse(
          rawName: 'widgets',
          ttlMs: 500,
          hasStream: false,
          streamMethod: 'load',
        ),
      );
      expect(
        context.render('class {{Pascal}}Domain {}'),
        'class WidgetsDomain {}',
      );
    });
  });

  group('DomainGenerator integration', () {
    test('snapshot scaffold writes expected tree and patches', () async {
      final temp = await _copyFixtureToTemp(fixtureSource);
      addTearDown(() => temp.deleteSync(recursive: true));

      await _runGenerator(
        ['sensors', '--skip-post-steps'],
        fixtureRoot: temp.path,
      );

      expect(
        File('${temp.path}/packages/dart_sysinfo/lib/src/domains/sensors/sensors_domain.dart')
            .existsSync(),
        isTrue,
      );
      expect(
        File('${temp.path}/packages/native/src/api/sensors.rs').existsSync(),
        isTrue,
      );

      final sysInfo = File(
        '${temp.path}/packages/dart_sysinfo/lib/src/core/sys_info.dart',
      ).readAsStringSync();
      expect(sysInfo, contains('SensorsDomain get sensors;'));
      expect(sysInfo, contains('sensors = SensorsDomainImpl()'));
      expect(
        sysInfo.contains(RegExp(r'// GENERATOR:END domain-impl-init\s*;')),
        isFalse,
        reason: 'semicolon must stay on the last initializer, not after END',
      );

      final mock = File(
        '${temp.path}/packages/dart_sysinfo/test/support/mock_rust_lib_api.dart',
      ).readAsStringSync();
      expect(
        mock.contains(RegExp(r'// GENERATOR:END mock-stream-ctor-init\s*;')),
        isFalse,
      );

      final matrix = File('${temp.path}/docs/capability-matrix.md').readAsStringSync();
      expect(matrix, contains('`sensors`'));
      expect(matrix, contains('TBD — scaffold placeholder'));
    });

    test('stream scaffold adds stream sample and mock stream wiring', () async {
      final temp = await _copyFixtureToTemp(fixtureSource);
      addTearDown(() => temp.deleteSync(recursive: true));

      await _runGenerator(
        [
          'metrics',
          '--stream',
          '--stream-method=throughput',
          '--skip-post-steps',
        ],
        fixtureRoot: temp.path,
      );

      expect(
        File(
          '${temp.path}/packages/dart_sysinfo/lib/src/domains/metrics/metrics_stream_sample.dart',
        ).existsSync(),
        isTrue,
      );

      final domain = File(
        '${temp.path}/packages/dart_sysinfo/lib/src/domains/metrics/metrics_domain.dart',
      ).readAsStringSync();
      expect(domain, contains('Stream<MetricsStreamSample> throughput'));

      final mock = File(
        '${temp.path}/packages/dart_sysinfo/test/support/mock_rust_lib_api.dart',
      ).readAsStringSync();
      expect(mock, contains('crateApiMetricsMetricsThroughputStream'));
    });

    test('refuses to overwrite an existing domain', () async {
      final temp = await _copyFixtureToTemp(fixtureSource);
      addTearDown(() => temp.deleteSync(recursive: true));

      await _runGenerator(
        ['sensors', '--skip-post-steps'],
        fixtureRoot: temp.path,
      );

      final second = await Process.run(
        _dartRunner,
        _dartArgs([
          'run',
          '${Directory.current.path}/tool/new_domain.dart',
          'sensors',
          '--skip-post-steps',
          '--fixture-root=${temp.path}',
        ]),
        runInShell: true,
      );
      expect(second.exitCode, 1);
    });
  });
}

String? _dartRunnerCache;

String get _dartRunner {
  if (_dartRunnerCache != null) {
    return _dartRunnerCache!;
  }
  final locator = Platform.isWindows ? 'where' : 'which';
  if (Process.runSync(locator, ['fvm']).exitCode == 0) {
    return _dartRunnerCache = 'fvm';
  }
  return _dartRunnerCache = Platform.resolvedExecutable;
}

List<String> _dartArgs(List<String> args) {
  if (_dartRunner == 'fvm') {
    return ['dart', ...args];
  }
  return args;
}

Future<void> _runGenerator(
  List<String> args, {
  required String fixtureRoot,
}) async {
  final result = await Process.run(
    _dartRunner,
    _dartArgs([
      'run',
      '${Directory.current.path}/tool/new_domain.dart',
      ...args,
      '--fixture-root=$fixtureRoot',
    ]),
    runInShell: true,
  );
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw ProcessException(
      _dartRunner,
      args,
      'Generator failed:\n${result.stderr}',
      result.exitCode,
    );
  }
}

Future<Directory> _copyFixtureToTemp(Directory source) async {
  final temp = await Directory.systemTemp.createTemp('new_domain_fixture_');
  await _copyDirectory(source, temp);
  return temp;
}

Future<void> _copyDirectory(Directory source, Directory destination) async {
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    if (entity is Directory) {
      continue;
    }
    if (entity is! File) {
      continue;
    }
    final relative = entity.path.substring(source.path.length + 1);
    final target = File('${destination.path}/$relative');
    await target.parent.create(recursive: true);
    await entity.copy(target.path);
  }
}
