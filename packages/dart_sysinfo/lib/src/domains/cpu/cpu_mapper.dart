/// Maps FRB CPU DTOs to public domain models (TDD §4.1).
library;

import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/core/reading.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_info.dart';

/// Maps a native [CpuInfoDto] to the public [CpuInfo] model.
CpuInfo mapCpuInfoDto(CpuInfoDto dto) {
  return CpuInfo(
    architecture: dto.architecture,
    physicalCoreCount: dto.physicalCoreCount != null
        ? ReadingValue(dto.physicalCoreCount!)
        : const ReadingUnavailable(
            reason: 'not detectable on this platform',
          ),
    globalUsagePercent: dto.globalUsagePercent != null
        ? ReadingValue(dto.globalUsagePercent!)
        : const ReadingUnavailable(
            reason: 'first sample; call snapshot() again',
          ),
    cores: dto.cores != null
        ? ReadingValue(dto.cores!.map(mapCpuCoreDto).toList())
        : const ReadingUnsupported(
            reason: 'CPU enumeration restricted on this platform',
          ),
  );
}

/// Maps a native [CpuLoadSampleDto] to the public [CpuLoadSample] model.
CpuLoadSample mapCpuLoadSampleDto(CpuLoadSampleDto dto) {
  return CpuLoadSample(
    globalUsagePercent: dto.globalUsagePercent,
    perCoreUsagePercent: dto.perCoreUsagePercent.toList(),
  );
}

CpuCoreInfo mapCpuCoreDto(CpuCoreDto dto) {
  return CpuCoreInfo(
    name: dto.name,
    vendorId: dto.vendorId,
    brand: dto.brand,
    frequencyMhz: dto.frequencyMhz.toInt(),
    usagePercent: dto.usagePercent,
  );
}
