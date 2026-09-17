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
  CpuInfoDto crateApiCpuCpuSnapshot() => const CpuInfoDto(architecture: 'mock');

  @override
  Stream<CpuLoadSampleDto> crateApiCpuCpuLoadStream({
    required BigInt intervalMs,
  }) =>
      const Stream.empty();
}
