/// Memory domain interface (P1).
library;

import 'package:dart_sysinfo/src/domains/memory/memory_info.dart';

/// Memory metrics: TTL-cached snapshot.
abstract class MemoryDomain {
  /// Returns a TTL-cached memory snapshot.
  Future<MemoryInfo> snapshot({bool forceRefresh = false});
}
