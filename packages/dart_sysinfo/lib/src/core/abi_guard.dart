/// ABI handshake between Dart bridge and native library (TDD §3.5).
library;

import 'package:dart_sysinfo/src/core/sys_info_exception.dart';

/// Compares the native ABI reported by [init] against the Dart-side constant.
class AbiGuard {
  /// Hand-kept in lockstep with `native/src/abi.rs` — CI ABI gate (PRD §10.3)
  /// enforces this.
  static const expectedAbi = 2;

  /// Throws [SysInfoAbiMismatchException] when [actual] does not match
  /// [expectedAbi].
  static void check({required int actual}) {
    if (actual != expectedAbi) {
      throw SysInfoAbiMismatchException(
        'Native library ABI ($actual) does not match the ABI this Dart '
        'package version expects ($expectedAbi). Run `dart run '
        'dart_sysinfo:doctor` or reinstall/rebuild the native library.',
        expectedAbi: expectedAbi,
        actualAbi: actual,
      );
    }
  }
}
