import 'dart:async';

import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';

/// Test double for [RustLibApi] lifecycle calls without a native library.
class MockRustLibApi implements RustLibApi {
  MockRustLibApi({
    this.initResult = const InitResult(
      createdFresh: true,
      abiVersion: AbiGuard.expectedAbi,
    ),
    CpuInfoDto? cpuSnapshotResult,
    StreamController<CpuLoadSampleDto>? cpuLoadStreamController,
  })  : cpuSnapshotResult =
            cpuSnapshotResult ?? const CpuInfoDto(architecture: 'mock'),
        cpuLoadStreamController = cpuLoadStreamController ??
            StreamController<CpuLoadSampleDto>.broadcast();

  InitResult initResult;
  int initCalls = 0;
  int disposeCalls = 0;

  CpuInfoDto cpuSnapshotResult;
  int cpuSnapshotCalls = 0;

  final StreamController<CpuLoadSampleDto> cpuLoadStreamController;
  int cpuLoadStreamCalls = 0;
  BigInt? lastLoadIntervalMs;

  @override
  InitResult crateApiLifecycleInit() {
    initCalls++;
    return initResult;
  }

  @override
  void crateApiLifecycleDispose() {
    disposeCalls++;
  }

  @override
  int crateApiSmokeFrbPlatformSmokePing() => 42;

  @override
  String crateApiAbiNativeCrateVersion() => '0.1.0';

  @override
  CpuInfoDto crateApiCpuCpuSnapshot() {
    cpuSnapshotCalls++;
    return cpuSnapshotResult;
  }

  @override
  Stream<CpuLoadSampleDto> crateApiCpuCpuLoadStream({
    required BigInt intervalMs,
  }) {
    cpuLoadStreamCalls++;
    lastLoadIntervalMs = intervalMs;
    return cpuLoadStreamController.stream;
  }
}
