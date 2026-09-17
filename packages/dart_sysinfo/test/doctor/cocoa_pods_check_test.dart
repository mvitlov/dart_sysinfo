import 'package:dart_sysinfo/src/doctor/checks/cocoa_pods_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:test/test.dart';

import 'fake_process_runner.dart';

void main() {
  group('CocoaPodsCheck', () {
    test('skips on non-macOS hosts', () async {
      final context = DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: FakeProcessRunner({}),
        host: const HostEnvironment(operatingSystem: 'linux'),
        environment: {},
      );

      final result = await const CocoaPodsCheck().run(context);
      expect(result.skipped, isTrue);
      expect(result.ok, isTrue);
    });

    test('passes when pod is available on macOS', () async {
      final context = DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: FakeProcessRunner({
          'pod': (_) => okResult('1.16.2\n'),
        }),
        host: const HostEnvironment(operatingSystem: 'macos'),
        environment: {},
      );

      final result = await const CocoaPodsCheck().run(context);
      expect(result.ok, isTrue);
      expect(result.summary, contains('1.16.2'));
    });

    test('fails when pod is missing on macOS', () async {
      final context = DoctorContext(
        packageRoot: '/tmp/dart_sysinfo',
        processRunner: FakeProcessRunner({}),
        host: const HostEnvironment(operatingSystem: 'macos'),
        environment: {},
      );

      final result = await const CocoaPodsCheck().run(context);
      expect(result.ok, isFalse);
      expect(result.fixCommand, 'sudo gem install cocoapods');
    });
  });
}
