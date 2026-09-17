import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/src/bridge/api/memory.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain_impl.dart';
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
      ..memorySnapshotCalls = 0
      ..memorySnapshotResult = MemoryInfoDto(
        totalMemoryBytes: BigInt.from(16 * 1024 * 1024 * 1024),
        freeMemoryBytes: BigInt.from(4 * 1024 * 1024 * 1024),
        availableMemoryBytes: BigInt.from(6 * 1024 * 1024 * 1024),
        usedMemoryBytes: BigInt.from(10 * 1024 * 1024 * 1024),
        totalSwapBytes: BigInt.from(2 * 1024 * 1024 * 1024),
        freeSwapBytes: BigInt.from(1 * 1024 * 1024 * 1024),
        usedSwapBytes: BigInt.from(1 * 1024 * 1024 * 1024),
        cgroupLimits: const CGroupLimitsReadingDto(supported: false),
      );
  });

  group('MemoryDomainImpl.snapshot', () {
    test('snapshot_maps_plain_fields', () async {
      final domain = MemoryDomainImpl();
      final info = await domain.snapshot();

      expect(info.totalMemoryBytes, 16 * 1024 * 1024 * 1024);
      expect(info.freeMemoryBytes, 4 * 1024 * 1024 * 1024);
      expect(info.availableMemoryBytes, 6 * 1024 * 1024 * 1024);
      expect(info.usedMemoryBytes, 10 * 1024 * 1024 * 1024);
      expect(info.totalSwapBytes, 2 * 1024 * 1024 * 1024);
      expect(info.freeSwapBytes, 1 * 1024 * 1024 * 1024);
      expect(info.usedSwapBytes, 1 * 1024 * 1024 * 1024);
    });

    test('snapshot_maps_cgroup_unsupported', () async {
      mockRustLibApi.memorySnapshotResult = MemoryInfoDto(
        totalMemoryBytes: BigInt.zero,
        freeMemoryBytes: BigInt.zero,
        availableMemoryBytes: BigInt.zero,
        usedMemoryBytes: BigInt.zero,
        totalSwapBytes: BigInt.zero,
        freeSwapBytes: BigInt.zero,
        usedSwapBytes: BigInt.zero,
        cgroupLimits: const CGroupLimitsReadingDto(supported: false),
      );

      final domain = MemoryDomainImpl();
      final info = await domain.snapshot();

      expect(info.cgroupLimits.isUnsupported, isTrue);
      expect(
        info.cgroupLimits.maybeWhen(
          unsupported: (reason) => reason,
          orElse: () => null,
        ),
        'cgroup limits are Linux-only',
      );
    });

    test('snapshot_maps_cgroup_unavailable', () async {
      mockRustLibApi.memorySnapshotResult = MemoryInfoDto(
        totalMemoryBytes: BigInt.zero,
        freeMemoryBytes: BigInt.zero,
        availableMemoryBytes: BigInt.zero,
        usedMemoryBytes: BigInt.zero,
        totalSwapBytes: BigInt.zero,
        freeSwapBytes: BigInt.zero,
        usedSwapBytes: BigInt.zero,
        cgroupLimits: const CGroupLimitsReadingDto(supported: true),
      );

      final domain = MemoryDomainImpl();
      final info = await domain.snapshot();

      expect(info.cgroupLimits.isUnavailable, isTrue);
    });

    test('snapshot_maps_cgroup_value', () async {
      mockRustLibApi.memorySnapshotResult = MemoryInfoDto(
        totalMemoryBytes: BigInt.zero,
        freeMemoryBytes: BigInt.zero,
        availableMemoryBytes: BigInt.zero,
        usedMemoryBytes: BigInt.zero,
        totalSwapBytes: BigInt.zero,
        freeSwapBytes: BigInt.zero,
        usedSwapBytes: BigInt.zero,
        cgroupLimits: CGroupLimitsReadingDto(
          supported: true,
          value: CGroupLimitsDto(
            totalMemoryBytes: BigInt.from(512 * 1024 * 1024),
            freeMemoryBytes: BigInt.from(256 * 1024 * 1024),
            freeSwapBytes: BigInt.from(128 * 1024 * 1024),
            rssBytes: BigInt.from(64 * 1024 * 1024),
          ),
        ),
      );

      final domain = MemoryDomainImpl();
      final info = await domain.snapshot();

      expect(info.cgroupLimits.isValue, isTrue);
      final limits = info.cgroupLimits.valueOrNull!;
      expect(limits.totalMemoryBytes, 512 * 1024 * 1024);
      expect(limits.freeMemoryBytes, 256 * 1024 * 1024);
      expect(limits.freeSwapBytes, 128 * 1024 * 1024);
      expect(limits.rssBytes, 64 * 1024 * 1024);
    });

    test('snapshot_caches_within_500ms', () async {
      final domain = MemoryDomainImpl();

      await domain.snapshot();
      await domain.snapshot();

      expect(mockRustLibApi.memorySnapshotCalls, 1);
    });

    test('snapshot_forceRefresh_bypasses_cache', () async {
      final domain = MemoryDomainImpl();

      await domain.snapshot(forceRefresh: true);
      await domain.snapshot(forceRefresh: true);

      expect(mockRustLibApi.memorySnapshotCalls, 2);
    });
  });
}
