/// Flutter-free debug logging for developer diagnostics (PRD §5.4).
library;

/// Logs [message] only when asserts are enabled (debug builds).
void debugLog(String message) {
  assert(() {
    // ignore: avoid_print
    print('[dart_sysinfo] $message');
    return true;
  }());
}
