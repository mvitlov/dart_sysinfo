/// File write helpers for the domain generator.
library;

import 'dart:io';

class DomainWriter {
  DomainWriter({
    required this.repoRoot,
    required this.dryRun,
  });

  final Directory repoRoot;
  final bool dryRun;

  Directory get dartSysinfoRoot =>
      Directory('${repoRoot.path}/packages/dart_sysinfo');

  Directory get nativeRoot => Directory('${repoRoot.path}/packages/native');

  File domainFile(String relativePath) =>
      File('${dartSysinfoRoot.path}/$relativePath');

  File repoFile(String relativePath) => File('${repoRoot.path}/$relativePath');

  void writeNewFile(String relativePath, String content) {
    final file = relativePath.startsWith('packages/')
        ? File('${repoRoot.path}/$relativePath')
        : domainFile(relativePath);
    if (file.existsSync()) {
      throw StateError('Refusing to overwrite existing file: ${file.path}');
    }
    _write(file, content);
  }

  void writePatch(String relativePath, String content) {
    final file = relativePath.startsWith('packages/') ||
            relativePath.startsWith('docs/')
        ? File('${repoRoot.path}/$relativePath')
        : domainFile(relativePath);
    _write(file, content);
  }

  void _write(File file, String content) {
    if (dryRun) {
      stdout.writeln('[dry-run] write ${file.path}');
      return;
    }
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(content);
    stdout.writeln('Wrote ${file.path}');
  }

  void assertDomainAbsent(String name) {
    final domainDir = domainFile('lib/src/domains/$name');
    if (domainDir.existsSync()) {
      throw StateError('Domain folder already exists: ${domainDir.path}');
    }
    final sysInfo = domainFile('lib/src/core/sys_info.dart');
    if (!sysInfo.existsSync()) {
      throw StateError('Missing sys_info.dart at ${sysInfo.path}');
    }
    final sysInfoContent = sysInfo.readAsStringSync();
    if (RegExp(r'\b$name\b').hasMatch(sysInfoContent) &&
        sysInfoContent.contains('Domain get $name')) {
      throw StateError('Domain "$name" already wired in sys_info.dart');
    }
  }
}
