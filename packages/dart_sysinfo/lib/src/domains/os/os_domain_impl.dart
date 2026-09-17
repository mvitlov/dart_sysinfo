/// OS domain implementation (TDD §3.4, §4.3).
library;

import 'package:dart_sysinfo/src/bridge/api/os.dart';
import 'package:dart_sysinfo/src/core/ttl_cache.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain.dart';
import 'package:dart_sysinfo/src/domains/os/os_info.dart';
import 'package:dart_sysinfo/src/domains/os/os_mapper.dart';

/// Real OS domain backed by the native bridge.
class OsDomainImpl implements OsDomain {
  /// Creates an OS domain with optional test double for cache.
  OsDomainImpl({TtlCache<OsInfo>? snapshotCache})
      : _cache = snapshotCache ?? TtlCache(const Duration(milliseconds: 2000));

  final TtlCache<OsInfo> _cache;

  @override
  Future<OsInfo> snapshot({bool forceRefresh = false}) {
    return _cache.read(
      () async => mapOsInfoDto(osSnapshot()),
      forceRefresh: forceRefresh,
    );
  }
}
