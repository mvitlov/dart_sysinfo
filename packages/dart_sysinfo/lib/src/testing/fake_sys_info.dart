/// Fake [SysInfo] for unit tests (TDD §5.1).
library;

import 'package:dart_sysinfo/src/core/sys_info.dart';
import 'package:dart_sysinfo/src/testing/fake_cpu_domain.dart';
import 'package:dart_sysinfo/src/testing/fake_memory_domain.dart';
import 'package:dart_sysinfo/src/testing/fake_os_domain.dart';

/// Configurable [SysInfo] with no native calls.
class FakeSysInfo extends SysInfo {
  /// Creates a fake [SysInfo] with optional per-domain fakes.
  FakeSysInfo({
    FakeCpuDomain? cpu,
    FakeMemoryDomain? memory,
    FakeOsDomain? os,
  })  : cpu = cpu ?? FakeCpuDomain(),
        memory = memory ?? FakeMemoryDomain(),
        os = os ?? FakeOsDomain();

  @override
  final FakeCpuDomain cpu;

  @override
  final FakeMemoryDomain memory;

  @override
  final FakeOsDomain os;

  @override
  bool get nativeStateWasPreExisting => false;

  @override
  Future<void> dispose() async {}
}
