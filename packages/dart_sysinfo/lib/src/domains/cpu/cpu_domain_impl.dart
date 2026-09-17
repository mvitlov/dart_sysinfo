/// CPU domain implementation (TDD §3.3, §3.4, §4.1).
library;

import 'dart:io';

import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
import 'package:dart_sysinfo/src/core/ttl_cache.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_info.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_mapper.dart';

/// Real CPU domain backed by the native bridge.
class CpuDomainImpl implements CpuDomain {
  /// Creates a CPU domain with optional test doubles for cache/registry.
  CpuDomainImpl({
    TtlCache<CpuInfo>? snapshotCache,
    SharedStreamRegistry? streamRegistry,
  })  : _cache = snapshotCache ?? TtlCache(const Duration(milliseconds: 500)),
        _streams = streamRegistry ?? SharedStreamRegistry.instance;

  static const _loadDomainKey = 'cpu.load';

  final TtlCache<CpuInfo> _cache;
  final SharedStreamRegistry _streams;

  @override
  Future<CpuInfo> snapshot({bool forceRefresh = false}) {
    return _cache.read(
      () async => mapCpuInfoDto(cpuSnapshot()),
      forceRefresh: forceRefresh,
    );
  }

  @override
  Stream<CpuLoadSample> load({
    Duration interval = const Duration(seconds: 1),
  }) {
    return _streams.get<CpuLoadSample>(
      domainKey: _loadDomainKey,
      requested: interval,
      minInterval: _cpuLoadMinInterval(),
      createRawStream: (clamped) => cpuLoadStream(
        intervalMs: BigInt.from(clamped.inMilliseconds),
      ).map(mapCpuLoadSampleDto),
    );
  }
}

Duration _cpuLoadMinInterval() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const Duration(milliseconds: 200);
  }
  return const Duration(milliseconds: 50);
}
