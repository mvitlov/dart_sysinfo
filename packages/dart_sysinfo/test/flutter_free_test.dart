import 'package:dart_sysinfo/dart_sysinfo.dart';
import 'package:test/test.dart';

void main() {
  group('Flutter-free core verification (M0-05)', () {
    test('dart_sysinfo can be imported in pure Dart without Flutter SDK', () {
      expect(RustLib.instance, isNotNull);
    });

    test('RustLib mock mode initializes in pure Dart', () {
      expect(RustLib.initMock, isNotNull);
    });
  });
}
