/// Disks domain interface (TDD §4.4).
library;

import 'package:dart_sysinfo/src/domains/disks/disks_info.dart';

/// Disks metrics: TTL-cached snapshot of mounted volumes.
abstract class DisksDomain {
  /// Returns a TTL-cached disks snapshot.
  Future<DisksInfo> snapshot({bool forceRefresh = false});
}
