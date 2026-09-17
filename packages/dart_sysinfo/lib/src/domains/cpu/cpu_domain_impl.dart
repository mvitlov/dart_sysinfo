/// CPU domain implementation (stub until M1-07).
library;

import 'package:dart_sysinfo/src/domains/cpu/cpu_domain.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_info.dart';

/// Stub CpuDomain so SysInfo can compile before M1-07.
class CpuDomainImpl implements CpuDomain {
  /// Creates a stub CPU domain.
  const CpuDomainImpl();

  @override
  Future<CpuInfo> snapshot({bool forceRefresh = false}) {
    throw UnimplementedError('CpuDomain.snapshot is implemented in M1-07');
  }

  @override
  Stream<CpuLoadSample> load({Duration interval = const Duration(seconds: 1)}) {
    throw UnimplementedError('CpuDomain.load is implemented in M1-07');
  }
}
