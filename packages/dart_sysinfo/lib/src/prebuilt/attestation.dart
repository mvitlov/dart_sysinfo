import 'dart:io';

import 'package:dart_sysinfo/src/prebuilt/manifest.dart';
import 'package:dart_sysinfo/src/prebuilt/prebuilt_env.dart';

/// Verifies GitHub Artifact Attestation for a prebuilt library (PRD §7.3).
class PrebuiltAttestationVerifier {
  PrebuiltAttestationVerifier({
    Future<ProcessResult> Function(String, List<String>)? runProcess,
    bool? skipAttestationVerify,
  })  : _runProcess = runProcess ?? Process.run,
        _skipAttestationVerify = skipAttestationVerify;

  final Future<ProcessResult> Function(String, List<String>) _runProcess;
  final bool? _skipAttestationVerify;

  Future<void> verify({
    required File artifactFile,
    required PrebuiltArtifact artifact,
  }) async {
    if (_skipAttestationVerify ?? PrebuiltEnv.skipAttestationVerify) {
      return;
    }

    final attestation = artifact.attestation;
    if (attestation.kind != 'github-artifact-attestation') {
      throw StateError(
        'unsupported attestation kind: ${attestation.kind}',
      );
    }

    if (attestation.digestAlgorithm != 'sha256') {
      throw StateError(
        'unsupported digest algorithm: ${attestation.digestAlgorithm}',
      );
    }

    if (attestation.digest.isNotEmpty &&
        attestation.digest != artifact.sha256) {
      throw StateError(
        'attestation digest does not match manifest sha256 '
        'for ${artifact.targetKey}',
      );
    }

    if (attestation.repository.isEmpty) {
      throw StateError(
        'attestation.repository is required for ${artifact.targetKey}',
      );
    }

    final result = await _runProcess('gh', [
      'attestation',
      'verify',
      artifactFile.path,
      '--repo',
      attestation.repository,
    ]);

    if (result.exitCode != 0) {
      final stderr = result.stderr.toString().trim();
      throw StateError(
        'gh attestation verify failed for ${artifact.targetKey}'
        '${stderr.isEmpty ? '' : ': $stderr'}',
      );
    }
  }
}
