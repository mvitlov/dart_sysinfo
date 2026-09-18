import 'package:dart_sysinfo/src/prebuilt/manifest.dart';
import 'package:test/test.dart';

void main() {
  group('PrebuiltManifest', () {
    test('fromJson parses linux-x64 artifact', () {
      final manifest = PrebuiltManifest.fromJson({
        'packageVersion': '0.1.0',
        'abi': 3,
        'artifacts': {
          'linux-x64': {
            'fileName': 'libdart_sysinfo_native.so',
            'sha256': 'abc123',
            'url': 'file:///tmp/libdart_sysinfo_native.so',
            'attestation': {
              'kind': 'github-artifact-attestation',
              'repository': 'mvitlov/dart_sysinfo',
              'digestAlgorithm': 'sha256',
              'digest': 'abc123',
            },
          },
        },
      });

      expect(manifest.packageVersion, '0.1.0');
      expect(manifest.abi, 3);
      expect(manifest.artifactForTarget('linux-x64')?.fileName,
          'libdart_sysinfo_native.so');
    });
  });
}
