/// SysInfo entrypoint, singleton lifecycle, and testability hooks (TDD §3.2).
library;

import 'dart:async' show unawaited;

import 'package:dart_sysinfo/src/bridge/api/lifecycle.dart' as bridge;
import 'package:dart_sysinfo/src/core/abi_guard.dart';
import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
// GENERATOR:BEGIN domain-imports
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_domain.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain.dart';
// GENERATOR:END domain-imports
// GENERATOR:BEGIN domain-impl-imports
import 'package:dart_sysinfo/src/domains/cpu/cpu_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/disks/disks_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/memory/memory_domain_impl.dart';
import 'package:dart_sysinfo/src/domains/os/os_domain_impl.dart';
// GENERATOR:END domain-impl-imports
import 'package:meta/meta.dart';

/// Public facade for OS, CPU, memory, and disks domains.
abstract class SysInfo {
  // GENERATOR:BEGIN domain-getters
  /// CPU metrics namespace.
  CpuDomain get cpu;

  /// Disks metrics namespace.
  DisksDomain get disks;

  /// Memory metrics namespace.
  MemoryDomain get memory;

  /// OS metrics namespace.
  OsDomain get os;
// GENERATOR:END domain-getters

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

  /// Clears native singleton state that can survive a Dart isolate reset
  /// (Flutter hot restart). Safe no-op on cold start.
  ///
  /// Called by `dart_sysinfo_flutter` before the first [instance] access in a
  /// new isolate so stale stream workers from a prior isolate are torn down.
  static void prepareFreshIsolate() {
    bridge.dispose();
  }

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
      // GENERATOR:BEGIN domain-impl-init
      : cpu = CpuDomainImpl(),
        disks = DisksDomainImpl(),
        memory = MemoryDomainImpl(),
        os = OsDomainImpl();
// GENERATOR:END domain-impl-init

  /// Production callers must call `initDartSysinfoBridge()` before the first
  /// [SysInfo.instance]; tests use `RustLib.initMock` instead.
  factory _RealSysInfo._create() {
    final result = bridge.init();
    AbiGuard.check(actual: result.abiVersion);
    return _RealSysInfo._(result);
  }

  final bridge.InitResult _initResult;

  // GENERATOR:BEGIN domain-impl-fields
  @override
  final CpuDomainImpl cpu;

  @override
  final DisksDomainImpl disks;

  @override
  final MemoryDomainImpl memory;

  @override
  final OsDomainImpl os;
// GENERATOR:END domain-impl-fields

  @override
  bool get nativeStateWasPreExisting => !_initResult.createdFresh;

  @override
  Future<void> dispose() async {
    await SharedStreamRegistry.instance.cancelAll();
    bridge.dispose();
  }
}
