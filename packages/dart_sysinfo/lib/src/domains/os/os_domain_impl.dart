/// OS domain implementation (stub until M1-09).
library;

import 'package:dart_sysinfo/src/domains/os/os_domain.dart';
import 'package:dart_sysinfo/src/domains/os/os_info.dart';

/// Stub OsDomain so SysInfo can compile before M1-09.
class OsDomainImpl implements OsDomain {
  /// Creates a stub OS domain.
  const OsDomainImpl();

  @override
  Future<OsInfo> snapshot({bool forceRefresh = false}) {
    throw UnimplementedError('OsDomain.snapshot is implemented in M1-09');
  }
}
