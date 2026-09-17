import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';

/// A single setup diagnostic check for the `doctor` CLI (TDD §6).
abstract interface class DoctorCheck {
  String get name;

  Future<DoctorResult> run(DoctorContext context);
}
