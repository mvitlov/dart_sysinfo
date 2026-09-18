import 'dart:async';

// GENERATOR:BEGIN mock-imports
import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/bridge/api/memory.dart';
import 'package:dart_sysinfo/src/bridge/api/os.dart';
// GENERATOR:END mock-imports
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';

/// Test double for [RustLibApi] lifecycle calls without a native library.
class MockRustLibApi implements RustLibApi {
  MockRustLibApi({
    this.initResult = const InitResult(
      createdFresh: true,
      abiVersion: AbiGuard.expectedAbi,
    ),
    // GENERATOR:BEGIN mock-ctor-params
    CpuInfoDto? cpuSnapshotResult,
    MemoryInfoDto? memorySnapshotResult,
    OsInfoDto? osSnapshotResult,
    // GENERATOR:END mock-ctor-params
    // GENERATOR:BEGIN mock-stream-ctor-params
    StreamController<CpuLoadSampleDto>? cpuLoadStreamController,
    // GENERATOR:END mock-stream-ctor-params
  })  // GENERATOR:BEGIN mock-ctor-init
      : cpuSnapshotResult =
            cpuSnapshotResult ?? const CpuInfoDto(architecture: 'mock'),
        memorySnapshotResult =
            memorySnapshotResult ??
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
        osSnapshotResult =
            osSnapshotResult ??
            OsInfoDto(
              distributionId: 'mock',
              distributionIdLike: const [],
              kernelLongVersion: 'mock kernel',
              uptimeSeconds: BigInt.zero,
              bootTimeSeconds: BigInt.zero,
              loadAverage: const LoadAverageReadingDto(supported: false),
            ),
      // GENERATOR:END mock-ctor-init
      // GENERATOR:BEGIN mock-stream-ctor-init
      ,
        cpuLoadStreamController = cpuLoadStreamController ??
            StreamController<CpuLoadSampleDto>.broadcast()
      // GENERATOR:END mock-stream-ctor-init
      ;

  InitResult initResult;
  int initCalls = 0;
  int disposeCalls = 0;

  // GENERATOR:BEGIN mock-fields
  CpuInfoDto cpuSnapshotResult;
  int cpuSnapshotCalls = 0;

  MemoryInfoDto memorySnapshotResult;
  int memorySnapshotCalls = 0;

  OsInfoDto osSnapshotResult;
  int osSnapshotCalls = 0;
  // GENERATOR:END mock-fields

  // GENERATOR:BEGIN mock-stream-fields
  final StreamController<CpuLoadSampleDto> cpuLoadStreamController;
  int cpuLoadStreamCalls = 0;
  BigInt? lastLoadIntervalMs;
  // GENERATOR:END mock-stream-fields

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

  // GENERATOR:BEGIN mock-methods
  @override
  CpuInfoDto crateApiCpuCpuSnapshot() {
    cpuSnapshotCalls++;
    return cpuSnapshotResult;
  }

  @override
  MemoryInfoDto crateApiMemoryMemorySnapshot() {
    memorySnapshotCalls++;
    return memorySnapshotResult;
  }

  @override
  OsInfoDto crateApiOsOsSnapshot() {
    osSnapshotCalls++;
    return osSnapshotResult;
  }
  // GENERATOR:END mock-methods

  // GENERATOR:BEGIN mock-stream-methods
  @override
  Stream<CpuLoadSampleDto> crateApiCpuCpuLoadStream({
    required BigInt intervalMs,
  }) {
    cpuLoadStreamCalls++;
    lastLoadIntervalMs = intervalMs;
    return cpuLoadStreamController.stream;
  }
  // GENERATOR:END mock-stream-methods
}
