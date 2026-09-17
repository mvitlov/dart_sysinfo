/// Maps FRB OS DTOs to public domain models (TDD §4.3).
library;

import 'package:dart_sysinfo/src/bridge/api/os.dart';
import 'package:dart_sysinfo/src/core/reading.dart';
import 'package:dart_sysinfo/src/domains/os/os_info.dart';

/// Maps a native [OsInfoDto] to the public [OsInfo] model.
OsInfo mapOsInfoDto(OsInfoDto dto) {
  return OsInfo(
    name: _mapReadingString(dto.name),
    kernelVersion: _mapReadingString(dto.kernelVersion),
    osVersion: _mapReadingString(dto.osVersion),
    longOsVersion: _mapReadingString(dto.longOsVersion),
    hostName: _mapReadingString(dto.hostName),
    distributionId: dto.distributionId,
    distributionIdLike: dto.distributionIdLike.toList(),
    kernelLongVersion: dto.kernelLongVersion,
    uptimeSeconds: dto.uptimeSeconds.toInt(),
    bootTimeSeconds: dto.bootTimeSeconds.toInt(),
    loadAverage: _mapLoadAverage(dto.loadAverage),
  );
}

Reading<String> _mapReadingString(String? value) {
  if (value == null) {
    return const ReadingUnavailable();
  }
  return ReadingValue(value);
}

Reading<LoadAverage> _mapLoadAverage(LoadAverageReadingDto dto) {
  if (!dto.supported) {
    return const ReadingUnsupported(
      reason: 'load average is not available on Windows',
    );
  }
  final value = dto.value;
  if (value == null) {
    return const ReadingUnavailable();
  }
  return ReadingValue(
    LoadAverage(
      one: value.one,
      five: value.five,
      fifteen: value.fifteen,
    ),
  );
}
