import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:test/test.dart';

void main() {
  group('Reading<T> variant flags', () {
    test('ReadingValue sets isValue only', () {
      const reading = ReadingValue<int>(42);
      expect(reading.isValue, isTrue);
      expect(reading.isUnsupported, isFalse);
      expect(reading.isUnavailable, isFalse);
    });

    test('ReadingUnsupported sets isUnsupported only', () {
      const reading = ReadingUnsupported<int>(reason: 'not supported');
      expect(reading.isValue, isFalse);
      expect(reading.isUnsupported, isTrue);
      expect(reading.isUnavailable, isFalse);
    });

    test('ReadingUnavailable sets isUnavailable only', () {
      const reading = ReadingUnavailable<int>(reason: 'pending');
      expect(reading.isValue, isFalse);
      expect(reading.isUnsupported, isFalse);
      expect(reading.isUnavailable, isTrue);
    });
  });

  group('valueOrNull and orElse', () {
    test('ReadingValue returns value', () {
      const reading = ReadingValue<int>(42);
      expect(reading.valueOrNull, 42);
      expect(reading.orElse(0), 42);
    });

    test('ReadingValue with null payload is still a value variant', () {
      const reading = ReadingValue<int?>(null);
      expect(reading.isValue, isTrue);
      expect(reading.valueOrNull, isNull);
      // PRD §5.2: orElse uses `valueOrNull ?? fallback`, so a null payload
      // still falls back — distinguish via isValue, not orElse.
      expect(reading.orElse(99), 99);
    });

    test('ReadingUnsupported returns null and fallback', () {
      const reading = ReadingUnsupported<int>(reason: 'unsupported');
      expect(reading.valueOrNull, isNull);
      expect(reading.orElse(7), 7);
    });

    test('ReadingUnavailable returns null and fallback', () {
      const reading = ReadingUnavailable<int>(reason: 'unavailable');
      expect(reading.valueOrNull, isNull);
      expect(reading.orElse(7), 7);
    });
  });

  group('when', () {
    test('dispatches ReadingValue', () {
      const reading = ReadingValue<String>('ok');
      expect(
        reading.when(
          value: (v) => 'value:$v',
          unsupported: (_) => 'unsupported',
          unavailable: (_) => 'unavailable',
        ),
        'value:ok',
      );
    });

    test('dispatches ReadingUnsupported with reason', () {
      const reading = ReadingUnsupported<String>(reason: 'linux-only');
      expect(
        reading.when(
          value: (_) => 'value',
          unsupported: (r) => 'unsupported:$r',
          unavailable: (_) => 'unavailable',
        ),
        'unsupported:linux-only',
      );
    });

    test('dispatches ReadingUnsupported with null reason', () {
      const reading = ReadingUnsupported<String>();
      expect(
        reading.when(
          value: (_) => 'value',
          unsupported: (r) => 'unsupported:${r ?? 'none'}',
          unavailable: (_) => 'unavailable',
        ),
        'unsupported:none',
      );
    });

    test('dispatches ReadingUnavailable with reason', () {
      const reading = ReadingUnavailable<String>(reason: 'first sample');
      expect(
        reading.when(
          value: (_) => 'value',
          unsupported: (_) => 'unsupported',
          unavailable: (r) => 'unavailable:$r',
        ),
        'unavailable:first sample',
      );
    });

    test('dispatches ReadingUnavailable with null reason', () {
      const reading = ReadingUnavailable<String>();
      expect(
        reading.when(
          value: (_) => 'value',
          unsupported: (_) => 'unsupported',
          unavailable: (r) => 'unavailable:${r ?? 'none'}',
        ),
        'unavailable:none',
      );
    });
  });

  group('maybeWhen', () {
    const valueReading = ReadingValue<int>(10);
    const unsupportedReading = ReadingUnsupported<int>(reason: 'n/a');
    const unavailableReading = ReadingUnavailable<int>(reason: 'retry');

    test('value branch provided', () {
      expect(
        valueReading.maybeWhen(
          value: (v) => v * 2,
          orElse: () => -1,
        ),
        20,
      );
    });

    test('value branch omitted', () {
      expect(
        valueReading.maybeWhen(
          orElse: () => -1,
        ),
        -1,
      );
    });

    test('unsupported branch provided', () {
      expect(
        unsupportedReading.maybeWhen(
          unsupported: (r) => 'u:$r',
          orElse: () => 'else',
        ),
        'u:n/a',
      );
    });

    test('unsupported branch omitted', () {
      expect(
        unsupportedReading.maybeWhen(
          orElse: () => 'else',
        ),
        'else',
      );
    });

    test('unavailable branch provided', () {
      expect(
        unavailableReading.maybeWhen(
          unavailable: (r) => 'a:$r',
          orElse: () => 'else',
        ),
        'a:retry',
      );
    });

    test('unavailable branch omitted', () {
      expect(
        unavailableReading.maybeWhen(
          orElse: () => 'else',
        ),
        'else',
      );
    });

    test('all branches omitted uses orElse', () {
      expect(
        valueReading.maybeWhen(orElse: () => 'fallback'),
        'fallback',
      );
    });
  });

  group('sealed exhaustiveness', () {
    test('switch covers all three variants', () {
      String label(Reading<int> reading) => switch (reading) {
            ReadingValue<int>(:final value) => 'value:$value',
            ReadingUnsupported<int>(:final reason) => 'unsupported:$reason',
            ReadingUnavailable<int>(:final reason) => 'unavailable:$reason',
          };

      expect(label(const ReadingValue(1)), 'value:1');
      expect(
        label(const ReadingUnsupported(reason: 'x')),
        'unsupported:x',
      );
      expect(
        label(const ReadingUnavailable(reason: 'y')),
        'unavailable:y',
      );
    });
  });

  group('equality and hashCode', () {
    test('ReadingValue equal when payload equal', () {
      const a = ReadingValue<int>(42);
      const b = ReadingValue<int>(42);
      const c = ReadingValue<int>(7);

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('ReadingUnsupported equal when reason equal', () {
      const a = ReadingUnsupported<int>(reason: 'same');
      const b = ReadingUnsupported<int>(reason: 'same');
      const c = ReadingUnsupported<int>(reason: 'other');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('ReadingUnavailable equal when reason equal', () {
      const a = ReadingUnavailable<int>();
      const b = ReadingUnavailable<int>();
      const c = ReadingUnavailable<int>(reason: 'x');

      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('different variants are not equal', () {
      const value = ReadingValue<int>(1);
      const unsupported = ReadingUnsupported<int>();
      const unavailable = ReadingUnavailable<int>();

      expect(value, isNot(equals(unsupported)));
      expect(value, isNot(equals(unavailable)));
      expect(unsupported, isNot(equals(unavailable)));
    });
  });

  group('const construction', () {
    test('all variants are const-constructible', () {
      const value = ReadingValue<int>(1);
      const unsupported = ReadingUnsupported<int>(reason: 'r');
      const unavailable = ReadingUnavailable<int>(reason: 'r');

      expect(value, isA<ReadingValue<int>>());
      expect(unsupported, isA<ReadingUnsupported<int>>());
      expect(unavailable, isA<ReadingUnavailable<int>>());
    });
  });

  group('generic payload', () {
    test('preserves complex type through combinators', () {
      const reading = ReadingValue<List<int>>([1, 2, 3]);

      expect(reading.valueOrNull, [1, 2, 3]);
      expect(
        reading.when(
          value: (v) => v.length,
          unsupported: (_) => -1,
          unavailable: (_) => -2,
        ),
        3,
      );
    });
  });
}
