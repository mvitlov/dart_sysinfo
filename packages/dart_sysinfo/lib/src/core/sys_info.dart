/// SysInfo entrypoint, singleton lifecycle, and testability hooks (TDD §3.2).
library;

import 'dart:async' show unawaited;

import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart' as bridge;
import 'package:dart_sysinfo/src/core/abi_guard.dart';
import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain.dart';
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain_impl.dart';
import 'package:meta/meta.dart';

/// Public facade for OS, CPU, and memory domains.
abstract class SysInfo {
  /// CPU metrics namespace.
  CpuDomain get cpu;

  /// Memory metrics namespace.
  MemoryDomain get memory;

  /// OS metrics namespace.
  OsDomain get os;

  /// True if native state existed before this call created its binding.
  ///
  /// Consumed only by dart_sysinfo_flutter (PRD §9.2) — the core exposes the
  /// bit but never interprets it.
  bool get nativeStateWasPreExisting;

  /// Tears down native state held by this instance.
  Future<void> dispose();

  static SysInfo? _override;
  static _RealSysInfo? _real;

  /// Default entrypoint for application code.
  static SysInfo get instance =>
      _override ?? (_real ??= _RealSysInfo._create());

  /// Tears down the real singleton, if one was created.
  ///
  /// PRD §5.7 shows `SysInfo.dispose()`; Dart disallows a static and instance
  /// method with the same name, so the static entry point is [disposeInstance].
  static Future<void> disposeInstance() async {
    await _real?.dispose();
    _real = null;
  }

  /// Swaps the singleton returned by [instance] for the remainder of the test.
  @visibleForTesting
  static void overrideInstance(SysInfo fake) => _override = fake;

  /// Clears any override and disposes the real singleton.
  @visibleForTesting
  static void resetForTesting() {
    _override = null;
    unawaited(disposeInstance());
  }
}

class _RealSysInfo extends SysInfo {
  _RealSysInfo._(this._initResult)
      : cpu = CpuDomainImpl(),
        memory = const MemoryDomainImpl(),
        os = const OsDomainImpl();

  /// Production callers must call `initDartSysinfoBridge()` before the first
  /// [SysInfo.instance]; tests use `RustLib.initMock` instead.
  factory _RealSysInfo._create() {
    final result = bridge.init();
    AbiGuard.check(actual: result.abiVersion);
    return _RealSysInfo._(result);
  }

  final bridge.InitResult _initResult;

  @override
  final CpuDomainImpl cpu;

  @override
  final MemoryDomainImpl memory;

  @override
  final OsDomainImpl os;

  @override
  bool get nativeStateWasPreExisting => !_initResult.createdFresh;

  @override
  Future<void> dispose() async {
    await SharedStreamRegistry.instance.cancelAll();
    bridge.dispose();
  }
}
