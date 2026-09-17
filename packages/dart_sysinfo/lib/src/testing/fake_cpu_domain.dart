/// Fake CPU domain for unit tests (TDD §5.1).
library;

import 'dart:async';

import 'package:dart_sysinfo/src/domains/cpu/cpu_domain.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_info.dart';

/// Configurable [CpuDomain] with no native calls.
class FakeCpuDomain implements CpuDomain {
  /// Creates a fake CPU domain with an optional canned [snapshot].
  FakeCpuDomain({CpuInfo? snapshot})
      : _snapshot = snapshot ?? CpuInfo.allUnavailable();

  CpuInfo _snapshot;
  final _loadController = StreamController<CpuLoadSample>.broadcast();

  /// Test-only mutator — not part of [CpuDomain].
  void setSnapshot(CpuInfo value) => _snapshot = value;

  /// Test-only injector for stream-based assertions.
  void emitLoad(CpuLoadSample sample) => _loadController.add(sample);

  @override
  Future<CpuInfo> snapshot({bool forceRefresh = false}) async => _snapshot;

  @override
  Stream<CpuLoadSample> load({
    Duration interval = const Duration(seconds: 1),
  }) =>
      _loadController.stream;
}
