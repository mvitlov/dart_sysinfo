import 'dart:io';

import 'package:dart_sysinfo/src/doctor/checks/rust_toolchain_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:dart_sysinfo/src/doctor/rust_toolchain_config.dart';
import 'package:test/test.dart';

import 'fake_process_runner.dart';

void main() {
  group('RustToolchainCheck', () {
    late Directory workspaceDir;
    late Directory packageRoot;
    late Directory nativeRoot;

    setUp(() async {
      workspaceDir = await Directory.systemTemp.createTemp('doctor_rust_');
      packageRoot = Directory('${workspaceDir.path}/dart_sysinfo')
        ..createSync();
      nativeRoot = Directory('${workspaceDir.path}/native')..createSync();
    });

    tearDown(() async {
      if (workspaceDir.existsSync()) {
        await workspaceDir.delete(recursive: true);
      }
    });

    Future<DoctorContext> contextWith(FakeProcessRunner runner) async {
      await File('${nativeRoot.path}/rust-toolchain.toml').writeAsString('''
[toolchain]
channel = "1.98.1"
targets = [
  "aarch64-linux-android",
  "x86_64-unknown-linux-gnu",
]
''');
      return DoctorContext(
        packageRoot: packageRoot.path,
        processRunner: runner,
        host: const HostEnvironment(operatingSystem: 'linux'),
        environment: {},
      );
    }

    test('passes when version and targets match', () async {
      final runner = FakeProcessRunner({
        'rustc': (_) => okResult('rustc 1.98.1 (abc123)'),
        'rustup': (_) => okResult('aarch64-linux-android\nx86_64-unknown-linux-gnu\n'),
      });
      final context = await contextWith(runner);

      final result = await const RustToolchainCheck().run(context);
      expect(result.ok, isTrue);
      expect(result.summary, contains('1.98.1'));
    });

    test('fails on version mismatch', () async {
      final runner = FakeProcessRunner({
        'rustc': (_) => okResult('rustc 1.97.0 (abc123)'),
      });
      final context = await contextWith(runner);

      final result = await const RustToolchainCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, contains('rustup toolchain install 1.98.1'));
    });

    test('fails when targets are missing', () async {
      final runner = FakeProcessRunner({
        'rustc': (_) => okResult('rustc 1.98.1 (abc123)'),
        'rustup': (_) => okResult('x86_64-unknown-linux-gnu\n'),
      });
      final context = await contextWith(runner);

      final result = await const RustToolchainCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, contains('rustup target add aarch64-linux-android'));
    });

    test('fails gracefully when rust-toolchain.toml is missing', () async {
      final runner = FakeProcessRunner({});
      final context = DoctorContext(
        packageRoot: packageRoot.path,
        processRunner: runner,
        host: const HostEnvironment(operatingSystem: 'linux'),
        environment: {},
      );

      final result = await const RustToolchainCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, contains('rust-toolchain.toml'));
    });

    test('fails when rustc is not on PATH', () async {
      final runner = FakeProcessRunner({});
      final context = await contextWith(runner);

      final result = await const RustToolchainCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, contains('sh.rustup.rs'));
    });
  });

  group('RustToolchainConfig', () {
    test('parses channel and targets', () {
      const content = '''
[toolchain]
channel = "1.98.1"
targets = [
  "aarch64-linux-android",
  "x86_64-unknown-linux-gnu",
]
''';
      final config = RustToolchainConfig.parse(content);
      expect(config?.channel, '1.98.1');
      expect(config?.targets, [
        'aarch64-linux-android',
        'x86_64-unknown-linux-gnu',
      ]);
    });
  });
}
