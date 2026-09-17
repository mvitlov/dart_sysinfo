import 'package:dart_sysinfo/src/core/ttl_cache.dart';
import 'package:test/test.dart';

void main() {
  group('TtlCache', () {
    test('returns_cached_value_within_ttl', () async {
      final cache = TtlCache<int>(const Duration(milliseconds: 500));
      var fetchCalls = 0;

      final first = await cache.read(
        () async {
          fetchCalls++;
          return 1;
        },
        forceRefresh: false,
      );
      final second = await cache.read(
        () async {
          fetchCalls++;
          return 2;
        },
        forceRefresh: false,
      );

      expect(first, 1);
      expect(second, 1);
      expect(fetchCalls, 1);
    });

    test('forceRefresh_bypasses_cache', () async {
      final cache = TtlCache<int>(const Duration(milliseconds: 500));
      var fetchCalls = 0;

      await cache.read(
        () async {
          fetchCalls++;
          return 1;
        },
        forceRefresh: false,
      );
      final second = await cache.read(
        () async {
          fetchCalls++;
          return 2;
        },
        forceRefresh: true,
      );

      expect(second, 2);
      expect(fetchCalls, 2);
    });

    test('expires_after_ttl', () async {
      final cache = TtlCache<int>(const Duration(milliseconds: 20));
      var fetchCalls = 0;

      await cache.read(
        () async {
          fetchCalls++;
          return 1;
        },
        forceRefresh: false,
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final second = await cache.read(
        () async {
          fetchCalls++;
          return 2;
        },
        forceRefresh: false,
      );

      expect(second, 2);
      expect(fetchCalls, 2);
    });
  });
}
