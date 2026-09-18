/// Fake disks domain for unit tests (TDD §5.1).
library;

import 'package:dart_sysinfo/src/domains/disks/disks_domain.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_info.dart';

/// Configurable [DisksDomain] with no native calls.
class FakeDisksDomain implements DisksDomain {
  /// Creates a fake disks domain with an optional canned [snapshot].
  FakeDisksDomain({DisksInfo? snapshot})
      : _snapshot = snapshot ?? DisksInfo.allUnavailable();

  DisksInfo _snapshot;

  /// Test-only mutator — not part of [DisksDomain].
  void setSnapshot(DisksInfo value) => _snapshot = value;

  @override
  Future<DisksInfo> snapshot({bool forceRefresh = false}) async => _snapshot;
}
