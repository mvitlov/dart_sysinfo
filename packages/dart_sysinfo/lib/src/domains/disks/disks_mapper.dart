/// Maps FRB disks DTOs to public domain models (TDD §4.4).
library;

import 'package:dart_sysinfo/src/bridge/api/disks.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_info.dart';

/// Maps a native [DisksInfoDto] to the public [DisksInfo] model.
DisksInfo mapDisksInfoDto(DisksInfoDto dto) {
  return DisksInfo(
    volumes: dto.volumes.map(mapDiskVolumeDto).toList(growable: false),
  );
}

DiskVolume mapDiskVolumeDto(DiskVolumeDto dto) {
  return DiskVolume(
    name: dto.name,
    kind: mapDiskKindDto(dto.kind),
    fileSystem: dto.fileSystem,
    mountPoint: dto.mountPoint,
    totalSpaceBytes: dto.totalSpaceBytes.toInt(),
    availableSpaceBytes: dto.availableSpaceBytes.toInt(),
    isRemovable: dto.isRemovable,
    isReadOnly: dto.isReadOnly,
    ioUsage: mapDiskIoUsageDto(dto.ioUsage),
  );
}

DiskKind mapDiskKindDto(DiskKindDto dto) {
  return switch (dto) {
    DiskKindDto.hdd => DiskKind.hdd,
    DiskKindDto.ssd => DiskKind.ssd,
    DiskKindDto.unknown => DiskKind.unknown,
  };
}

DiskIoUsage mapDiskIoUsageDto(DiskIoUsageDto dto) {
  return DiskIoUsage(
    readBytes: dto.readBytes.toInt(),
    writtenBytes: dto.writtenBytes.toInt(),
    totalReadBytes: dto.totalReadBytes.toInt(),
    totalWrittenBytes: dto.totalWrittenBytes.toInt(),
  );
}
