import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dart_sysinfo/src/prebuilt/manifest.dart';

/// Downloads a prebuilt artifact and verifies its SHA256 digest.
class PrebuiltDownloader {
  PrebuiltDownloader({HttpClient? httpClient}) : _httpClient = httpClient;

  final HttpClient? _httpClient;

  /// Returns the verified artifact bytes written to [destination].
  Future<File> downloadVerified({
    required PrebuiltArtifact artifact,
    required File destination,
  }) async {
    final bytes = await _readBytes(artifact.url);
    final digest = sha256.convert(bytes).toString();
    if (digest != artifact.sha256) {
      throw StateError(
        'prebuilt SHA256 mismatch for ${artifact.targetKey}: '
        'expected ${artifact.sha256}, got $digest',
      );
    }

    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(bytes, flush: true);
    return destination;
  }

  Future<List<int>> _readBytes(String url) async {
    final uri = Uri.parse(url);
    if (uri.scheme == 'file') {
      return File.fromUri(uri).readAsBytes();
    }

    final client = _httpClient ?? HttpClient();
    final shouldClose = _httpClient == null;
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'prebuilt download failed (${response.statusCode})',
          uri: uri,
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      if (shouldClose) {
        client.close(force: true);
      }
    }
  }
}
