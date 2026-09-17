/// Fake OS domain for unit tests (TDD §5.1).
library;

import 'package:dart_sysinfo/src/domains/os/os_domain.dart';
import 'package:dart_sysinfo/src/domains/os/os_info.dart';

/// Configurable [OsDomain] with no native calls.
class FakeOsDomain implements OsDomain {
  /// Creates a fake OS domain with an optional canned [snapshot].
  FakeOsDomain({OsInfo? snapshot})
      : _snapshot = snapshot ?? OsInfo.allUnavailable();

  OsInfo _snapshot;

  /// Test-only mutator — not part of [OsDomain].
  void setSnapshot(OsInfo value) => _snapshot = value;

  @override
  Future<OsInfo> snapshot({bool forceRefresh = false}) async => _snapshot;
}
