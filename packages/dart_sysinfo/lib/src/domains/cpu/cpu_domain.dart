/// CPU domain interface (P1).
library;

import 'package:dart_sysinfo/src/domains/cpu/cpu_info.dart';

/// CPU metrics: TTL-cached snapshot and load stream.
abstract class CpuDomain {
  /// Returns a TTL-cached CPU snapshot.
  Future<CpuInfo> snapshot({bool forceRefresh = false});

  /// Broadcast CPU load samples at the requested interval.
  Stream<CpuLoadSample> load({Duration interval = const Duration(seconds: 1)});
}
