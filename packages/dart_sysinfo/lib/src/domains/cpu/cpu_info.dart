/// CPU snapshot and stream models (TDD §4.1).
library;

import 'package:dart_sysinfo/src/core/reading.dart';
import 'package:meta/meta.dart';

/// CPU snapshot returned by [CpuDomain.snapshot].
@immutable
class CpuInfo {
  /// Creates a CPU snapshot with the given field readings.
  const CpuInfo({
    required this.architecture,
    required this.physicalCoreCount,
    required this.globalUsagePercent,
    required this.cores,
  });

  /// CPU architecture string from the OS.
  final String architecture;

  /// Number of physical cores when detectable.
  final Reading<int> physicalCoreCount;

  /// Global CPU usage percentage when a diff-based sample is available.
  final Reading<double> globalUsagePercent;

  /// Per-core details when enumeration is supported on this platform.
  final Reading<List<CpuCoreInfo>> cores;

  /// Safe default for unconfigured fakes (TDD §5.1 — used by M1-12).
  factory CpuInfo.allUnavailable() => const CpuInfo(
        architecture: '',
        physicalCoreCount: ReadingUnavailable(reason: 'not configured'),
        globalUsagePercent: ReadingUnavailable(reason: 'not configured'),
        cores: ReadingUnavailable(reason: 'not configured'),
      );
}

/// Per-core CPU details when the core list itself is available.
@immutable
class CpuCoreInfo {
  /// Creates per-core CPU details.
  const CpuCoreInfo({
    required this.name,
    required this.vendorId,
    required this.brand,
    required this.frequencyMhz,
    required this.usagePercent,
  });

  /// Core label reported by the OS.
  final String name;

  /// CPU vendor identifier.
  final String vendorId;

  /// CPU marketing brand string.
  final String brand;

  /// Current frequency in megahertz.
  final int frequencyMhz;

  /// Core usage percentage for the latest sample.
  final double usagePercent;
}

/// One CPU load stream sample (plain fields — TDD §4.1).
@immutable
class CpuLoadSample {
  /// Creates one CPU load stream tick.
  const CpuLoadSample({
    required this.globalUsagePercent,
    required this.perCoreUsagePercent,
  });

  /// Global CPU usage percentage for this tick.
  final double globalUsagePercent;

  /// Per-core usage percentages aligned with core order.
  final List<double> perCoreUsagePercent;
}
