/// Memory domain implementation (TDD §3.4, §4.2).
library;

import 'package:dart_sysinfo/src/bridge/api/memory.dart';
import 'package:dart_sysinfo/src/core/ttl_cache.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_info.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_mapper.dart';

/// Real memory domain backed by the native bridge.
class MemoryDomainImpl implements MemoryDomain {
  /// Creates a memory domain with optional test double for cache.
  MemoryDomainImpl({TtlCache<MemoryInfo>? snapshotCache})
      : _cache = snapshotCache ?? TtlCache(const Duration(milliseconds: 500));

  final TtlCache<MemoryInfo> _cache;

  @override
  Future<MemoryInfo> snapshot({bool forceRefresh = false}) {
    return _cache.read(
      () async => mapMemoryInfoDto(memorySnapshot()),
      forceRefresh: forceRefresh,
    );
  }
}
