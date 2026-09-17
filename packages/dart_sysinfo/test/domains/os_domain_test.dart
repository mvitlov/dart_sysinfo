import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/src/bridge/api/os.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain_impl.dart';
import 'package:test/test.dart';

import '../support/mock_rust_lib_api.dart';

late MockRustLibApi mockRustLibApi;

void main() {
  setUpAll(() {
    mockRustLibApi = MockRustLibApi();
    RustLib.initMock(api: mockRustLibApi);
  });

  setUp(() {
    mockRustLibApi
      ..osSnapshotCalls = 0
      ..osSnapshotResult = OsInfoDto(
        name: 'Ubuntu',
        kernelVersion: '6.8.0',
        osVersion: '24.04',
        longOsVersion: 'Linux (Ubuntu 24.04)',
        hostName: 'dev-box',
        distributionId: 'ubuntu',
        distributionIdLike: const ['debian'],
        kernelLongVersion: 'Linux 6.8.0',
        uptimeSeconds: BigInt.from(86400),
        bootTimeSeconds: BigInt.from(1700000000),
        loadAverage: const LoadAverageReadingDto(supported: false),
      );
  });

  group('OsDomainImpl.snapshot', () {
    test('snapshot_maps_plain_fields', () async {
      final domain = OsDomainImpl();
      final info = await domain.snapshot();

      expect(info.distributionId, 'ubuntu');
      expect(info.distributionIdLike, ['debian']);
      expect(info.kernelLongVersion, 'Linux 6.8.0');
      expect(info.uptimeSeconds, 86400);
      expect(info.bootTimeSeconds, 1700000000);
    });

    test('snapshot_maps_reading_string_unavailable', () async {
      mockRustLibApi.osSnapshotResult = OsInfoDto(
        distributionId: 'macos',
        distributionIdLike: const [],
        kernelLongVersion: 'Darwin 24.1.0',
        uptimeSeconds: BigInt.zero,
        bootTimeSeconds: BigInt.zero,
        loadAverage: const LoadAverageReadingDto(supported: false),
      );

      final domain = OsDomainImpl();
      final info = await domain.snapshot();

      expect(info.name.isUnavailable, isTrue);
      expect(info.kernelVersion.isUnavailable, isTrue);
      expect(info.osVersion.isUnavailable, isTrue);
      expect(info.longOsVersion.isUnavailable, isTrue);
      expect(info.hostName.isUnavailable, isTrue);
    });

    test('snapshot_maps_reading_string_value', () async {
      final domain = OsDomainImpl();
      final info = await domain.snapshot();

      expect(info.name.valueOrNull, 'Ubuntu');
      expect(info.kernelVersion.valueOrNull, '6.8.0');
      expect(info.osVersion.valueOrNull, '24.04');
      expect(info.longOsVersion.valueOrNull, 'Linux (Ubuntu 24.04)');
      expect(info.hostName.valueOrNull, 'dev-box');
    });

    test('snapshot_maps_load_average_unsupported', () async {
      mockRustLibApi.osSnapshotResult = OsInfoDto(
        distributionId: 'windows',
        distributionIdLike: const [],
        kernelLongVersion: 'Windows OS Build 20348',
        uptimeSeconds: BigInt.zero,
        bootTimeSeconds: BigInt.zero,
        loadAverage: const LoadAverageReadingDto(supported: false),
      );

      final domain = OsDomainImpl();
      final info = await domain.snapshot();

      expect(info.loadAverage.isUnsupported, isTrue);
      expect(
        info.loadAverage.maybeWhen(
          unsupported: (reason) => reason,
          orElse: () => null,
        ),
        'load average is not available on Windows',
      );
    });

    test('snapshot_maps_load_average_unavailable', () async {
      mockRustLibApi.osSnapshotResult = OsInfoDto(
        distributionId: 'linux',
        distributionIdLike: const [],
        kernelLongVersion: 'Linux 6.8.0',
        uptimeSeconds: BigInt.zero,
        bootTimeSeconds: BigInt.zero,
        loadAverage: const LoadAverageReadingDto(supported: true),
      );

      final domain = OsDomainImpl();
      final info = await domain.snapshot();

      expect(info.loadAverage.isUnavailable, isTrue);
    });

    test('snapshot_maps_load_average_value', () async {
      mockRustLibApi.osSnapshotResult = OsInfoDto(
        distributionId: 'linux',
        distributionIdLike: const [],
        kernelLongVersion: 'Linux 6.8.0',
        uptimeSeconds: BigInt.zero,
        bootTimeSeconds: BigInt.zero,
        loadAverage: const LoadAverageReadingDto(
          supported: true,
          value: LoadAverageDto(one: 0.42, five: 0.35, fifteen: 0.28),
        ),
      );

      final domain = OsDomainImpl();
      final info = await domain.snapshot();

      expect(info.loadAverage.isValue, isTrue);
      final load = info.loadAverage.valueOrNull!;
      expect(load.one, 0.42);
      expect(load.five, 0.35);
      expect(load.fifteen, 0.28);
    });

    test('snapshot_caches_within_2000ms', () async {
      final domain = OsDomainImpl();

      await domain.snapshot();
      await domain.snapshot();

      expect(mockRustLibApi.osSnapshotCalls, 1);
    });

    test('snapshot_forceRefresh_bypasses_cache', () async {
      final domain = OsDomainImpl();

      await domain.snapshot(forceRefresh: true);
      await domain.snapshot(forceRefresh: true);

      expect(mockRustLibApi.osSnapshotCalls, 2);
    });
  });
}
