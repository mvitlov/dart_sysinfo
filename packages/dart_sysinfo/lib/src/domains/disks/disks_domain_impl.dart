/// Disks domain implementation (TDD §4.4).
library;

import 'package:dart_sysinfo/src/bridge/api/disks.dart';
import 'package:dart_sysinfo/src/core/ttl_cache.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_domain.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_info.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_mapper.dart';

/// Real disks domain backed by the native bridge.
class DisksDomainImpl implements DisksDomain {
  /// Creates a disks domain with optional test double for cache.
  DisksDomainImpl({TtlCache<DisksInfo>? snapshotCache})
      : _cache = snapshotCache ?? TtlCache(const Duration(milliseconds: 2000));

  final TtlCache<DisksInfo> _cache;

  @override
  Future<DisksInfo> snapshot({bool forceRefresh = false}) {
    return _cache.read(
      () async => mapDisksInfoDto(disksSnapshot()),
      forceRefresh: forceRefresh,
    );
  }
}
