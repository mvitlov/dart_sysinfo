/// Fake network domain for unit tests (TDD §5.1).
library;

import 'dart:async';

import 'package:dart_sysinfo/src/domains/network/network_domain.dart';
import 'package:dart_sysinfo/src/domains/network/network_info.dart';
import 'package:dart_sysinfo/src/domains/network/network_throughput_sample.dart';

/// Configurable [NetworkDomain] with no native calls.
class FakeNetworkDomain implements NetworkDomain {
  /// Creates a fake network domain with optional canned values.
  FakeNetworkDomain({NetworkInfo? snapshot})
      : _snapshot = snapshot ?? NetworkInfo.allUnavailable();

  NetworkInfo _snapshot;
  final _throughputController =
      StreamController<NetworkThroughputSample>.broadcast();

  /// Test-only mutator — not part of [NetworkDomain].
  void setSnapshot(NetworkInfo value) => _snapshot = value;

  /// Test-only injector for stream-based assertions.
  void emitThroughput(NetworkThroughputSample sample) =>
      _throughputController.add(sample);

  @override
  Future<NetworkInfo> snapshot({bool forceRefresh = false}) async => _snapshot;

  @override
  Stream<NetworkThroughputSample> throughput({
    Duration interval = const Duration(seconds: 1),
  }) =>
      _throughputController.stream;
}
