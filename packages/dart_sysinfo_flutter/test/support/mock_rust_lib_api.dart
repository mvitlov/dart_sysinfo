import 'dart:async';

import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/bridge/api/disks.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/bridge/api/memory.dart';
import 'package:dart_sysinfo/src/bridge/api/os.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';

/// Test double for [RustLibApi] lifecycle calls without a native library.
class MockRustLibApi implements RustLibApi {
  MockRustLibApi({
    this.initResult = const InitResult(
      createdFresh: true,
      abiVersion: AbiGuard.expectedAbi,
    ),
  });

  InitResult initResult;
  int initCalls = 0;
  int disposeCalls = 0;

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
  CpuInfoDto crateApiCpuCpuSnapshot() =>
      const CpuInfoDto(architecture: 'mock');

  @override
  Stream<CpuLoadSampleDto> crateApiCpuCpuLoadStream({
    required BigInt intervalMs,
  }) =>
      const Stream<CpuLoadSampleDto>.empty();

  @override
  MemoryInfoDto crateApiMemoryMemorySnapshot() => MemoryInfoDto(
        totalMemoryBytes: BigInt.zero,
        freeMemoryBytes: BigInt.zero,
        availableMemoryBytes: BigInt.zero,
        usedMemoryBytes: BigInt.zero,
        totalSwapBytes: BigInt.zero,
        freeSwapBytes: BigInt.zero,
        usedSwapBytes: BigInt.zero,
        cgroupLimits: const CGroupLimitsReadingDto(supported: false),
      );

  @override
  OsInfoDto crateApiOsOsSnapshot() => OsInfoDto(
        distributionId: 'mock',
        distributionIdLike: const [],
        kernelLongVersion: 'mock kernel',
        uptimeSeconds: BigInt.zero,
        bootTimeSeconds: BigInt.zero,
        loadAverage: const LoadAverageReadingDto(supported: false),
      );

  @override
  DisksInfoDto crateApiDisksDisksSnapshot() => const DisksInfoDto(volumes: []);
}
