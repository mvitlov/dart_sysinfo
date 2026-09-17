import 'dart:io';

/// Host OS facts used to gate platform-specific checks.
class HostEnvironment {
  const HostEnvironment({required this.operatingSystem});

  /// Default host environment from [Platform.operatingSystem].
  factory HostEnvironment.current() {
    return HostEnvironment(operatingSystem: Platform.operatingSystem);
  }

  final String operatingSystem;

  bool get isMacOS => operatingSystem == 'macos';
}
