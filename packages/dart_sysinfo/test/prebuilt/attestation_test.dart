import 'dart:io';

import 'package:dart_sysinfo/src/prebuilt/attestation.dart';
import 'package:dart_sysinfo/src/prebuilt/manifest.dart';
import 'package:test/test.dart';

void main() {
  group('PrebuiltAttestationVerifier', () {
    test('verify delegates to gh attestation verify', () async {
      final temp = await Directory.systemTemp.createTemp('prebuilt_attest_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final file = File('${temp.path}/libdart_sysinfo_native.so')
        ..writeAsBytesSync([1, 2, 3]);

      String? command;
      List<String>? args;
      final verifier = PrebuiltAttestationVerifier(
        runProcess: (executable, arguments) async {
          command = executable;
          args = arguments;
          return ProcessResult(0, 0, '', '');
        },
      );

      final artifact = PrebuiltArtifact.fromJson('linux-x64', {
        'fileName': 'libdart_sysinfo_native.so',
        'sha256': 'abc',
        'url': 'file://${file.path}',
        'attestation': {
          'kind': 'github-artifact-attestation',
          'repository': 'mvitlov/dart_sysinfo',
          'digestAlgorithm': 'sha256',
          'digest': 'abc',
        },
      });

      await verifier.verify(artifactFile: file, artifact: artifact);

      expect(command, 'gh');
      expect(args, contains('verify'));
      expect(args, contains('--repo'));
      expect(args, contains('mvitlov/dart_sysinfo'));
    });

    test('verify is skipped when attestation verify is disabled', () async {
      var called = false;
      final verifier = PrebuiltAttestationVerifier(
        skipAttestationVerify: true,
        runProcess: (executable, arguments) async {
          called = true;
          return ProcessResult(0, 0, '', '');
        },
      );

      final temp = await Directory.systemTemp.createTemp('prebuilt_attest_');
      addTearDown(() => temp.deleteSync(recursive: true));
      final file = File('${temp.path}/lib.so')..writeAsBytesSync([1]);

      await verifier.verify(
        artifactFile: file,
        artifact: PrebuiltArtifact.fromJson('linux-x64', {
          'fileName': 'lib.so',
          'sha256': 'abc',
          'url': 'file://${file.path}',
          'attestation': {
            'kind': 'github-artifact-attestation',
            'repository': 'mvitlov/dart_sysinfo',
            'digestAlgorithm': 'sha256',
            'digest': 'abc',
          },
        }),
      );

      expect(called, isFalse);
    });
  });
}
