/// Network domain interface (TDD §4.5).
library;

import 'package:dart_sysinfo/src/domains/network/network_info.dart';
import 'package:dart_sysinfo/src/domains/network/network_throughput_sample.dart';

/// Network metrics: TTL-cached snapshot and throughput stream.
abstract class NetworkDomain {
  /// Returns a TTL-cached network snapshot.
  Future<NetworkInfo> snapshot({bool forceRefresh = false});

  /// Broadcast network throughput samples at the requested interval.
  Stream<NetworkThroughputSample> throughput({
    Duration interval = const Duration(seconds: 1),
  });
}
