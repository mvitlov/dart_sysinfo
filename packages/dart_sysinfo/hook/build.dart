import 'package:hooks/hooks.dart';

/// Placeholder. Full Native Assets hook via `flutter_rust_bridge_hooks`
/// lands in M2.
///
/// Cargokit is the active backend for M0–M1; this no-op hook satisfies
/// Flutter's hook runner without compiling native code on the Native Assets
/// path.
void main(List<String> args) async {
  await build(args, (input, output) async {});
}
