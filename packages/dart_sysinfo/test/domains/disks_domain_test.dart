import 'package:dart_sysinfo/src/bridge/api/disks.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_info.dart';
import 'package:test/test.dart';

import '../support/mock_rust_lib_api.dart';

late MockRustLibApi mockRustLibApi;

DiskVolumeDto _sampleVolume({
  required String name,
  required String mountPoint,
  DiskKindDto kind = DiskKindDto.ssd,
}) {
  return DiskVolumeDto(
    name: name,
    kind: kind,
    fileSystem: 'APFS',
    mountPoint: mountPoint,
    totalSpaceBytes: BigInt.from(512 * 1024 * 1024 * 1024),
    availableSpaceBytes: BigInt.from(256 * 1024 * 1024 * 1024),
    isRemovable: false,
    isReadOnly: false,
    ioUsage: DiskIoUsageDto(
      readBytes: BigInt.from(1024),
      writtenBytes: BigInt.from(2048),
      totalReadBytes: BigInt.from(4096),
      totalWrittenBytes: BigInt.from(8192),
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
      ..disksSnapshotCalls = 0
      ..disksSnapshotResult = DisksInfoDto(
        volumes: [
          _sampleVolume(name: 'Macintosh HD', mountPoint: '/'),
          _sampleVolume(
            name: 'External',
            mountPoint: '/Volumes/External',
            kind: DiskKindDto.hdd,
          ),
        ],
      );
  });

  group('DisksDomainImpl.snapshot', () {
    test('snapshot_maps_volumes', () async {
      final domain = DisksDomainImpl();
      final info = await domain.snapshot();

      expect(info.volumes, hasLength(2));
      expect(info.volumes.first.name, 'Macintosh HD');
      expect(info.volumes.first.mountPoint, '/');
      expect(info.volumes.first.kind, DiskKind.ssd);
      expect(info.volumes.first.totalSpaceBytes, 512 * 1024 * 1024 * 1024);
      expect(info.volumes.first.ioUsage.readBytes, 1024);
      expect(info.volumes.last.kind, DiskKind.hdd);
    });

    test('snapshot_maps_empty_list', () async {
      mockRustLibApi.disksSnapshotResult = const DisksInfoDto(volumes: []);

      final domain = DisksDomainImpl();
      final info = await domain.snapshot();

      expect(info.volumes, isEmpty);
    });

    test('snapshot_caches_within_ttl', () async {
      final domain = DisksDomainImpl();

      await domain.snapshot();
      await domain.snapshot();

      expect(mockRustLibApi.disksSnapshotCalls, 1);
    });

    test('snapshot_forceRefresh_bypasses_cache', () async {
      final domain = DisksDomainImpl();

      await domain.snapshot(forceRefresh: true);
      await domain.snapshot(forceRefresh: true);

      expect(mockRustLibApi.disksSnapshotCalls, 2);
    });
  });
}
