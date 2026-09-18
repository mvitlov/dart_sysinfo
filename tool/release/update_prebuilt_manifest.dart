/// Updates packages/dart_sysinfo/prebuilt/manifest.json for a release row.
library;

import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final options = _parseArgs(args);
  if (options == null) {
    stderr.writeln(
      'Usage: dart run tool/release/update_prebuilt_manifest.dart '
      '--target linux-x64 '
      '--file dist/prebuilt/linux-x64/libdart_sysinfo_native.so '
      '--url https://github.com/org/repo/releases/download/prebuilt-v0.1.0/linux-x64-libdart_sysinfo_native.so '
      '[--repository org/repo] '
      '[--package-version 0.1.0] '
      '[--abi 3]',
    );
    exit(64);
  }

  final digest = _sha256HexFile(options.filePath);

  final manifestFile = File(options.manifestPath);
  Map<String, Object?> manifest;
  if (manifestFile.existsSync()) {
    final decoded = jsonDecode(manifestFile.readAsStringSync());
    if (decoded is! Map) {
      stderr.writeln('manifest root must be an object');
      exit(1);
    }
    manifest = Map<String, Object?>.from(decoded);
  } else {
    manifest = {
      'packageVersion': options.packageVersion,
      'abi': options.abi,
      'artifacts': <String, Object?>{},
    };
  }

  manifest['packageVersion'] = options.packageVersion;
  manifest['abi'] = options.abi;

  final artifacts = Map<String, Object?>.from(
    manifest['artifacts'] as Map? ?? {},
  );
  artifacts[options.targetKey] = {
    'fileName': options.fileName,
    'sha256': digest,
    'url': options.url,
    'attestation': {
      'kind': 'github-artifact-attestation',
      'repository': options.repository,
      'digestAlgorithm': 'sha256',
      'digest': digest,
    },
  };
  manifest['artifacts'] = artifacts;

  await manifestFile.parent.create(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  await manifestFile.writeAsString('${encoder.convert(manifest)}\n');
  stdout.writeln(
    'Updated ${manifestFile.path} (${options.targetKey} sha256=$digest)',
  );
}

_Options? _parseArgs(List<String> args) {
  String? targetKey;
  String? filePath;
  String? url;
  var repository = 'mvitlov/dart_sysinfo';
  var packageVersion = '0.1.0';
  var abi = 3;
  var manifestPath = 'packages/dart_sysinfo/prebuilt/manifest.json';

  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    String value() {
      if (i + 1 >= args.length) {
        stderr.writeln('Missing value for $arg');
        exit(64);
      }
      return args[++i];
    }

    switch (arg) {
      case '--target':
        targetKey = value();
      case '--file':
        filePath = value();
      case '--url':
        url = value();
      case '--repository':
        repository = value();
      case '--package-version':
        packageVersion = value();
      case '--abi':
        abi = int.parse(value());
      case '--manifest':
        manifestPath = value();
      default:
        stderr.writeln('Unknown argument: $arg');
        return null;
    }
  }

  if (targetKey == null || filePath == null || url == null) {
    return null;
  }

  return _Options(
    targetKey: targetKey,
    filePath: filePath,
    fileName: File(filePath).uri.pathSegments.last,
    url: url,
    repository: repository,
    packageVersion: packageVersion,
    abi: abi,
    manifestPath: manifestPath,
  );
}

String _sha256HexFile(String path) {
  final result = Process.runSync('shasum', ['-a', '256', path]);
  if (result.exitCode != 0) {
    throw StateError('shasum failed: ${result.stderr}');
  }
  final line = result.stdout.toString().trim();
  return line.split(RegExp(r'\s+')).first.toLowerCase();
}

class _Options {
  _Options({
    required this.targetKey,
    required this.filePath,
    required this.fileName,
    required this.url,
    required this.repository,
    required this.packageVersion,
    required this.abi,
    required this.manifestPath,
  });

  final String targetKey;
  final String filePath;
  final String fileName;
  final String url;
  final String repository;
  final String packageVersion;
  final int abi;
  final String manifestPath;
}
