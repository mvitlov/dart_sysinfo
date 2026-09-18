/// Cross-platform system information for Dart (Flutter-free core).
///
/// P1 domains: OS, CPU, memory. Flutter apps should also depend on
/// `dart_sysinfo_flutter` for hot-restart lifecycle glue.
library;

export 'src/bridge/api/smoke.dart';
export 'src/bridge/frb_generated.dart';
export 'src/bridge/init.dart';
export 'src/core/reading.dart';
export 'src/core/sys_info.dart';
export 'src/core/sys_info_exception.dart';
export 'src/domains/cpu/cpu_domain.dart';
export 'src/domains/cpu/cpu_info.dart';
export 'src/domains/memory/memory_domain.dart';
export 'src/domains/memory/memory_info.dart';
export 'src/domains/os/os_domain.dart';
export 'src/domains/os/os_info.dart';
