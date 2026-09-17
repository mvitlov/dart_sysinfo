/// Maps FRB memory DTOs to public domain models (TDD §4.2).
library;

import 'package:dart_sysinfo/src/bridge/api/memory.dart';
import 'package:dart_sysinfo/src/core/reading.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_info.dart';

/// Maps a native [MemoryInfoDto] to the public [MemoryInfo] model.
MemoryInfo mapMemoryInfoDto(MemoryInfoDto dto) {
  return MemoryInfo(
    totalMemoryBytes: dto.totalMemoryBytes.toInt(),
    freeMemoryBytes: dto.freeMemoryBytes.toInt(),
    availableMemoryBytes: dto.availableMemoryBytes.toInt(),
    usedMemoryBytes: dto.usedMemoryBytes.toInt(),
    totalSwapBytes: dto.totalSwapBytes.toInt(),
    freeSwapBytes: dto.freeSwapBytes.toInt(),
    usedSwapBytes: dto.usedSwapBytes.toInt(),
    cgroupLimits: _mapCGroupLimits(dto.cgroupLimits),
  );
}

Reading<CGroupLimits> _mapCGroupLimits(CGroupLimitsReadingDto dto) {
  if (!dto.supported) {
    return const ReadingUnsupported(
      reason: 'cgroup limits are Linux-only',
    );
  }
  final value = dto.value;
  if (value == null) {
    return const ReadingUnavailable();
  }
  return ReadingValue(
    CGroupLimits(
      totalMemoryBytes: value.totalMemoryBytes.toInt(),
      freeMemoryBytes: value.freeMemoryBytes.toInt(),
      freeSwapBytes: value.freeSwapBytes.toInt(),
      rssBytes: value.rssBytes.toInt(),
    ),
  );
}
