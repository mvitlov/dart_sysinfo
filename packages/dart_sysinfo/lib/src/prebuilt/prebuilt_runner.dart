import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:dart_sysinfo/src/core/abi_guard.dart';
import 'package:dart_sysinfo/src/prebuilt/attestation.dart';
import 'package:dart_sysinfo/src/prebuilt/code_asset.dart';
import 'package:dart_sysinfo/src/prebuilt/downloader.dart';
import 'package:dart_sysinfo/src/prebuilt/manifest.dart';
import 'package:dart_sysinfo/src/prebuilt/prebuilt_env.dart';
import 'package:hooks/hooks.dart';

/// Expected ABI in manifest must match the Dart-side guard (M1-05).
const prebuiltExpectedAbi = AbiGuard.expectedAbi;

/// Default manifest path relative to the dart_sysinfo package root.
const defaultManifestRelativePath = 'prebuilt/manifest.json';

/// Resolves the manifest file for the current hook invocation.
File resolveManifestFile({required Uri packageRoot}) {
  final override = PrebuiltEnv.manifestOverridePath;
  if (override != null && override.isNotEmpty) {
    return File(override);
  }
  return File.fromUri(packageRoot.resolve(defaultManifestRelativePath));
}

/// Reads package version from pubspec.yaml for manifest validation.
String readPackageVersion({required Uri packageRoot}) {
  final pubspec = File.fromUri(packageRoot.resolve('pubspec.yaml'));
  for (final line in pubspec.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.startsWith('version:')) {
      return trimmed.substring('version:'.length).trim();
    }
  }
  return '';
}

/// Attempts the prebuilt download path. Returns true when an asset was registered.
Future<bool> tryUsePrebuilt({
  required BuildInput input,
  required BuildOutputBuilder output,
  PrebuiltDownloader? downloader,
  PrebuiltAttestationVerifier? attestationVerifier,
}) async {
  if (!input.config.buildCodeAssets) {
    return false;
  }

  final manifestFile = resolveManifestFile(packageRoot: input.packageRoot);
  if (!manifestFile.existsSync()) {
    return false;
  }

  final manifest = PrebuiltManifest.loadFile(manifestFile.path);
  if (manifest.abi != prebuiltExpectedAbi) {
    throw StateError(
      'prebuilt manifest abi (${manifest.abi}) does not match expected '
      'Dart ABI ($prebuiltExpectedAbi)',
    );
  }

  final packageVersion = readPackageVersion(packageRoot: input.packageRoot);
  if (manifest.packageVersion.isNotEmpty &&
      packageVersion.isNotEmpty &&
      manifest.packageVersion != packageVersion) {
    throw StateError(
      'prebuilt manifest packageVersion (${manifest.packageVersion}) does not '
      'match pubspec version ($packageVersion)',
    );
  }

  final targetKey = PrebuiltManifest.targetKeyFor(input.config.code);
  final artifact = manifest.artifactForTarget(targetKey);
  if (artifact == null) {
    return false;
  }

  final outputDir = Directory.fromUri(input.outputDirectoryShared.resolve(
    'prebuilt/$targetKey/',
  ));
  final destination = File('${outputDir.path}/${artifact.fileName}');

  final effectiveDownloader = downloader ?? PrebuiltDownloader();
  await effectiveDownloader.downloadVerified(
    artifact: artifact,
    destination: destination,
  );

  final effectiveAttestation = attestationVerifier ?? PrebuiltAttestationVerifier();
  await effectiveAttestation.verify(
    artifactFile: destination,
    artifact: artifact,
  );

  registerPrebuiltCodeAsset(
    input: input,
    output: output,
    libraryFile: destination,
  );
  return true;
}
