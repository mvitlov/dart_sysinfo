import 'dart:io';

/// Environment flags for the Native Assets prebuilt path (M3-06, TDD §9.4).
abstract final class PrebuiltEnv {
  static const fromSource = 'DART_SYSINFO_FROM_SOURCE';
  static const prebuiltRequired = 'DART_SYSINFO_PREBUILT';
  static const skipHook = 'DART_SYSINFO_SKIP_NATIVE_ASSETS_HOOK';
  static const manifestOverride = 'DART_SYSINFO_PREBUILT_MANIFEST';
  static const skipAttestationKey = 'DART_SYSINFO_SKIP_ATTESTATION';

  static bool isSet(String key) => Platform.environment[key] == '1';

  static bool get forceFromSource => isSet(fromSource);

  static bool get requirePrebuilt => isSet(prebuiltRequired);

  static bool get skipNativeAssetsHook => isSet(skipHook);

  static bool get skipAttestationVerify => isSet(skipAttestationKey);

  static String? get manifestOverridePath =>
      Platform.environment[manifestOverride];
}
