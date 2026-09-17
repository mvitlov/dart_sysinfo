/// OS domain interface (P1).
library;

import 'package:dart_sysinfo/src/domains/os/os_info.dart';

/// OS metrics: TTL-cached snapshot.
abstract class OsDomain {
  /// Returns a TTL-cached OS snapshot.
  Future<OsInfo> snapshot({bool forceRefresh = false});
}
