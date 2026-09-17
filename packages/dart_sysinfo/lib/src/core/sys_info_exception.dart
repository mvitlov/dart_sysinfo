/// Lifecycle and native-loading failures for the public API (PRD §5.3).
library;

import 'package:meta/meta.dart';

/// Top-level lifecycle or native-loading failure, distinct from
/// Reading&lt;T&gt;.
///
/// This is the complete list of throwable errors from the public API for this
/// major version. Every other failure mode is expressed as Reading&lt;T&gt;.
sealed class SysInfoException implements Exception {
  const SysInfoException(this.message);

  final String message;

  @override
  // ignore: no_runtimetype_tostring — PRD §5.3 required format
  String toString() => '$runtimeType: $message';
}

/// The native library could not be located or loaded for this platform/ABI.
@immutable
final class SysInfoLoadException extends SysInfoException {
  const SysInfoLoadException(super.message);
}

/// The loaded native library's ABI does not match the version the Dart bridge
/// was generated against. See PRD §7.3.
@immutable
final class SysInfoAbiMismatchException extends SysInfoException {
  const SysInfoAbiMismatchException(
    super.message, {
    required this.expectedAbi,
    required this.actualAbi,
  });

  final int expectedAbi;
  final int actualAbi;
}

/// A SysInfo API was called after SysInfo.dispose().
@immutable
final class SysInfoDisposedException extends SysInfoException {
  const SysInfoDisposedException(super.message);
}

/// SysInfo.instance was accessed on a platform excluded by PRD §1.6 (should
/// normally be caught earlier, at build/dependency-resolution time, but this
/// is the runtime backstop).
@immutable
final class SysInfoUnsupportedPlatformException extends SysInfoException {
  const SysInfoUnsupportedPlatformException(super.message);
}
