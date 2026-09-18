import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_sysinfo/src/prebuilt/downloader.dart';
import 'package:dart_sysinfo/src/prebuilt/manifest.dart';
import 'package:test/test.dart';

void main() {
  group('PrebuiltDownloader', () {
    test('downloadVerified accepts matching sha256 from file url', () async {
      final temp = await Directory.systemTemp.createTemp('prebuilt_dl_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final bytes = utf8.encode('prebuilt-test-bytes');
      final source = File('${temp.path}/source.so')..writeAsBytesSync(bytes);
      final digest = sha256.convert(bytes).toString();
      final destination = File('${temp.path}/dest.so');

      final artifact = PrebuiltArtifact.fromJson('linux-x64', {
        'fileName': 'libdart_sysinfo_native.so',
        'sha256': digest,
        'url': source.uri.toString(),
        'attestation': {
          'kind': 'github-artifact-attestation',
          'repository': 'mvitlov/dart_sysinfo',
          'digestAlgorithm': 'sha256',
          'digest': digest,
        },
      });

      await PrebuiltDownloader().downloadVerified(
        artifact: artifact,
        destination: destination,
      );

      expect(await destination.readAsBytes(), bytes);
    });

    test('downloadVerified rejects sha256 mismatch', () async {
      final temp = await Directory.systemTemp.createTemp('prebuilt_dl_');
      addTearDown(() => temp.deleteSync(recursive: true));

      final source = File('${temp.path}/source.so')
        ..writeAsBytesSync([1, 2, 3]);
      final destination = File('${temp.path}/dest.so');

      final artifact = PrebuiltArtifact.fromJson('linux-x64', {
        'fileName': 'libdart_sysinfo_native.so',
        'sha256': 'deadbeef',
        'url': source.uri.toString(),
        'attestation': {
          'kind': 'github-artifact-attestation',
          'repository': 'mvitlov/dart_sysinfo',
          'digestAlgorithm': 'sha256',
          'digest': 'deadbeef',
        },
      });

      expect(
        () => PrebuiltDownloader().downloadVerified(
          artifact: artifact,
          destination: destination,
        ),
        throwsStateError,
      );
    });
  });
}
