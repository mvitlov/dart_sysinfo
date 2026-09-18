import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/testing.dart';
import 'package:test/test.dart';

void main() {
  group('FakeCpuDomain', () {
    test('fake_cpu_defaults_to_all_unavailable', () async {
      final domain = FakeCpuDomain();
      final info = await domain.snapshot();

      expect(info.physicalCoreCount.isUnavailable, isTrue);
      expect(info.globalUsagePercent.isUnavailable, isTrue);
      expect(info.cores.isUnavailable, isTrue);
    });

    test('fake_cpu_setSnapshot_updates_return_value', () async {
      final domain = FakeCpuDomain();
      domain.setSnapshot(
        const CpuInfo(
          architecture: 'aarch64',
          physicalCoreCount: ReadingValue(8),
          globalUsagePercent: ReadingValue(42.0),
          cores: ReadingValue([]),
        ),
      );

      final info = await domain.snapshot();
      expect(info.architecture, 'aarch64');
      expect(info.physicalCoreCount.valueOrNull, 8);
    });

    test('fake_cpu_forceRefresh_returns_same_snapshot', () async {
      final domain = FakeCpuDomain(
        snapshot: const CpuInfo(
          architecture: 'x86_64',
          physicalCoreCount: ReadingValue(4),
          globalUsagePercent: ReadingValue(10.0),
          cores: ReadingValue([]),
        ),
      );

      final first = await domain.snapshot(forceRefresh: true);
      final second = await domain.snapshot(forceRefresh: true);

      expect(first.architecture, second.architecture);
      expect(first.physicalCoreCount.valueOrNull, 4);
    });

    test('fake_cpu_emitLoad_delivers_to_listener', () async {
      final domain = FakeCpuDomain();
      final values = <CpuLoadSample>[];

      final sub = domain.load().listen(values.add);
      domain.emitLoad(
        const CpuLoadSample(
          globalUsagePercent: 12.5,
          perCoreUsagePercent: [12.5],
        ),
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(values, hasLength(1));
      expect(values.single.globalUsagePercent, 12.5);
    });
  });

  group('FakeDisksDomain', () {
    test('fake_disks_defaults_and_setSnapshot', () async {
      final domain = FakeDisksDomain();
      final defaultInfo = await domain.snapshot();

      expect(defaultInfo.volumes, isEmpty);

      domain.setSnapshot(
        DisksInfo(
          volumes: [
            DiskVolume(
              name: 'Data',
              kind: DiskKind.ssd,
              fileSystem: 'ext4',
              mountPoint: '/data',
              totalSpaceBytes: 1024,
              availableSpaceBytes: 512,
              isRemovable: false,
              isReadOnly: false,
              ioUsage: const DiskIoUsage(
                readBytes: 1,
                writtenBytes: 2,
                totalReadBytes: 3,
                totalWrittenBytes: 4,
              ),
            ),
          ],
        ),
      );

      final updated = await domain.snapshot();
      expect(updated.volumes, hasLength(1));
      expect(updated.volumes.single.mountPoint, '/data');
    });
  });

  group('FakeMemoryDomain', () {
    test('fake_memory_defaults_and_setSnapshot', () async {
      final domain = FakeMemoryDomain();
      final defaultInfo = await domain.snapshot();

      expect(defaultInfo.cgroupLimits.isUnavailable, isTrue);

      domain.setSnapshot(
        MemoryInfo(
          totalMemoryBytes: 16 * 1024 * 1024 * 1024,
          freeMemoryBytes: 8 * 1024 * 1024 * 1024,
          availableMemoryBytes: 8 * 1024 * 1024 * 1024,
          usedMemoryBytes: 8 * 1024 * 1024 * 1024,
          totalSwapBytes: 0,
          freeSwapBytes: 0,
          usedSwapBytes: 0,
          cgroupLimits: const ReadingValue(
            CGroupLimits(
              totalMemoryBytes: 512 * 1024 * 1024,
              freeMemoryBytes: 256 * 1024 * 1024,
              freeSwapBytes: 0,
              rssBytes: 64 * 1024 * 1024,
            ),
          ),
        ),
      );

      final updated = await domain.snapshot();
      expect(updated.totalMemoryBytes, 16 * 1024 * 1024 * 1024);
      expect(updated.cgroupLimits.isValue, isTrue);
    });
  });

  group('FakeOsDomain', () {
    test('fake_os_defaults_and_setSnapshot', () async {
      final domain = FakeOsDomain();
      final defaultInfo = await domain.snapshot();

      expect(defaultInfo.name.isUnavailable, isTrue);

      domain.setSnapshot(
        const OsInfo(
          name: ReadingValue('Ubuntu'),
          kernelVersion: ReadingValue('6.8.0'),
          osVersion: ReadingValue('24.04'),
          longOsVersion: ReadingValue('Linux (Ubuntu 24.04)'),
          hostName: ReadingValue('dev-box'),
          distributionId: 'ubuntu',
          distributionIdLike: ['debian'],
          kernelLongVersion: 'Linux 6.8.0',
          uptimeSeconds: 86400,
          bootTimeSeconds: 1700000000,
          loadAverage: ReadingUnavailable(),
        ),
      );

      final updated = await domain.snapshot();
      expect(updated.name.valueOrNull, 'Ubuntu');
      expect(updated.distributionId, 'ubuntu');
    });

    test('fake_os_reading_variants_configurable', () async {
      final domain = FakeOsDomain(
        snapshot: const OsInfo(
          name: ReadingValue('Windows'),
          kernelVersion: ReadingUnsupported(reason: 'restricted'),
          osVersion: ReadingUnavailable(reason: 'retry later'),
          longOsVersion: ReadingValue('Windows Server 2022'),
          hostName: ReadingUnavailable(),
          distributionId: 'windows',
          distributionIdLike: [],
          kernelLongVersion: 'Windows OS Build 20348',
          uptimeSeconds: 0,
          bootTimeSeconds: 0,
          loadAverage: ReadingUnsupported(
            reason: 'load average is not available on Windows',
          ),
        ),
      );

      final info = await domain.snapshot();

      expect(info.name.isValue, isTrue);
      expect(info.kernelVersion.isUnsupported, isTrue);
      expect(info.osVersion.isUnavailable, isTrue);
      expect(info.loadAverage.isUnsupported, isTrue);
    });
  });

  group('FakeSysInfo', () {
    tearDown(SysInfo.resetForTesting);

    test('fake_sys_info_works_with_overrideInstance', () {
      final cpu = FakeCpuDomain(
        snapshot: const CpuInfo(
          architecture: 'mock',
          physicalCoreCount: ReadingValue(1),
          globalUsagePercent: ReadingValue(1.0),
          cores: ReadingValue([]),
        ),
      );
      final fake = FakeSysInfo(cpu: cpu);

      SysInfo.overrideInstance(fake);

      expect(identical(SysInfo.instance, fake), isTrue);
      expect(identical(SysInfo.instance.cpu, cpu), isTrue);
      expect(SysInfo.instance.memory, isA<FakeMemoryDomain>());
      expect(SysInfo.instance.disks, isA<FakeDisksDomain>());
      expect(SysInfo.instance.os, isA<FakeOsDomain>());
    });

    test('fake_sys_info_dispose_is_noop', () async {
      final fake = FakeSysInfo();
      await expectLater(fake.dispose(), completes);
    });
  });
}
