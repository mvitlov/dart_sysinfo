import 'dart:io';

import 'package:dart_sysinfo/src/doctor/doctor_check.dart' show DoctorCheck;

import 'package:dart_sysinfo/src/doctor/host_environment.dart';
import 'package:dart_sysinfo/src/doctor/process_runner.dart';

/// Shared runtime context for all [DoctorCheck] implementations.
class DoctorContext {
  DoctorContext({
    required this.packageRoot,
    required this.processRunner,
    required this.host,
    Map<String, String>? environment,
  }) : environment = environment ?? Platform.environment;

  /// Builds context from the `bin/doctor.dart` script location.
  factory DoctorContext.fromScript({
    ProcessRunner? processRunner,
    HostEnvironment? host,
    Map<String, String>? environment,
  }) {
    final scriptPath = Platform.script.toFilePath();
    final packageRoot = Directory(scriptPath).parent.parent.path;
    return DoctorContext(
      packageRoot: packageRoot,
      processRunner: processRunner ?? const IoProcessRunner(),
      host: host ?? HostEnvironment.current(),
      environment: environment,
    );
  }

  final String packageRoot;
  final ProcessRunner processRunner;
  final HostEnvironment host;
  final Map<String, String> environment;

  String get nativeRoot => '$packageRoot${Platform.pathSeparator}..'
      '${Platform.pathSeparator}native';

  String get rustToolchainFile =>
      '$nativeRoot${Platform.pathSeparator}rust-toolchain.toml';

  String? env(String key) => environment[key];
}
