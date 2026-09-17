import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart';
import 'package:dart_sysinfo/src/bridge/frb_generated.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_info.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_info.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain.dart';
import 'package:dart_sysinfo/src/domains/os/os_info.dart';
import '../support/mock_rust_lib_api.dart';
import 'package:test/test.dart';

late MockRustLibApi mockRustLibApi;

void main() {
  setUpAll(() {
    mockRustLibApi = MockRustLibApi();
    RustLib.initMock(api: mockRustLibApi);
  });

  setUp(() {
    mockRustLibApi
      ..initCalls = 0
      ..disposeCalls = 0
      ..initResult = const InitResult(
        createdFresh: true,
        abiVersion: AbiGuard.expectedAbi,
      );
  });

  tearDown(() async {
    SysInfo.resetForTesting();
    await SysInfo.disposeInstance();
  });

  group('SysInfo.instance', () {
    test('returns the same real singleton without override', () {
      final first = SysInfo.instance;
      final second = SysInfo.instance;

      expect(identical(first, second), isTrue);
      expect(first, isA<SysInfo>());
    });
  });

  group('overrideInstance', () {
    test('returns the injected fake from instance', () {
      final fake = _TestSysInfo();
      SysInfo.overrideInstance(fake);

      expect(identical(SysInfo.instance, fake), isTrue);
    });

    test('exposes fake domain getters', () {
      final fake = _TestSysInfo();
      SysInfo.overrideInstance(fake);

      expect(identical(SysInfo.instance.cpu, fake.cpu), isTrue);
      expect(identical(SysInfo.instance.memory, fake.memory), isTrue);
      expect(identical(SysInfo.instance.os, fake.os), isTrue);
    });
  });

  group('resetForTesting', () {
    test('clears override so instance returns real singleton again', () async {
      SysInfo.overrideInstance(_TestSysInfo());
      SysInfo.resetForTesting();
      await SysInfo.disposeInstance();

      final real = SysInfo.instance;
      expect(real, isA<SysInfo>());
      expect(real, isNot(isA<_TestSysInfo>()));
    });

    test('does not call dispose on the active fake override', () async {
      final fake = _TestSysInfo();
      SysInfo.overrideInstance(fake);

      SysInfo.resetForTesting();
      await SysInfo.disposeInstance();

      expect(fake.disposeCalls, 0);
    });
  });

  group('disposeInstance', () {
    test('creates a new real singleton on next access', () async {
      final before = SysInfo.instance;
      await SysInfo.disposeInstance();
      final after = SysInfo.instance;

      expect(identical(before, after), isFalse);
    });

    test('calls native dispose through the mock bridge', () async {
      SysInfo.instance;
      await SysInfo.disposeInstance();

      expect(mockRustLibApi.disposeCalls, 1);
    });
  });

  group('nativeStateWasPreExisting', () {
    test('is false when init reports createdFresh', () {
      expect(SysInfo.instance.nativeStateWasPreExisting, isFalse);
    });

    test('is true when init reports reused native state', () {
      mockRustLibApi.initResult = const InitResult(
        createdFresh: false,
        abiVersion: AbiGuard.expectedAbi,
      );

      expect(SysInfo.instance.nativeStateWasPreExisting, isTrue);
    });

    test('is false for test fakes', () {
      final fake = _TestSysInfo();
      SysInfo.overrideInstance(fake);

      expect(SysInfo.instance.nativeStateWasPreExisting, isFalse);
    });
  });
}

class _TestSysInfo extends SysInfo {
  _TestSysInfo()
      : cpu = _TestCpuDomain(),
        memory = _TestMemoryDomain(),
        os = _TestOsDomain();

  int disposeCalls = 0;

  @override
  final _TestCpuDomain cpu;

  @override
  final _TestMemoryDomain memory;

  @override
  final _TestOsDomain os;

  @override
  bool get nativeStateWasPreExisting => false;

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }
}

class _TestCpuDomain implements CpuDomain {
  @override
  Future<CpuInfo> snapshot({bool forceRefresh = false}) async =>
      const CpuInfo();

  @override
  Stream<CpuLoadSample> load({
    Duration interval = const Duration(seconds: 1),
  }) =>
      const Stream.empty();
}

class _TestMemoryDomain implements MemoryDomain {
  @override
  Future<MemoryInfo> snapshot({bool forceRefresh = false}) async =>
      const MemoryInfo();
}

class _TestOsDomain implements OsDomain {
  @override
  Future<OsInfo> snapshot({bool forceRefresh = false}) async => const OsInfo();
}
