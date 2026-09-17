/// Memory domain implementation (stub until M1-08).
library;

import 'package:dart_sysinfo/src/domains/memory/memory_domain.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_info.dart';

/// Stub MemoryDomain so SysInfo can compile before M1-08.
class MemoryDomainImpl implements MemoryDomain {
  /// Creates a stub memory domain.
  const MemoryDomainImpl();

  @override
  Future<MemoryInfo> snapshot({bool forceRefresh = false}) {
    throw UnimplementedError('MemoryDomain.snapshot is implemented in M1-08');
  }
}
