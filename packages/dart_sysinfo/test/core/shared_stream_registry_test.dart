import 'dart:async';

import 'package:dart_sysinfo/src/core/shared_stream_registry.dart';
import 'package:test/test.dart';

void main() {
  group('SharedStreamRegistry', () {
    late SharedStreamRegistry registry;

    setUp(() async {
      registry = SharedStreamRegistry.instance;
      await registry.cancelAll();
    });

    tearDown(() async {
      await registry.cancelAll();
    });

    test('clamps_requested_interval_to_minimum', () {
      Duration? received;

      registry.get<int>(
        domainKey: 'cpu.load',
        requested: const Duration(milliseconds: 10),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (clamped) {
          received = clamped;
          return const Stream.empty();
        },
      );

      expect(received, const Duration(milliseconds: 50));
    });

    test('reuses_entry_for_same_domain_and_interval', () {
      var createCalls = 0;

      registry.get<int>(
        domainKey: 'cpu.load',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (clamped) {
          createCalls++;
          return Stream.value(1);
        },
      );
      registry.get<int>(
        domainKey: 'cpu.load',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (clamped) {
          createCalls++;
          return Stream.value(2);
        },
      );

      expect(createCalls, 1);
    });

    test('broadcasts_to_multiple_listeners', () async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      final stream = registry.get<int>(
        domainKey: 'cpu.load',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (_) => controller.stream,
      );

      final firstValues = <int>[];
      final secondValues = <int>[];
      final firstSub = stream.listen(firstValues.add);
      final secondSub = stream.listen(secondValues.add);

      controller.add(42);
      await Future<void>.delayed(Duration.zero);

      await firstSub.cancel();
      await secondSub.cancel();

      expect(firstValues, [42]);
      expect(secondValues, [42]);
    });

    test('cancelAll_closes_active_streams', () async {
      final controller = StreamController<int>();
      addTearDown(controller.close);

      final stream = registry.get<int>(
        domainKey: 'cpu.load',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (_) => controller.stream,
      );

      final sub = stream.listen((_) {});
      await registry.cancelAll();
      await sub.cancel();

      expect(sub.isPaused, isFalse);
    });

    test('clamp_logs_once_per_domain', () {
      final logs = <String>[];

      runZoned(
        () {
          registry.get<int>(
            domainKey: 'test.clamp-once-a',
            requested: const Duration(milliseconds: 10),
            minInterval: const Duration(milliseconds: 50),
            createRawStream: (_) => const Stream.empty(),
          );
          registry.get<int>(
            domainKey: 'test.clamp-once-a',
            requested: const Duration(milliseconds: 10),
            minInterval: const Duration(milliseconds: 50),
            createRawStream: (_) => const Stream.empty(),
          );
          registry.get<int>(
            domainKey: 'test.clamp-once-b',
            requested: const Duration(milliseconds: 10),
            minInterval: const Duration(milliseconds: 50),
            createRawStream: (_) => const Stream.empty(),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => logs.add(line),
        ),
      );

      final clampLogs = logs
          .where((line) => line.contains('clamped to'))
          .toList(growable: false);
      expect(clampLogs, hasLength(2));
      expect(clampLogs[0], contains('test.clamp-once-a'));
      expect(clampLogs[1], contains('test.clamp-once-b'));
    });

    test('evicts_entry_when_last_listener_cancels', () async {
      var createCalls = 0;

      Stream<int> createRawStream(Duration _) {
        createCalls++;
        return StreamController<int>().stream;
      }

      final stream = registry.get<int>(
        domainKey: 'test.evict',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: createRawStream,
      );

      final sub = stream.listen((_) {});
      await sub.cancel();
      await Future<void>.delayed(Duration.zero);

      registry.get<int>(
        domainKey: 'test.evict',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: createRawStream,
      );

      expect(createCalls, 2);
    });

    test('creates_separate_entries_for_different_intervals', () {
      var createCalls = 0;

      registry.get<int>(
        domainKey: 'test.intervals',
        requested: const Duration(milliseconds: 100),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (_) {
          createCalls++;
          return const Stream.empty();
        },
      );
      registry.get<int>(
        domainKey: 'test.intervals',
        requested: const Duration(milliseconds: 200),
        minInterval: const Duration(milliseconds: 50),
        createRawStream: (_) {
          createCalls++;
          return const Stream.empty();
        },
      );

      expect(createCalls, 2);
    });
  });
}
