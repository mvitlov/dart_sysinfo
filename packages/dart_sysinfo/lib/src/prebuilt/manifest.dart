import 'dart:convert';
import 'dart:io';

import 'package:code_assets/code_assets.dart';

/// Parsed prebuilt manifest (`prebuilt/manifest.json`, M3-06).
class PrebuiltManifest {
  PrebuiltManifest({
    required this.packageVersion,
    required this.abi,
    required this.artifacts,
  });

  factory PrebuiltManifest.fromJson(Map<String, Object?> json) {
    final artifactsRaw = json['artifacts'];
    if (artifactsRaw is! Map) {
      throw FormatException('manifest.artifacts must be a map');
    }

    final artifacts = <String, PrebuiltArtifact>{};
    for (final entry in artifactsRaw.entries) {
      if (entry.value is! Map) {
        throw FormatException('artifact ${entry.key} must be a map');
      }
      final targetKey = entry.key as String;
      artifacts[targetKey] = PrebuiltArtifact.fromJson(
        targetKey,
        Map<String, Object?>.from(entry.value as Map),
      );
    }

    return PrebuiltManifest(
      packageVersion: json['packageVersion'] as String? ?? '',
      abi: json['abi'] as int? ?? 0,
      artifacts: artifacts,
    );
  }

  final String packageVersion;
  final int abi;
  final Map<String, PrebuiltArtifact> artifacts;

  PrebuiltArtifact? artifactForTarget(String targetKey) => artifacts[targetKey];

  static PrebuiltManifest loadFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('prebuilt manifest not found', path);
    }
    final decoded = jsonDecode(file.readAsStringSync());
    if (decoded is! Map) {
      throw FormatException('prebuilt manifest root must be an object');
    }
    return PrebuiltManifest.fromJson(Map<String, Object?>.from(decoded));
  }

  static String targetKeyFor(CodeConfig config) {
    final os = switch (config.targetOS) {
      OS.linux => 'linux',
      OS.macOS => 'macos',
      OS.windows => 'windows',
      OS.android => 'android',
      OS.iOS => 'ios',
      _ => config.targetOS.name,
    };
    final arch = switch (config.targetArchitecture) {
      Architecture.x64 => 'x64',
      Architecture.arm64 => 'arm64',
      Architecture.arm => 'arm',
      Architecture.riscv64 => 'riscv64',
      _ => config.targetArchitecture.name,
    };
    return '$os-$arch';
  }
}

/// One prebuilt artifact row in the manifest.
class PrebuiltArtifact {
  PrebuiltArtifact({
    required this.targetKey,
    required this.fileName,
    required this.sha256,
    required this.url,
    required this.attestation,
  });

  factory PrebuiltArtifact.fromJson(
    String targetKey,
    Map<String, Object?> json,
  ) {
    final attestationRaw = json['attestation'];
    if (attestationRaw is! Map) {
      throw FormatException('artifact $targetKey attestation must be a map');
    }

    return PrebuiltArtifact(
      targetKey: targetKey,
      fileName: json['fileName'] as String? ?? '',
      sha256: (json['sha256'] as String? ?? '').toLowerCase(),
      url: json['url'] as String? ?? '',
      attestation: PrebuiltAttestation.fromJson(
        Map<String, Object?>.from(attestationRaw),
      ),
    );
  }

  final String targetKey;
  final String fileName;
  final String sha256;
  final String url;
  final PrebuiltAttestation attestation;
}

/// GitHub Artifact Attestation metadata for a prebuilt row.
class PrebuiltAttestation {
  PrebuiltAttestation({
    required this.kind,
    required this.repository,
    required this.digestAlgorithm,
    required this.digest,
  });

  factory PrebuiltAttestation.fromJson(Map<String, Object?> json) {
    return PrebuiltAttestation(
      kind: json['kind'] as String? ?? '',
      repository: json['repository'] as String? ?? '',
      digestAlgorithm: json['digestAlgorithm'] as String? ?? 'sha256',
      digest: (json['digest'] as String? ?? '').toLowerCase(),
    );
  }

  final String kind;
  final String repository;
  final String digestAlgorithm;
  final String digest;
}
