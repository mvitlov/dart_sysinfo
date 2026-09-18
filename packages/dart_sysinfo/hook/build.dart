import 'dart:io';

import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
import 'package:hooks/hooks.dart';

/// Native Assets build hook (M2-01, TDD §7).
///
/// Compiles `packages/native` via `native_toolchain_rust` in parallel with the
/// Cargokit default backend. Runtime loading remains Cargokit until M5.
///
/// Skips when Rust is unavailable (Flutter-free `dart pub get` / `dart test`) or
/// when [skipNativeAssetsHook] is true.
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (skipNativeAssetsHook()) {
      return;
    }
    await const FlutterRustBridgeNativeAssetsBuilder(
      cratePath: '../native',
      assetName: 'src/bridge/frb_generated.io.dart',
    ).run(input: input, output: output);
  });
}

/// Whether to skip the Native Assets compile (hook exits successfully as no-op).
bool skipNativeAssetsHook() {
  if (Platform.environment['DART_SYSINFO_SKIP_NATIVE_ASSETS_HOOK'] == '1') {
    return true;
  }
  return !isRustToolchainAvailable();
}

/// Detect rustup on PATH or under the default cargo home.
bool isRustToolchainAvailable() {
  try {
    final locator = Platform.isWindows ? 'where' : 'which';
    final result = Process.runSync(locator, ['rustup']);
    if (result.exitCode == 0) {
      return true;
    }
  } on ProcessException {
    // Fall through to cargo-home probe.
  }

  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) {
    return false;
  }

  final rustup = Platform.isWindows
      ? '$home\\.cargo\\bin\\rustup.exe'
      : '$home/.cargo/bin/rustup';
  return File(rustup).existsSync();
}
