import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:dart_sysinfo/src/prebuilt/code_config_mapping.dart';
import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';
import 'package:hooks/hooks.dart';

/// Registers a verified prebuilt dynamic library as a Native Assets code asset.
void registerPrebuiltCodeAsset({
  required BuildInput input,
  required BuildOutputBuilder output,
  required File libraryFile,
  String assetName = 'src/bridge/frb_generated.io.dart',
}) {
  if (!input.config.buildCodeAssets) {
    return;
  }

  final linkMode = input.config.code.linkMode;
  for (final routing in const [ToAppBundle()]) {
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: assetName,
        linkMode: linkMode,
        file: libraryFile.uri,
      ),
      routing: routing,
    );
  }
}
