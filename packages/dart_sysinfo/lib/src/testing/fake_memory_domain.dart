/// Fake memory domain for unit tests (TDD §5.1).
library;

import 'package:dart_sysinfo/src/domains/memory/memory_domain.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_info.dart';

/// Configurable [MemoryDomain] with no native calls.
class FakeMemoryDomain implements MemoryDomain {
  /// Creates a fake memory domain with an optional canned [snapshot].
  FakeMemoryDomain({MemoryInfo? snapshot})
      : _snapshot = snapshot ?? MemoryInfo.allUnavailable();

  MemoryInfo _snapshot;

  /// Test-only mutator — not part of [MemoryDomain].
  void setSnapshot(MemoryInfo value) => _snapshot = value;

  @override
  Future<MemoryInfo> snapshot({bool forceRefresh = false}) async => _snapshot;
}
