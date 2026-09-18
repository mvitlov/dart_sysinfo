import 'dart:io';

import 'package:dart_sysinfo/src/doctor/checks/backend_consistency_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:dart_sysinfo/src/doctor/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('BackendConsistencyCheck', () {
    late Directory tempRoot;
    late DoctorContext context;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('doctor_backend_');
      context = DoctorContext(
        packageRoot: tempRoot.path,
        processRunner: const _NoopProcessRunner(),
        host: const HostEnvironment(operatingSystem: 'linux'),
        environment: {},
      );
    });

    tearDown(() async {
      if (tempRoot.existsSync()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('passes with valid dual-backend layout', () async {
      await _writeValidLayout(tempRoot);

      final result = await const BackendConsistencyCheck().run(context);
      expect(result.ok, isTrue);
      expect(result.summary, contains('Dual-backend'));
    });

    test('fails when cargokit directory is missing', () async {
      await _writeValidLayout(tempRoot);
      await Directory('${tempRoot.path}/cargokit').delete(recursive: true);

      final result = await const BackendConsistencyCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, contains('cargokit'));
    });

    test('fails when hook is a no-op placeholder', () async {
      await _writeValidLayout(tempRoot);
      await File('${tempRoot.path}/hook/build.dart').writeAsString('''
import 'package:hooks/hooks.dart';
void main(List<String> args) async {
  await build(args, (input, output) async {});
}
''');

      final result = await const BackendConsistencyCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.summary, contains('Native Assets hook missing'));
    });

    test('fails when android gradle does not reference cargokit', () async {
      await _writeValidLayout(tempRoot);
      await File('${tempRoot.path}/android/build.gradle')
          .writeAsString('apply plugin: "com.android.library"');

      final result = await const BackendConsistencyCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.summary, contains('Cargokit'));
    });
  });
}

Future<void> _writeValidLayout(Directory root) async {
  await Directory('${root.path}/cargokit').create(recursive: true);
  for (final platform in ['android', 'ios', 'linux', 'macos', 'windows']) {
    await Directory('${root.path}/$platform').create(recursive: true);
  }
  await Directory('${root.path}/hook').create(recursive: true);
  await File('${root.path}/hook/build.dart').writeAsString('''
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
import 'package:hooks/hooks.dart';
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    await const FlutterRustBridgeNativeAssetsBuilder(
      cratePath: '../native',
      assetName: 'src/bridge/frb_generated.io.dart',
    ).run(input: input, output: output);
  });
}
''');
  await File('${root.path}/pubspec.yaml').writeAsString('''
name: dart_sysinfo
dependencies:
  flutter_rust_bridge_hooks: 2.13.0
flutter:
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ios:
        ffiPlugin: true
      linux:
        ffiPlugin: true
      macos:
        ffiPlugin: true
      windows:
        ffiPlugin: true
''');
  await File('${root.path}/android/build.gradle').writeAsString('''
apply from: "../cargokit/gradle/plugin.gradle"
cargokit {
  manifestDir = "../../native"
}
''');
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
