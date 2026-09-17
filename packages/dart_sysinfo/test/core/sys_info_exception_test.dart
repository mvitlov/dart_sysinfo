import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:test/test.dart';

void main() {
  group('SysInfoException construction', () {
    test('SysInfoLoadException is const-constructible', () {
      const exception = SysInfoLoadException('failed to load');
      expect(exception.message, 'failed to load');
    });

    test('SysInfoAbiMismatchException is const-constructible', () {
      const exception = SysInfoAbiMismatchException(
        'ABI mismatch',
        expectedAbi: 1,
        actualAbi: 2,
      );
      expect(exception.message, 'ABI mismatch');
      expect(exception.expectedAbi, 1);
      expect(exception.actualAbi, 2);
    });

    test('SysInfoDisposedException is const-constructible', () {
      const exception = SysInfoDisposedException('already disposed');
      expect(exception.message, 'already disposed');
    });

    test('SysInfoUnsupportedPlatformException is const-constructible', () {
      const exception = SysInfoUnsupportedPlatformException('unsupported');
      expect(exception.message, 'unsupported');
    });
  });

  group('implements Exception', () {
    test('all subtypes implement Exception and SysInfoException', () {
      const exceptions = <SysInfoException>[
        SysInfoLoadException('load'),
        SysInfoAbiMismatchException(
          'abi',
          expectedAbi: 1,
          actualAbi: 2,
        ),
        SysInfoDisposedException('disposed'),
        SysInfoUnsupportedPlatformException('platform'),
      ];

      for (final exception in exceptions) {
        expect(exception, isA<Exception>());
        expect(exception, isA<SysInfoException>());
      }
    });
  });

  group('toString', () {
    test('matches PRD runtimeType: message format', () {
      const load = SysInfoLoadException('failed to load');
      const abi = SysInfoAbiMismatchException(
        'upgrade required',
        expectedAbi: 1,
        actualAbi: 3,
      );
      const disposed = SysInfoDisposedException('disposed');
      const platform = SysInfoUnsupportedPlatformException('web');

      expect(load.toString(), '${load.runtimeType}: failed to load');
      expect(abi.toString(), '${abi.runtimeType}: upgrade required');
      expect(disposed.toString(), '${disposed.runtimeType}: disposed');
      expect(platform.toString(), '${platform.runtimeType}: web');
    });
  });

  group('SysInfoAbiMismatchException fields', () {
    test('preserves expectedAbi and actualAbi independently of message', () {
      const exception = SysInfoAbiMismatchException(
        'rebuild native library',
        expectedAbi: 7,
        actualAbi: 9,
      );

      expect(exception.message, 'rebuild native library');
      expect(exception.expectedAbi, 7);
      expect(exception.actualAbi, 9);
    });
  });

  group('subtype catch', () {
    test('on SysInfoAbiMismatchException exposes ABI fields', () {
      expect(
        () => throw const SysInfoAbiMismatchException(
          'mismatch',
          expectedAbi: 1,
          actualAbi: 4,
        ),
        throwsA(
          isA<SysInfoAbiMismatchException>()
              .having((e) => e.message, 'message', 'mismatch')
              .having((e) => e.expectedAbi, 'expectedAbi', 1)
              .having((e) => e.actualAbi, 'actualAbi', 4),
        ),
      );
    });
  });

  group('sealed exhaustiveness', () {
    test('switch covers all four subtypes', () {
      String label(SysInfoException exception) => switch (exception) {
            SysInfoLoadException(:final message) => 'load:$message',
            SysInfoAbiMismatchException(
              :final message,
              expectedAbi: final expected,
              actualAbi: final actual,
            ) =>
              'abi:$message:$expected:$actual',
            SysInfoDisposedException(:final message) => 'disposed:$message',
            SysInfoUnsupportedPlatformException(:final message) =>
              'platform:$message',
          };

      expect(
        label(const SysInfoLoadException('x')),
        'load:x',
      );
      expect(
        label(
          const SysInfoAbiMismatchException(
            'y',
            expectedAbi: 1,
            actualAbi: 2,
          ),
        ),
        'abi:y:1:2',
      );
      expect(
        label(const SysInfoDisposedException('z')),
        'disposed:z',
      );
      expect(
        label(const SysInfoUnsupportedPlatformException('w')),
        'platform:w',
      );
    });
  });

  group('hierarchy shape', () {
    test('subtypes are not instances of sibling types', () {
      const load = SysInfoLoadException('load');
      const abi = SysInfoAbiMismatchException(
        'abi',
        expectedAbi: 1,
        actualAbi: 2,
      );
      const disposed = SysInfoDisposedException('disposed');
      const platform = SysInfoUnsupportedPlatformException('platform');

      expect(load, isA<SysInfoLoadException>());
      expect(load, isNot(isA<SysInfoAbiMismatchException>()));
      expect(load, isNot(isA<SysInfoDisposedException>()));
      expect(load, isNot(isA<SysInfoUnsupportedPlatformException>()));

      expect(abi, isA<SysInfoAbiMismatchException>());
      expect(abi, isNot(isA<SysInfoLoadException>()));
      expect(abi, isNot(isA<SysInfoDisposedException>()));
      expect(abi, isNot(isA<SysInfoUnsupportedPlatformException>()));

      expect(disposed, isA<SysInfoDisposedException>());
      expect(disposed, isNot(isA<SysInfoLoadException>()));
      expect(disposed, isNot(isA<SysInfoAbiMismatchException>()));
      expect(disposed, isNot(isA<SysInfoUnsupportedPlatformException>()));

      expect(platform, isA<SysInfoUnsupportedPlatformException>());
      expect(platform, isNot(isA<SysInfoLoadException>()));
      expect(platform, isNot(isA<SysInfoAbiMismatchException>()));
      expect(platform, isNot(isA<SysInfoDisposedException>()));
    });
  });
}
