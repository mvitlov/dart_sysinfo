import 'dart:io';

import 'package:dart_sysinfo/src/doctor/checks/android_ndk_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:dart_sysinfo/src/doctor/process_runner.dart';
import 'package:test/test.dart';

void main() {
  group('AndroidNdkCheck', () {
    late Directory ndkRoot;

    setUp(() async {
      ndkRoot = await Directory.systemTemp.createTemp('doctor_ndk_');
      await File('${ndkRoot.path}/source.properties').writeAsString('''
Pkg.Desc = Android NDK
Pkg.Revision = 28.2.13676358
''');
    });

    tearDown(() async {
      if (ndkRoot.existsSync()) {
        await ndkRoot.delete(recursive: true);
      }
    });

    DoctorContext context({Map<String, String>? env}) {
      return DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: const _NoopProcessRunner(),
        host: const HostEnvironment(operatingSystem: 'linux'),
        environment: env ?? {},
      );
    }

    test('passes with valid ANDROID_NDK_ROOT', () async {
      final result = await const AndroidNdkCheck().run(
        context(env: {'ANDROID_NDK_ROOT': ndkRoot.path}),
      );
      expect(result.ok, isTrue);
      expect(result.summary, contains('r28.2.13676358'));
    });

    test('falls back to ANDROID_NDK_HOME', () async {
      final result = await const AndroidNdkCheck().run(
        context(env: {'ANDROID_NDK_HOME': ndkRoot.path}),
      );
      expect(result.ok, isTrue);
    });

    test('fails when env var is unset', () async {
      final result = await const AndroidNdkCheck().run(context());
      expect(result.ok, isFalse);
      expect(result.fixCommand, contains('sdkmanager'));
    });

    test('fails when NDK version is below r28', () async {
      await File('${ndkRoot.path}/source.properties').writeAsString('''
Pkg.Revision = 26.1.10909125
''');
      final result = await const AndroidNdkCheck().run(
        context(env: {'ANDROID_NDK_ROOT': ndkRoot.path}),
      );
      expect(result.ok, isFalse);
      expect(result.summary, contains('below required r28'));
    });
  });
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
