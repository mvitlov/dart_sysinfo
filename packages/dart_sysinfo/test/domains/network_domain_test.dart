import 'dart:async';
import 'dart:io';

import 'package:dart_sysinfo/src/bridge/api/network.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
import 'package:dart_sysinfo/src/domains/network/network_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/network/network_info.dart';
import 'package:dart_sysinfo/src/domains/network/network_throughput_sample.dart';
import 'package:test/test.dart';

import '../support/mock_rust_lib_api.dart';

late MockRustLibApi mockRustLibApi;

NetworkInterfaceDto _sampleInterface({
  required String name,
  String macAddress = '00:11:22:33:44:55',
}) {
  return NetworkInterfaceDto(
    name: name,
    macAddress: macAddress,
    ipNetworks: const [
      IpNetworkEntryDto(address: '192.168.1.10', prefixLength: 24),
    ],
    mtu: BigInt.from(1500),
    operationalState: NetworkOperationalStateDto.up,
    cumulative: NetworkCumulativeStatsDto(
      totalReceivedBytes: BigInt.from(1024),
      totalTransmittedBytes: BigInt.from(2048),
      totalPacketsReceived: BigInt.from(10),
      totalPacketsTransmitted: BigInt.from(20),
      totalErrorsOnReceived: BigInt.zero,
      totalErrorsOnTransmitted: BigInt.zero,
    ),
  );
}

void main() {
  setUpAll(() {
    mockRustLibApi = MockRustLibApi();
    RustLib.initMock(api: mockRustLibApi);
  });

  setUp(() {
    mockRustLibApi
      ..networkSnapshotCalls = 0
      ..networkThroughputStreamCalls = 0
      ..lastThroughputIntervalMs = null
      ..networkSnapshotResult = NetworkInfoDto(
        interfaces: [
          _sampleInterface(name: 'en0'),
          _sampleInterface(name: 'lo0', macAddress: '00:00:00:00:00:00'),
        ],
      );
  });

  tearDown(() async {
    await SharedStreamRegistry.instance.cancelAll();
  });

  group('NetworkDomainImpl.snapshot', () {
    test('snapshot_maps_interfaces', () async {
      final domain = NetworkDomainImpl();
      final info = await domain.snapshot();

      expect(info.interfaces, hasLength(2));
      expect(info.interfaces.first.name, 'en0');
      expect(info.interfaces.first.macAddress, '00:11:22:33:44:55');
      expect(info.interfaces.first.ipNetworks.single.address, '192.168.1.10');
      expect(info.interfaces.first.operationalState, NetworkOperationalState.up);
      expect(info.interfaces.first.cumulative.totalReceivedBytes, 1024);
    });

    test('snapshot_maps_empty_list', () async {
      mockRustLibApi.networkSnapshotResult = const NetworkInfoDto(
        interfaces: [],
      );

      final domain = NetworkDomainImpl();
      final info = await domain.snapshot();

      expect(info.interfaces, isEmpty);
    });

    test('snapshot_caches_within_ttl', () async {
      final domain = NetworkDomainImpl();

      await domain.snapshot();
      await domain.snapshot();

      expect(mockRustLibApi.networkSnapshotCalls, 1);
    });

    test('snapshot_forceRefresh_bypasses_cache', () async {
      final domain = NetworkDomainImpl();

      await domain.snapshot(forceRefresh: true);
      await domain.snapshot(forceRefresh: true);

      expect(mockRustLibApi.networkSnapshotCalls, 2);
    });
  });

  group('NetworkDomainImpl.throughput', () {
    test('throughput_maps_interfaces', () async {
      final domain = NetworkDomainImpl();
      final values = <NetworkThroughputSample>[];

      final sub = domain.throughput().listen(values.add);
      mockRustLibApi.networkThroughputStreamController.add(
        NetworkThroughputSampleDto(
          interfaces: [
            NetworkThroughputInterfaceDto(
              name: 'en0',
              receivedBytes: BigInt.from(100),
              transmittedBytes: BigInt.from(200),
              packetsReceived: BigInt.from(3),
              packetsTransmitted: BigInt.from(4),
              errorsOnReceived: BigInt.zero,
              errorsOnTransmitted: BigInt.zero,
            ),
          ],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(values, hasLength(1));
      expect(values.single.interfaces.single.receivedBytes, 100);
    });

    test('throughput_clamps_interval_on_desktop_host', () async {
      if (Platform.isAndroid || Platform.isIOS) {
        return;
      }

      final domain = NetworkDomainImpl();
      final sub = domain
          .throughput(interval: const Duration(milliseconds: 10))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(mockRustLibApi.lastThroughputIntervalMs, BigInt.from(50));
    });

    test('throughput_delegates_to_shared_stream_registry', () async {
      final domain = NetworkDomainImpl();
      mockRustLibApi.networkThroughputStreamController.add(
        const NetworkThroughputSampleDto(interfaces: []),
      );

      final firstSub = domain
          .throughput(interval: const Duration(milliseconds: 100))
          .listen((_) {});
      final secondSub = domain
          .throughput(interval: const Duration(milliseconds: 100))
          .listen((_) {});

      await Future<void>.delayed(Duration.zero);

      await firstSub.cancel();
      await secondSub.cancel();

      expect(mockRustLibApi.networkThroughputStreamCalls, 1);
    });
  });
}
