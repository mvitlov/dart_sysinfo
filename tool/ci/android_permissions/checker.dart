/// Android permission lint checker (M3-05, PRD §2.5).
library;

import 'dart:io';

final _domainRow = RegExp(r'^\| `([a-z][a-z0-9_]*)` \|');
final _accessPermission = RegExp(r'ACCESS_[A-Z_]+');
final _manifestPermission = RegExp(
  r'''android:name="([^"]+)"''',
);
final _domainMethodCall = RegExp(
  r'\.([a-z][a-z0-9_]*)\.(snapshot|throughput|load)\(',
);
final _sysInfoDomainAccess = RegExp(
  r'SysInfo\.instance\.([a-z][a-z0-9_]*)',
);

class PermissionViolation {
  PermissionViolation({
    required this.domain,
    required this.message,
    required this.fixHint,
  });

  final String domain;
  final String message;
  final String fixHint;

  @override
  String toString() => '[$domain] $message\n  fix: $fixHint';
}

class AndroidPermissionChecker {
  AndroidPermissionChecker({required this.repoRoot});

  final Directory repoRoot;

  static const exampleManifestPath =
      'example/android/app/src/main/AndroidManifest.xml';
  static const pluginManifestPath =
      'packages/dart_sysinfo/android/src/main/AndroidManifest.xml';
  static const capabilityMatrixPath = 'docs/capability-matrix.md';
  static const exampleLibPath = 'example/lib';

  List<PermissionViolation> check() {
    final violations = <PermissionViolation>[];

    final matrixFile = File('${repoRoot.path}/$capabilityMatrixPath');
    if (!matrixFile.existsSync()) {
      return [
        PermissionViolation(
          domain: '*',
          message: '$capabilityMatrixPath is missing',
          fixHint: 'restore docs/capability-matrix.md from git',
        ),
      ];
    }

    final matrixText = matrixFile.readAsStringSync();
    final requiredByDomain = _requiredPermissionsByDomain(matrixText);
    final exercisedDomains = _exercisedDomains();
    final examplePermissions = _manifestPermissions(exampleManifestPath);
    final pluginPermissions = _manifestPermissions(pluginManifestPath);

    for (final permission in pluginPermissions) {
      violations.add(
        PermissionViolation(
          domain: '*',
          message:
              'plugin manifest declares $permission — silent merge forbidden',
          fixHint:
              'remove <uses-permission> from $pluginManifestPath; '
              'document consumer obligation in docs/capability-matrix.md',
        ),
      );
    }

    for (final domain in exercisedDomains) {
      final required = requiredByDomain[domain];
      if (required == null || required.isEmpty) {
        continue;
      }
      final missing = required.difference(examplePermissions);
      if (missing.isEmpty) {
        continue;
      }
      violations.add(
        PermissionViolation(
          domain: domain,
          message:
              'example app exercises `$domain` but main manifest is missing '
              '${missing.join(", ")}',
          fixHint:
              'add ${missing.map((p) => '<uses-permission android:name="$p"/>').join(" ")} '
              'to $exampleManifestPath (see docs/capability-matrix.md)',
        ),
      );
    }

    return violations;
  }

  Map<String, Set<String>> _requiredPermissionsByDomain(String matrixText) {
    final rows = {
      ..._sectionPermissionRows(
        matrixText,
        '## Android permission matrix (P1)',
      ),
      ..._markerPermissionRows(
        matrixText,
        '<!-- GENERATOR:BEGIN p2-permission-rows -->',
        '<!-- GENERATOR:END p2-permission-rows -->',
      ),
    };

    final result = <String, Set<String>>{};
    for (final entry in rows.entries) {
      final permissions = _extractAccessPermissions(entry.value);
      if (permissions.isNotEmpty) {
        result[entry.key] = permissions;
      }
    }
    return result;
  }

  Map<String, String> _sectionPermissionRows(String text, String heading) {
    final start = text.indexOf(heading);
    if (start == -1) {
      return {};
    }
    final rest = text.substring(start + heading.length);
    final next = rest.indexOf('\n## ');
    final section = next == -1 ? rest : rest.substring(0, next);
    return _parsePermissionRows(section);
  }

  Map<String, String> _markerPermissionRows(
    String text,
    String begin,
    String end,
  ) {
    final start = text.indexOf(begin);
    final stop = text.indexOf(end);
    if (start == -1 || stop == -1 || stop <= start) {
      return {};
    }
    return _parsePermissionRows(text.substring(start, stop));
  }

  Map<String, String> _parsePermissionRows(String section) {
    final rows = <String, String>{};
    for (final line in section.split('\n')) {
      final domainMatch = _domainRow.firstMatch(line);
      if (domainMatch == null) {
        continue;
      }
      final cells = line.split('|').map((cell) => cell.trim()).toList();
      if (cells.length < 4) {
        continue;
      }
      // | `domain` | merged | consumer obligation |
      rows[domainMatch.group(1)!] = cells[3];
    }
    return rows;
  }

  Set<String> _extractAccessPermissions(String obligation) {
    return {
      for (final match in _accessPermission.allMatches(obligation))
        _normalizePermission(match.group(0)!),
    };
  }

  String _normalizePermission(String shortName) {
    if (shortName.startsWith('android.permission.')) {
      return shortName;
    }
    return 'android.permission.$shortName';
  }

  Set<String> _exercisedDomains() {
    final libDir = Directory('${repoRoot.path}/$exampleLibPath');
    if (!libDir.existsSync()) {
      return {};
    }

    final domains = <String>{};
    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) {
        continue;
      }
      final content = entity.readAsStringSync();
      for (final match in _domainMethodCall.allMatches(content)) {
        domains.add(match.group(1)!);
      }
      for (final match in _sysInfoDomainAccess.allMatches(content)) {
        domains.add(match.group(1)!);
      }
    }
    return domains;
  }

  Set<String> _manifestPermissions(String relativePath) {
    final file = File('${repoRoot.path}/$relativePath');
    if (!file.existsSync()) {
      return {};
    }
    final text = file.readAsStringSync();
    if (!text.contains('<uses-permission')) {
      return {};
    }

    final permissions = <String>{};
    for (final line in text.split('\n')) {
      if (!line.contains('<uses-permission')) {
        continue;
      }
      final match = _manifestPermission.firstMatch(line);
      if (match != null) {
        permissions.add(match.group(1)!);
      }
    }
    return permissions;
  }
}
