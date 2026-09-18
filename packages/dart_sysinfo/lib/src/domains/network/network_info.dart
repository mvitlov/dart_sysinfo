/// Network snapshot model (TDD §4.5).
library;

import 'package:meta/meta.dart';

/// Network snapshot returned by [NetworkDomain.snapshot].
@immutable
class NetworkInfo {
  /// Creates a network snapshot with the given interfaces.
  const NetworkInfo({
    required this.interfaces,
  });

  /// Network interfaces visible to the current process.
  ///
  /// An empty list is valid on sandboxes or restricted hosts — not an error
  /// condition.
  final List<NetworkInterface> interfaces;

  /// Safe default for unconfigured fakes (TDD §5.1).
  factory NetworkInfo.allUnavailable() => const NetworkInfo(interfaces: []);
}

/// Operational state of a network interface.
enum NetworkOperationalState {
  /// Interface is up.
  up,

  /// Interface is down.
  down,

  /// Interface is in testing mode.
  testing,

  /// Unknown operational state.
  unknown,

  /// Interface is dormant.
  dormant,

  /// Interface is not present.
  notPresent,

  /// Lower layer is down.
  lowerLayerDown,
}

/// Static metadata for one network interface.
@immutable
class NetworkInterface {
  /// Creates a network interface snapshot entry.
  const NetworkInterface({
    required this.name,
    required this.macAddress,
    required this.ipNetworks,
    required this.mtu,
    required this.operationalState,
    required this.cumulative,
  });

  /// Interface name (for example `en0`, `eth0`).
  final String name;

  /// MAC address string. `00:00:00:00:00:00` indicates unspecified.
  final String macAddress;

  /// Assigned IP networks on this interface.
  final List<IpNetworkEntry> ipNetworks;

  /// Maximum transmission unit in bytes.
  final int mtu;

  /// Current operational state when reported by the OS.
  final NetworkOperationalState operationalState;

  /// Lifetime cumulative counters for this interface.
  final NetworkCumulativeStats cumulative;
}

/// IP network entry on an interface.
@immutable
class IpNetworkEntry {
  /// Creates an IP network entry.
  const IpNetworkEntry({
    required this.address,
    required this.prefixLength,
  });

  /// IP address string.
  final String address;

  /// CIDR prefix length.
  final int prefixLength;
}

/// Lifetime cumulative network counters.
@immutable
class NetworkCumulativeStats {
  /// Creates cumulative network counters.
  const NetworkCumulativeStats({
    required this.totalReceivedBytes,
    required this.totalTransmittedBytes,
    required this.totalPacketsReceived,
    required this.totalPacketsTransmitted,
    required this.totalErrorsOnReceived,
    required this.totalErrorsOnTransmitted,
  });

  /// Total bytes received since boot or counter reset.
  final int totalReceivedBytes;

  /// Total bytes transmitted since boot or counter reset.
  final int totalTransmittedBytes;

  /// Total packets received since boot or counter reset.
  final int totalPacketsReceived;

  /// Total packets transmitted since boot or counter reset.
  final int totalPacketsTransmitted;

  /// Total receive errors since boot or counter reset.
  final int totalErrorsOnReceived;

  /// Total transmit errors since boot or counter reset.
  final int totalErrorsOnTransmitted;
}
