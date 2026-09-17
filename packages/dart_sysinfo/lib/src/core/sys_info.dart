/// SysInfo entrypoint, singleton lifecycle, and testability hooks (TDD §3.2).
library;

import 'dart:async' show unawaited;

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
  _RealSysInfo._({required bool createdFresh})
      : _createdFresh = createdFresh,
        cpu = const CpuDomainImpl(),
        memory = const MemoryDomainImpl(),
        os = const OsDomainImpl();

  factory _RealSysInfo._create() => _RealSysInfo._(
        createdFresh: true,
      ); // M1-04 replaces with bridge init + InitResult

  final bool _createdFresh;

  @override
  final CpuDomainImpl cpu;

  @override
  final MemoryDomainImpl memory;

  @override
  final OsDomainImpl os;

  @override
  bool get nativeStateWasPreExisting => !_createdFresh;

  @override
  Future<void> dispose() async {
    // M1-10: await SharedStreamRegistry.instance.cancelAll();
    // M1-04: bridge.dispose();
  }
}
