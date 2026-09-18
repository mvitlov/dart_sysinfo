/// Disks snapshot model (TDD §4.4).
library;

import 'package:meta/meta.dart';

/// Disks snapshot returned by [DisksDomain.snapshot].
@immutable
class DisksInfo {
  /// Creates a disks snapshot with the given mounted volumes.
  const DisksInfo({
    required this.volumes,
  });

  /// Mounted volumes visible to the current process.
  ///
  /// An empty list is valid on sandboxes, scoped-storage contexts, and CI VMs —
  /// not an error condition.
  final List<DiskVolume> volumes;

  /// Safe default for unconfigured fakes (TDD §5.1).
  factory DisksInfo.allUnavailable() => const DisksInfo(volumes: []);
}

/// Physical disk kind for a mounted volume.
enum DiskKind {
  /// Hard disk drive.
  hdd,

  /// Solid-state drive.
  ssd,

  /// Unknown or undetectable kind.
  unknown,
}

/// A single mounted volume reported by the native layer.
@immutable
class DiskVolume {
  /// Creates a disk volume with the given metadata.
  const DiskVolume({
    required this.name,
    required this.kind,
    required this.fileSystem,
    required this.mountPoint,
    required this.totalSpaceBytes,
    required this.availableSpaceBytes,
    required this.isRemovable,
    required this.isReadOnly,
    required this.ioUsage,
  });

  /// Volume label or device name.
  final String name;

  /// Physical disk kind when detectable.
  final DiskKind kind;

  /// File system type (for example `ext4`, `NTFS`).
  final String fileSystem;

  /// Mount point path (for example `/` or `C:`).
  final String mountPoint;

  /// Total capacity in bytes.
  final int totalSpaceBytes;

  /// Available space in bytes.
  final int availableSpaceBytes;

  /// Whether the volume is on removable media.
  final bool isRemovable;

  /// Whether the volume is read-only.
  final bool isReadOnly;

  /// Cumulative I/O counters from the native refresh.
  final DiskIoUsage ioUsage;
}

/// Cumulative disk I/O counters — not a throughput stream.
@immutable
class DiskIoUsage {
  /// Creates disk I/O counters.
  const DiskIoUsage({
    required this.readBytes,
    required this.writtenBytes,
    required this.totalReadBytes,
    required this.totalWrittenBytes,
  });

  /// Bytes read since the last native refresh.
  final int readBytes;

  /// Bytes written since the last native refresh.
  final int writtenBytes;

  /// Total bytes read since boot or counter reset.
  final int totalReadBytes;

  /// Total bytes written since boot or counter reset.
  final int totalWrittenBytes;
}
