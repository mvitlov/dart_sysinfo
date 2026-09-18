import 'dart:async';

// GENERATOR:BEGIN mock-imports
import 'package:dart_sysinfo/src/bridge/api/cpu.dart';
import 'package:dart_sysinfo/src/bridge/api/disks.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/bridge/api/memory.dart';
import 'package:dart_sysinfo/src/bridge/api/network.dart';
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
    DisksInfoDto? disksSnapshotResult,
    MemoryInfoDto? memorySnapshotResult,
    NetworkInfoDto? networkSnapshotResult,
    OsInfoDto? osSnapshotResult,
    // GENERATOR:END mock-ctor-params
    // GENERATOR:BEGIN mock-stream-ctor-params
    StreamController<CpuLoadSampleDto>? cpuLoadStreamController,
    StreamController<NetworkThroughputSampleDto>?
        networkThroughputStreamController,
    // GENERATOR:END mock-stream-ctor-params
  })  // GENERATOR:BEGIN mock-ctor-init
      : cpuSnapshotResult =
            cpuSnapshotResult ?? const CpuInfoDto(architecture: 'mock'),
        disksSnapshotResult =
            disksSnapshotResult ??
            DisksInfoDto(
              volumes: [
                DiskVolumeDto(
                  name: 'mock',
                  kind: DiskKindDto.ssd,
                  fileSystem: 'APFS',
                  mountPoint: '/',
                  totalSpaceBytes: BigInt.from(512 * 1024 * 1024 * 1024),
                  availableSpaceBytes: BigInt.from(256 * 1024 * 1024 * 1024),
                  isRemovable: false,
                  isReadOnly: false,
                  ioUsage: DiskIoUsageDto(
                    readBytes: BigInt.zero,
                    writtenBytes: BigInt.zero,
                    totalReadBytes: BigInt.zero,
                    totalWrittenBytes: BigInt.zero,
                  ),
                ),
              ],
            ),
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
        networkSnapshotResult =
            networkSnapshotResult ??
            NetworkInfoDto(
              interfaces: [
                NetworkInterfaceDto(
                  name: 'mock0',
                  macAddress: '00:11:22:33:44:55',
                  ipNetworks: const [
                    IpNetworkEntryDto(address: '192.168.1.10', prefixLength: 24),
                  ],
                  mtu: BigInt.from(1500),
                  operationalState: NetworkOperationalStateDto.up,
                  cumulative: NetworkCumulativeStatsDto(
                    totalReceivedBytes: BigInt.from(1024),
                    totalTransmittedBytes: BigInt.from(2048),
                    totalPacketsReceived: BigInt.from(10),
                    totalPacketsTransmitted: BigInt.from(20),
                    totalErrorsOnReceived: BigInt.zero,
                    totalErrorsOnTransmitted: BigInt.zero,
                  ),
                ),
              ],
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
        cpuLoadStreamController = cpuLoadStreamController ??
            StreamController<CpuLoadSampleDto>.broadcast(),
        networkThroughputStreamController = networkThroughputStreamController ??
            StreamController<NetworkThroughputSampleDto>.broadcast();
  // GENERATOR:END mock-ctor-init

  InitResult initResult;
  int initCalls = 0;
  int disposeCalls = 0;

  // GENERATOR:BEGIN mock-fields
  CpuInfoDto cpuSnapshotResult;
  DisksInfoDto disksSnapshotResult;
  int disksSnapshotCalls = 0;
  MemoryInfoDto memorySnapshotResult;
  NetworkInfoDto networkSnapshotResult;
  int networkSnapshotCalls = 0;
  OsInfoDto osSnapshotResult;
  int cpuSnapshotCalls = 0;
  int memorySnapshotCalls = 0;
  int osSnapshotCalls = 0;
  // GENERATOR:END mock-fields

  // GENERATOR:BEGIN mock-stream-fields
  final StreamController<CpuLoadSampleDto> cpuLoadStreamController;
  int cpuLoadStreamCalls = 0;
  BigInt? lastLoadIntervalMs;

  final StreamController<NetworkThroughputSampleDto>
      networkThroughputStreamController;
  int networkThroughputStreamCalls = 0;
  BigInt? lastThroughputIntervalMs;
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

  @override
  DisksInfoDto crateApiDisksDisksSnapshot() {
    disksSnapshotCalls++;
    return disksSnapshotResult;
  }

  @override
  NetworkInfoDto crateApiNetworkNetworkSnapshot() {
    networkSnapshotCalls++;
    return networkSnapshotResult;
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

  @override
  Stream<NetworkThroughputSampleDto> crateApiNetworkNetworkThroughputStream({
    required BigInt intervalMs,
  }) {
    networkThroughputStreamCalls++;
    lastThroughputIntervalMs = intervalMs;
    return networkThroughputStreamController.stream;
  }
  // GENERATOR:END mock-stream-methods
}
