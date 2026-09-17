import 'package:dart_sysinfo/src/doctor/checks/xcode_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:test/test.dart';

import 'fake_process_runner.dart';

void main() {
  group('XcodeCheck', () {
    test('skips on non-macOS hosts', () async {
      final context = DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: FakeProcessRunner({}),
        host: const HostEnvironment(operatingSystem: 'linux'),
        environment: {},
      );

      final result = await const XcodeCheck().run(context);
      expect(result.skipped, isTrue);
      expect(result.ok, isTrue);
    });

    test('passes when xcodebuild succeeds on macOS', () async {
      final context = DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: FakeProcessRunner({
          'xcodebuild': (_) => okResult('Xcode 16.2\nBuild version abc'),
        }),
        host: const HostEnvironment(operatingSystem: 'macos'),
        environment: {},
      );

      final result = await const XcodeCheck().run(context);
      expect(result.ok, isTrue);
      expect(result.summary, contains('Xcode 16.2'));
    });

    test('fails when xcodebuild is unavailable on macOS', () async {
      final context = DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: FakeProcessRunner({}),
        host: const HostEnvironment(operatingSystem: 'macos'),
        environment: {},
      );

      final result = await const XcodeCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, 'xcode-select --install');
    });
  });
}
