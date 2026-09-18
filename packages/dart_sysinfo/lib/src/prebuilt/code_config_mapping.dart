import 'package:code_assets/code_assets.dart';

/// Maps [CodeConfig.linkModePreference] to the [LinkMode] used when registering
/// prebuilt code assets (mirrors native_toolchain_rust).
extension PrebuiltCodeConfigMapping on CodeConfig {
  LinkMode get linkMode {
    return switch (linkModePreference) {
      LinkModePreference.dynamic ||
      LinkModePreference.preferDynamic =>
        DynamicLoadingBundled(),
      LinkModePreference.static ||
      LinkModePreference.preferStatic =>
        StaticLinking(),
      _ => throw UnsupportedError(
        'Unsupported LinkModePreference: $linkModePreference',
      ),
    };
  }
}
