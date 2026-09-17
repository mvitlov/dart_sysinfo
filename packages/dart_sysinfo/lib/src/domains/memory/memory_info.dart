/// Memory snapshot model (TDD §4.2).
library;

import 'package:dart_sysinfo/src/core/reading.dart';
import 'package:meta/meta.dart';

/// Memory snapshot returned by [MemoryDomain.snapshot].
@immutable
class MemoryInfo {
  /// Creates a memory snapshot with the given byte fields and cgroup limits.
  const MemoryInfo({
    required this.totalMemoryBytes,
    required this.freeMemoryBytes,
    required this.availableMemoryBytes,
    required this.usedMemoryBytes,
    required this.totalSwapBytes,
    required this.freeSwapBytes,
    required this.usedSwapBytes,
    required this.cgroupLimits,
  });

  /// Total physical memory in bytes.
  final int totalMemoryBytes;

  /// Free memory in bytes. May match [availableMemoryBytes] on Windows/FreeBSD.
  final int freeMemoryBytes;

  /// Memory available for new allocations without swapping.
  final int availableMemoryBytes;

  /// Used memory in bytes.
  final int usedMemoryBytes;

  /// Total swap space in bytes.
  final int totalSwapBytes;

  /// Free swap space in bytes.
  final int freeSwapBytes;

  /// Used swap space in bytes.
  final int usedSwapBytes;

  /// Root cgroup memory limits when supported on this platform.
  final Reading<CGroupLimits> cgroupLimits;

  /// Safe default for unconfigured fakes (TDD §5.1 — used by M1-12).
  factory MemoryInfo.allUnavailable() => const MemoryInfo(
        totalMemoryBytes: 0,
        freeMemoryBytes: 0,
        availableMemoryBytes: 0,
        usedMemoryBytes: 0,
        totalSwapBytes: 0,
        freeSwapBytes: 0,
        usedSwapBytes: 0,
        cgroupLimits: ReadingUnavailable(reason: 'not configured'),
      );
}

/// Root cgroup memory limits (Linux-only).
@immutable
class CGroupLimits {
  /// Creates cgroup limit readings in bytes.
  const CGroupLimits({
    required this.totalMemoryBytes,
    required this.freeMemoryBytes,
    required this.freeSwapBytes,
    required this.rssBytes,
  });

  /// Cgroup memory limit in bytes.
  final int totalMemoryBytes;

  /// Free memory within the cgroup in bytes.
  final int freeMemoryBytes;

  /// Free swap within the cgroup in bytes.
  final int freeSwapBytes;

  /// Resident set size within the cgroup in bytes.
  final int rssBytes;
}
