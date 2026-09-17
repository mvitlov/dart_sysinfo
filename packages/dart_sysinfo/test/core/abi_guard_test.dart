import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';
import 'package:test/test.dart';

void main() {
  group('AbiGuard.check', () {
    test('check_succeeds_when_abi_matches', () {
      expect(
        () => AbiGuard.check(actual: AbiGuard.expectedAbi),
        returnsNormally,
      );
    });

    test('check_throws_on_deliberate_mismatch', () {
      expect(
        () => AbiGuard.check(actual: 99),
        throwsA(isA<SysInfoAbiMismatchException>()),
      );
    });

    test('mismatch_message_is_actionable', () {
      expect(
        () => AbiGuard.check(actual: 99),
        throwsA(
          isA<SysInfoAbiMismatchException>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('dart run dart_sysinfo:doctor'),
              contains('99'),
              contains('${AbiGuard.expectedAbi}'),
            ),
          ),
        ),
      );
    });

    test('mismatch_preserves_expected_and_actual_fields', () {
      SysInfoAbiMismatchException? caught;
      try {
        AbiGuard.check(actual: 99);
      } on SysInfoAbiMismatchException catch (exception) {
        caught = exception;
      }

      expect(caught, isNotNull);
      expect(caught!.expectedAbi, AbiGuard.expectedAbi);
      expect(caught.actualAbi, 99);
    });
  });
}
