import 'package:dart_sysinfo/src/doctor/doctor_result.dart';
import 'package:test/test.dart';

void main() {
  group('DoctorResult.format', () {
    test('formats OK line', () {
      const result = DoctorResult(ok: true, summary: 'All good');
      expect(result.format(), '[OK]    All good');
    });

    test('formats FAIL line with fix command', () {
      const result = DoctorResult(
        ok: false,
        summary: 'Something wrong',
        fixCommand: 'rustup target add foo',
      );
      expect(
        result.format(),
        '[FAIL]  Something wrong -> fix: rustup target add foo',
      );
    });

    test('formats SKIP line', () {
      const result = DoctorResult(
        ok: true,
        skipped: true,
        summary: 'Xcode: not applicable on linux',
      );
      expect(result.format(), '[SKIP]  Xcode: not applicable on linux');
    });
  });
}
