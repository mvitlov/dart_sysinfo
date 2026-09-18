import 'dart:io';

import 'package:dart_sysinfo/src/prebuilt/prebuilt_env.dart';
import 'package:dart_sysinfo/src/prebuilt/prebuilt_runner.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

/// Native Assets build hook (M2-01, M3-06, TDD §7 / §9.4).
///
/// Prefers verified prebuilt artifacts when available; compiles from source
/// when `DART_SYSINFO_FROM_SOURCE=1`, prebuilts are unavailable, or Rust is
/// present as a dev fallback. Cargokit remains the runtime default until M5.
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    if (PrebuiltEnv.skipNativeAssetsHook) {
      return;
    }

    if (PrebuiltEnv.forceFromSource) {
      await _compileFromSource(input: input, output: output);
      return;
    }

    Object? prebuiltError;
    StackTrace? prebuiltStack;
    try {
      final usedPrebuilt = await tryUsePrebuilt(input: input, output: output);
      if (usedPrebuilt) {
        return;
      }
    } on Object catch (error, stackTrace) {
      prebuiltError = error;
      prebuiltStack = stackTrace;
      if (PrebuiltEnv.requirePrebuilt) {
        Error.throwWithStackTrace(error, stackTrace);
      }
    }

    if (!PrebuiltEnv.requirePrebuilt && isRustToolchainAvailable()) {
      await _compileFromSource(input: input, output: output);
      return;
    }

    if (PrebuiltEnv.requirePrebuilt) {
      Error.throwWithStackTrace(
        prebuiltError ??
            StateError(
              'prebuilt artifact required but unavailable for this target; '
              'run `dart run dart_sysinfo:doctor`',
            ),
        prebuiltStack ?? StackTrace.current,
      );
    }
  });
}

Future<void> _compileFromSource({
  required BuildInput input,
  required BuildOutputBuilder output,
}) {
  return const FlutterRustBridgeNativeAssetsBuilder(
    cratePath: '../native',
    assetName: 'src/bridge/frb_generated.io.dart',
  ).run(input: input, output: output);
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
