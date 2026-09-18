/// Flutter lifecycle glue for `dart_sysinfo` (PRD §3.4, TDD §3.4/§9.2).
library;

import 'dart:async' show unawaited;

import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:flutter/widgets.dart';

/// Wires [SysInfo] teardown into Flutter hot-restart and app lifecycle.
class DartSysinfoFlutter {
  DartSysinfoFlutter._();

  static var _initialized = false;
  static _LifecycleBindingObserver? _observer;

  /// Callback invoked when the binding disposes native state on app detach.
  ///
  /// Test-only seam so widget tests can assert the dispose path without native
  /// code.
  @visibleForTesting
  static Future<void> Function()? onDetachedDisposeForTesting;

  /// Resets idempotent registration state between tests.
  @visibleForTesting
  static void resetForTesting() {
    final binding = WidgetsBinding.instance;
    if (_observer != null) {
      binding.removeObserver(_observer!);
    }
    _initialized = false;
    _observer = null;
    onDetachedDisposeForTesting = null;
  }

  /// Call once at app startup, after [initDartSysinfoBridge] and before the
  /// first [SysInfo.instance] access.
  static Future<void> ensureInitialized() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    SysInfo.prepareFreshIsolate();

    _observer = _LifecycleBindingObserver();
    WidgetsBinding.instance.addObserver(_observer!);
  }
}

class _LifecycleBindingObserver with WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      final testHook = DartSysinfoFlutter.onDetachedDisposeForTesting;
      if (testHook != null) {
        unawaited(testHook());
        return;
      }
      unawaited(SysInfo.disposeInstance());
    }
  }
}
