/// OS snapshot model (TDD §4.3).
library;

import 'package:dart_sysinfo/src/core/reading.dart';
import 'package:meta/meta.dart';

/// OS snapshot returned by [OsDomain.snapshot].
@immutable
class OsInfo {
  /// Creates an OS snapshot with the given field readings.
  const OsInfo({
    required this.name,
    required this.kernelVersion,
    required this.osVersion,
    required this.longOsVersion,
    required this.hostName,
    required this.distributionId,
    required this.distributionIdLike,
    required this.kernelLongVersion,
    required this.uptimeSeconds,
    required this.bootTimeSeconds,
    required this.loadAverage,
  });

  /// OS name when reported by the platform.
  final Reading<String> name;

  /// Kernel version string when available.
  final Reading<String> kernelVersion;

  /// OS version string when available.
  final Reading<String> osVersion;

  /// Long-form OS version string when available.
  final Reading<String> longOsVersion;

  /// Host name from DNS when available.
  final Reading<String> hostName;

  /// Distribution identifier; never empty on supported platforms.
  final String distributionId;

  /// Related distribution identifiers; empty list is valid.
  final List<String> distributionIdLike;

  /// Long kernel version string; falls back to `"unknown"` when unavailable.
  final String kernelLongVersion;

  /// System uptime in seconds.
  final int uptimeSeconds;

  /// Boot time as seconds since the UNIX epoch.
  final int bootTimeSeconds;

  /// Load averages when supported on this platform.
  final Reading<LoadAverage> loadAverage;

  /// Safe default for unconfigured fakes (TDD §5.1 — used by M1-12).
  factory OsInfo.allUnavailable() => const OsInfo(
        name: ReadingUnavailable(reason: 'not configured'),
        kernelVersion: ReadingUnavailable(reason: 'not configured'),
        osVersion: ReadingUnavailable(reason: 'not configured'),
        longOsVersion: ReadingUnavailable(reason: 'not configured'),
        hostName: ReadingUnavailable(reason: 'not configured'),
        distributionId: '',
        distributionIdLike: [],
        kernelLongVersion: 'unknown',
        uptimeSeconds: 0,
        bootTimeSeconds: 0,
        loadAverage: ReadingUnavailable(reason: 'not configured'),
      );
}

/// One-minute, five-minute, and fifteen-minute load averages.
@immutable
class LoadAverage {
  /// Creates load average readings.
  const LoadAverage({
    required this.one,
    required this.five,
    required this.fifteen,
  });

  /// One-minute load average.
  final double one;

  /// Five-minute load average.
  final double five;

  /// Fifteen-minute load average.
  final double fifteen;
}
