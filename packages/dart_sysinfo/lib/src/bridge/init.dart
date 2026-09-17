import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'frb_generated.dart';

/// Initializes the FRB bridge, loading the native library from the correct
/// location for each platform.
///
/// On macOS/iOS, Cargokit statically links Rust into the plugin framework
/// (`dart_sysinfo.framework`), not a separate `dart_sysinfo_native` dylib.
Future<void> initDartSysinfoBridge() async {
  if (Platform.isMacOS || Platform.isIOS) {
    await RustLib.init(
      externalLibrary: ExternalLibrary.open(
        'dart_sysinfo.framework/dart_sysinfo',
      ),
    );
  } else {
    await RustLib.init();
  }
}
