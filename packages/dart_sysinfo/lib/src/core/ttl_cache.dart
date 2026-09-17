/// Per-domain snapshot TTL cache (TDD §3.4, PRD §5.5).
library;

/// Caches the result of an async fetch for a fixed time-to-live.
class TtlCache<T> {
  /// Creates a cache with the given [ttl].
  TtlCache(this.ttl);

  /// Duration before a cached value is considered stale.
  final Duration ttl;

  T? _value;
  DateTime? _fetchedAt;

  /// Returns a cached value when fresh, otherwise calls [fetch].
  Future<T> read(
    Future<T> Function() fetch, {
    required bool forceRefresh,
  }) async {
    final fresh = _value == null ||
        forceRefresh ||
        DateTime.now().difference(_fetchedAt!) >= ttl;
    if (!fresh) {
      return _value as T;
    }
    final result = await fetch();
    _value = result;
    _fetchedAt = DateTime.now();
    return result;
  }
}
