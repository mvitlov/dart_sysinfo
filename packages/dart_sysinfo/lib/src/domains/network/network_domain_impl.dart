/// Network domain implementation (TDD §4.5).
library;

import 'dart:io';

import 'package:dart_sysinfo/src/bridge/api/network.dart';
import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
import 'package:dart_sysinfo/src/core/ttl_cache.dart';
import 'package:dart_sysinfo/src/domains/network/network_domain.dart';
import 'package:dart_sysinfo/src/domains/network/network_info.dart';
import 'package:dart_sysinfo/src/domains/network/network_mapper.dart';
import 'package:dart_sysinfo/src/domains/network/network_throughput_sample.dart';

/// Real network domain backed by the native bridge.
class NetworkDomainImpl implements NetworkDomain {
  /// Creates a network domain with optional test doubles for cache/registry.
  NetworkDomainImpl({
    TtlCache<NetworkInfo>? snapshotCache,
    SharedStreamRegistry? streamRegistry,
  })  : _cache = snapshotCache ?? TtlCache(const Duration(milliseconds: 2000)),
        _streams = streamRegistry ?? SharedStreamRegistry.instance;

  static const _streamDomainKey = 'network.throughput';

  final TtlCache<NetworkInfo> _cache;
  final SharedStreamRegistry _streams;

  @override
  Future<NetworkInfo> snapshot({bool forceRefresh = false}) {
    return _cache.read(
      () async => mapNetworkInfoDto(networkSnapshot()),
      forceRefresh: forceRefresh,
    );
  }

  @override
  Stream<NetworkThroughputSample> throughput({
    Duration interval = const Duration(seconds: 1),
  }) {
    return _streams.get<NetworkThroughputSample>(
      domainKey: _streamDomainKey,
      requested: interval,
      minInterval: _streamMinInterval(),
      createRawStream: (clamped) => networkThroughputStream(
        intervalMs: BigInt.from(clamped.inMilliseconds),
      ).map(mapNetworkThroughputSampleDto),
    );
  }
}

Duration _streamMinInterval() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const Duration(milliseconds: 200);
  }
  return const Duration(milliseconds: 50);
}
