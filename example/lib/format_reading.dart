import 'package:dart_sysinfo/dart_sysinfo.dart';

/// Formats a [Reading] for display in the example UI.
String formatReading<T>(Reading<T> reading) {
  return reading.when(
    value: (value) => value.toString(),
    unsupported: (reason) =>
        reason == null ? 'unsupported' : 'unsupported ($reason)',
    unavailable: (reason) =>
        reason == null ? 'unavailable' : 'unavailable ($reason)',
  );
}

/// Formats byte counts as gibibytes with one decimal place.
String formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const gib = 1024 * 1024 * 1024;
  if (bytes >= gib) {
    return '${(bytes / gib).toStringAsFixed(1)} GiB';
  }
  const mib = 1024 * 1024;
  if (bytes >= mib) {
    return '${(bytes / mib).toStringAsFixed(1)} MiB';
  }
  return '$bytes B';
}
