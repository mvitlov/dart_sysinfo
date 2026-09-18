/// Network throughput stream sample model (TDD §4.5).
library;

import 'package:meta/meta.dart';

/// One network throughput stream tick returned by [NetworkDomain.throughput].
@immutable
class NetworkThroughputSample {
  /// Creates one network throughput stream sample.
  const NetworkThroughputSample({
    required this.interfaces,
  });

  /// Per-interface throughput deltas since the last native refresh.
  final List<NetworkThroughputInterface> interfaces;
}

/// Per-interface throughput deltas for one stream tick.
@immutable
class NetworkThroughputInterface {
  /// Creates per-interface throughput counters.
  const NetworkThroughputInterface({
    required this.name,
    required this.receivedBytes,
    required this.transmittedBytes,
    required this.packetsReceived,
    required this.packetsTransmitted,
    required this.errorsOnReceived,
    required this.errorsOnTransmitted,
  });

  /// Interface name.
  final String name;

  /// Bytes received since the last native refresh.
  final int receivedBytes;

  /// Bytes transmitted since the last native refresh.
  final int transmittedBytes;

  /// Packets received since the last native refresh.
  final int packetsReceived;

  /// Packets transmitted since the last native refresh.
  final int packetsTransmitted;

  /// Receive errors since the last native refresh.
  final int errorsOnReceived;

  /// Transmit errors since the last native refresh.
  final int errorsOnTransmitted;
}
