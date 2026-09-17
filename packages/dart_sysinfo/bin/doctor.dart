import 'package:dart_sysinfo/src/doctor/checks/android_ndk_check.dart';
import 'package:dart_sysinfo/src/doctor/checks/backend_consistency_check.dart';
import 'package:dart_sysinfo/src/doctor/checks/cocoa_pods_check.dart';
import 'package:dart_sysinfo/src/doctor/checks/rust_toolchain_check.dart';
import 'package:dart_sysinfo/src/doctor/checks/xcode_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_runner.dart';

/// Setup diagnostics CLI (TDD §6, PRD §9.1).
///
/// Run via (workspace root): `dart run dart_sysinfo:doctor`
/// Run via (this package): `dart run :doctor`
Future<int> main(List<String> args) async {
  return DoctorRunner(
    checks: [
      const RustToolchainCheck(),
      const AndroidNdkCheck(),
      const XcodeCheck(),
      const CocoaPodsCheck(),
      const BackendConsistencyCheck(),
    ],
  ).run();
}
