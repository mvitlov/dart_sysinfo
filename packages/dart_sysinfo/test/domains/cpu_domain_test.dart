import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain_impl.dart';
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
      ..cpuSnapshotCalls = 0
      ..cpuLoadStreamCalls = 0
      ..lastLoadIntervalMs = null
      ..cpuSnapshotResult = const CpuInfoDto(architecture: 'mock');
  });

  tearDown(() async {
    await SharedStreamRegistry.instance.cancelAll();
  });

  group('CpuDomainImpl.snapshot', () {
    test('snapshot_maps_dto_to_reading_fields', () async {
      mockRustLibApi.cpuSnapshotResult = const CpuInfoDto(
        architecture: 'aarch64',
        physicalCoreCount: null,
        globalUsagePercent: null,
        cores: null,
      );

      final domain = CpuDomainImpl();
      final info = await domain.snapshot();

      expect(info.architecture, 'aarch64');
      expect(info.physicalCoreCount.isUnavailable, isTrue);
      expect(info.globalUsagePercent.isUnavailable, isTrue);
      expect(info.cores.isUnsupported, isTrue);
    });

    test('snapshot_caches_within_500ms', () async {
      final domain = CpuDomainImpl();

      await domain.snapshot();
      await domain.snapshot();

      expect(mockRustLibApi.cpuSnapshotCalls, 1);
    });

    test('snapshot_forceRefresh_bypasses_cache', () async {
      final domain = CpuDomainImpl();

      await domain.snapshot(forceRefresh: true);
      await domain.snapshot(forceRefresh: true);

      expect(mockRustLibApi.cpuSnapshotCalls, 2);
    });
  });

  group('CpuDomainImpl.load', () {
    test('load_clamps_interval_on_desktop_host', () async {
      if (Platform.isAndroid || Platform.isIOS) {
        return;
      }

      final domain = CpuDomainImpl();
      final sub = domain.load(interval: const Duration(milliseconds: 10)).listen(
        (_) {},
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(mockRustLibApi.lastLoadIntervalMs, BigInt.from(50));
    });

    test('load_delegates_to_shared_stream_registry', () async {
      final domain = CpuDomainImpl();
      mockRustLibApi.cpuLoadStreamController.add(
        CpuLoadSampleDto(
          globalUsagePercent: 12.5,
          perCoreUsagePercent: Float32List.fromList([12.5]),
        ),
      );

      final firstSub = domain
          .load(interval: const Duration(milliseconds: 100))
          .listen((_) {});
      final secondSub = domain
          .load(interval: const Duration(milliseconds: 100))
          .listen((_) {});

      await Future<void>.delayed(Duration.zero);

      await firstSub.cancel();
      await secondSub.cancel();

      expect(mockRustLibApi.cpuLoadStreamCalls, 1);
    });

    test('load_recreates_poller_after_all_listeners_cancel', () async {
      final domain = CpuDomainImpl();

      final sub1 = domain
          .load(interval: const Duration(milliseconds: 100))
          .listen((_) {});
      final sub2 = domain
          .load(interval: const Duration(milliseconds: 100))
          .listen((_) {});

      await sub1.cancel();
      await sub2.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(mockRustLibApi.cpuLoadStreamCalls, 1);

      final sub3 = domain
          .load(interval: const Duration(milliseconds: 100))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);

      expect(mockRustLibApi.cpuLoadStreamCalls, 2);

      await sub3.cancel();
    });
  });
}
