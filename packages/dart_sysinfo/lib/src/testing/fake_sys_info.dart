/// Fake [SysInfo] for unit tests (TDD §5.1).
library;

import 'package:dart_sysinfo/src/core/sys_info.dart';
// GENERATOR:BEGIN fake-imports
import 'package:dart_sysinfo/src/testing/fake_cpu_domain.dart';
import 'package:dart_sysinfo/src/testing/fake_disks_domain.dart';
import 'package:dart_sysinfo/src/testing/fake_memory_domain.dart';
import 'package:dart_sysinfo/src/testing/fake_network_domain.dart';
import 'package:dart_sysinfo/src/testing/fake_os_domain.dart';
// GENERATOR:END fake-imports

/// Configurable [SysInfo] with no native calls.
class FakeSysInfo extends SysInfo {
  /// Creates a fake [SysInfo] with optional per-domain fakes.
  FakeSysInfo({
    // GENERATOR:BEGIN fake-ctor-params
    FakeCpuDomain? cpu,
    FakeDisksDomain? disks,
    FakeMemoryDomain? memory,
    FakeNetworkDomain? network,
    FakeOsDomain? os,
// GENERATOR:END fake-ctor-params
  })  // GENERATOR:BEGIN fake-ctor-init
      : cpu = cpu ?? FakeCpuDomain(),
        disks = disks ?? FakeDisksDomain(),
        memory = memory ?? FakeMemoryDomain(),
        network = network ?? FakeNetworkDomain(),
        os = os ?? FakeOsDomain();
// GENERATOR:END fake-ctor-init

  // GENERATOR:BEGIN fake-fields
  @override
  final FakeCpuDomain cpu;

  @override
  final FakeDisksDomain disks;

  @override
  final FakeMemoryDomain memory;

  @override
  final FakeNetworkDomain network;

  @override
  final FakeOsDomain os;
// GENERATOR:END fake-fields

  @override
  bool get nativeStateWasPreExisting => false;

  @override
  Future<void> dispose() async {}
}
