import 'dart:async';

import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/bridge/api/memory.dart';
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
    MemoryInfoDto? memorySnapshotResult,
    StreamController<CpuLoadSampleDto>? cpuLoadStreamController,
  })  : cpuSnapshotResult =
            cpuSnapshotResult ?? const CpuInfoDto(architecture: 'mock'),
        memorySnapshotResult = memorySnapshotResult ??
            MemoryInfoDto(
              totalMemoryBytes: BigInt.from(16 * 1024 * 1024 * 1024),
              freeMemoryBytes: BigInt.from(8 * 1024 * 1024 * 1024),
              availableMemoryBytes: BigInt.from(8 * 1024 * 1024 * 1024),
              usedMemoryBytes: BigInt.from(8 * 1024 * 1024 * 1024),
              totalSwapBytes: BigInt.zero,
              freeSwapBytes: BigInt.zero,
              usedSwapBytes: BigInt.zero,
              cgroupLimits: const CGroupLimitsReadingDto(supported: false),
            ),
        cpuLoadStreamController = cpuLoadStreamController ??
            StreamController<CpuLoadSampleDto>.broadcast();

  InitResult initResult;
  int initCalls = 0;
  int disposeCalls = 0;

  CpuInfoDto cpuSnapshotResult;
  int cpuSnapshotCalls = 0;

  MemoryInfoDto memorySnapshotResult;
  int memorySnapshotCalls = 0;

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

  @override
  MemoryInfoDto crateApiMemoryMemorySnapshot() {
    memorySnapshotCalls++;
    return memorySnapshotResult;
  }
}
