import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
import 'package:hooks/hooks.dart';

/// Native Assets build hook (M2-01, TDD §7).
///
/// Compiles `packages/native` via `native_toolchain_rust` in parallel with the
/// Cargokit default backend. Runtime loading remains Cargokit until M2-02/M5.
Future<void> main(List<String> args) async {
  await build(args, (input, output) async {
    await const FlutterRustBridgeNativeAssetsBuilder(
      cratePath: '../native',
      assetName: 'src/bridge/frb_generated.io.dart',
    ).run(input: input, output: output);
  });
}
