/// Broadcast stream sharing, interval clamp, and ref-count (TDD §3.3).
library;

import 'dart:async';

import 'package:dart_sysinfo/src/core/debug_log.dart';

/// Shares one underlying native poller per domain key and clamped interval.
class SharedStreamRegistry {
  SharedStreamRegistry._();

  /// Process-wide registry for shared domain streams.
  static final instance = SharedStreamRegistry._();

  final _entries = <String, _Entry<Object?>>{};
  final _loggedClamps = <String>{};

  /// Returns a broadcast stream, reusing an existing poller when possible.
  Stream<T> get<T>({
    required String domainKey,
    required Duration requested,
    required Duration minInterval,
    required Stream<T> Function(Duration clamped) createRawStream,
  }) {
    final clamped = requested < minInterval ? minInterval : requested;
    if (requested < minInterval && _loggedClamps.add(domainKey)) {
      debugLog('$domainKey: requested $requested clamped to $minInterval');
    }
    final key = '$domainKey@${clamped.inMicroseconds}';
    final entry = _entries.putIfAbsent(
      key,
      () => _Entry<T>(
        createRawStream(clamped),
        () => _entries.remove(key),
      ),
    );
    return (entry as _Entry<T>).controller.stream;
  }

  /// Tears down all active shared streams.
  Future<void> cancelAll() async {
    for (final entry in _entries.values.toList()) {
      await entry.controller.close();
    }
    _entries.clear();
  }
}

class _Entry<T> {
  _Entry(Stream<T> source, void Function() onFullyIdle) {
    controller = StreamController<T>.broadcast(onCancel: () {
      if (!controller.hasListener) {
        unawaited(_sub.cancel());
        onFullyIdle();
      }
    });
    _sub = source.listen(controller.add, onError: controller.addError);
  }

  late final StreamController<T> controller;
  late final StreamSubscription<T> _sub;
}
