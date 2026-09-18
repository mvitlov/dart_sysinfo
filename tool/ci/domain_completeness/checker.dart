/// Domain-completeness checker (M3-02, PRD §10.2).
library;

import 'dart:io';

import '../../new_domain/naming.dart';

final _domainRow = RegExp(r'^\| `([a-z][a-z0-9_]*)` \|');

class CompletenessViolation {
  CompletenessViolation({
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

class DomainCompletenessChecker {
  DomainCompletenessChecker({required this.repoRoot});

  final Directory repoRoot;

  String get _dartRoot => '${repoRoot.path}/packages/dart_sysinfo';

  List<CompletenessViolation> check() {
    final domains = discoverDomains();
    final matrix = File('${repoRoot.path}/docs/capability-matrix.md');
    if (!matrix.existsSync()) {
      return [
        CompletenessViolation(
          domain: '*',
          message: 'docs/capability-matrix.md is missing',
          fixHint: 'restore docs/capability-matrix.md from git',
        ),
      ];
    }
    final matrixText = matrix.readAsStringSync();
    final capabilityRows = _capabilityRows(matrixText);
    final permissionRows = _permissionRows(matrixText);
    final p1Capability = _sectionRows(
      matrixText,
      '## Capability matrix (P1)',
    );
    final p1Permission = _sectionRows(
      matrixText,
      '## Android permission matrix (P1)',
    );

    final violations = <CompletenessViolation>[];
    for (final name in domains) {
      violations.addAll(
        _checkDomain(
          name,
          capabilityRows: capabilityRows,
          permissionRows: permissionRows,
        ),
      );
    }

    for (final name in p1Capability) {
      if (!domains.contains(name)) {
        violations.add(
          CompletenessViolation(
            domain: name,
            message: 'P1 capability-matrix row has no domain folder',
            fixHint:
                'add packages/dart_sysinfo/lib/src/domains/$name/ '
                'or remove the row',
          ),
        );
      }
    }
    for (final name in p1Permission) {
      if (!domains.contains(name)) {
        violations.add(
          CompletenessViolation(
            domain: name,
            message: 'P1 permission-matrix row has no domain folder',
            fixHint:
                'add packages/dart_sysinfo/lib/src/domains/$name/ '
                'or remove the row',
          ),
        );
      }
    }
    return violations;
  }

  List<String> discoverDomains() {
    final dir = Directory('$_dartRoot/lib/src/domains');
    if (!dir.existsSync()) {
      return [];
    }
    final names = dir
        .listSync()
        .whereType<Directory>()
        .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
        .where((name) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name))
        .toList()
      ..sort();
    return names;
  }

  Iterable<CompletenessViolation> _checkDomain(
    String name, {
    required Set<String> capabilityRows,
    required Set<String> permissionRows,
  }) {
    final pascal = DomainNaming.pascalCase(name);
    final violations = <CompletenessViolation>[];

    void requireFile(String relative, String hint) {
      final file = File('$_dartRoot/$relative');
      if (!file.existsSync()) {
        violations.add(
          CompletenessViolation(
            domain: name,
            message: 'missing $relative',
            fixHint: hint,
          ),
        );
      }
    }

    final scaffoldHint =
        'fvm dart run tool/new_domain.dart $name   # or restore from git';

    requireFile(
      'lib/src/domains/$name/${name}_domain.dart',
      scaffoldHint,
    );
    requireFile(
      'lib/src/domains/$name/${name}_info.dart',
      scaffoldHint,
    );
    requireFile(
      'lib/src/domains/$name/${name}_domain_impl.dart',
      scaffoldHint,
    );
    requireFile(
      'lib/src/domains/$name/${name}_mapper.dart',
      scaffoldHint,
    );
    requireFile(
      'lib/src/testing/fake_${name}_domain.dart',
      scaffoldHint,
    );
    requireFile(
      'test/domains/${name}_domain_test.dart',
      scaffoldHint,
    );

    final testing = _read('$_dartRoot/lib/testing.dart');
    if (testing != null &&
        !testing.contains(
          "export 'src/testing/fake_${name}_domain.dart';",
        )) {
      violations.add(
        CompletenessViolation(
          domain: name,
          message: 'fake is not exported from lib/testing.dart',
          fixHint:
              "add export 'src/testing/fake_${name}_domain.dart'; "
              'to packages/dart_sysinfo/lib/testing.dart',
        ),
      );
    }

    final sysInfo = _read('$_dartRoot/lib/src/core/sys_info.dart');
    if (sysInfo != null &&
        !RegExp('${pascal}Domain get $name;').hasMatch(sysInfo)) {
      violations.add(
        CompletenessViolation(
          domain: name,
          message: 'SysInfo is missing ${pascal}Domain get $name',
          fixHint:
              'add `${pascal}Domain get $name;` in '
              'packages/dart_sysinfo/lib/src/core/sys_info.dart',
        ),
      );
    }

    if (!capabilityRows.contains(name)) {
      violations.add(
        CompletenessViolation(
          domain: name,
          message: 'no capability-matrix row',
          fixHint:
              'add a `| `$name` |` row to docs/capability-matrix.md '
              '(P1 table or P2 scaffold block)',
        ),
      );
    }
    if (!permissionRows.contains(name)) {
      violations.add(
        CompletenessViolation(
          domain: name,
          message: 'no permission-matrix row',
          fixHint:
              'add a `| `$name` |` row to the Android permission matrix '
              'in docs/capability-matrix.md',
        ),
      );
    }

    final rustApi = File(
      '${repoRoot.path}/packages/native/src/api/$name.rs',
    );
    if (!rustApi.existsSync()) {
      violations.add(
        CompletenessViolation(
          domain: name,
          message: 'missing packages/native/src/api/$name.rs',
          fixHint: scaffoldHint,
        ),
      );
    }
    final rustMod = _read(
      '${repoRoot.path}/packages/native/src/api/mod.rs',
    );
    if (rustMod != null && !rustMod.contains('pub mod $name;')) {
      violations.add(
        CompletenessViolation(
          domain: name,
          message: 'api/mod.rs does not declare `pub mod $name;`',
          fixHint: 'add `pub mod $name;` to packages/native/src/api/mod.rs',
        ),
      );
    }

    final streamSample = File(
      '$_dartRoot/lib/src/domains/$name/${name}_stream_sample.dart',
    );
    if (streamSample.existsSync()) {
      final barrel = _read('$_dartRoot/lib/dart_sysinfo.dart');
      if (barrel != null &&
          !barrel.contains(
            "export 'src/domains/$name/${name}_stream_sample.dart';",
          )) {
        violations.add(
          CompletenessViolation(
            domain: name,
            message: 'stream sample is not exported from dart_sysinfo.dart',
            fixHint:
                "add export 'src/domains/$name/${name}_stream_sample.dart';",
          ),
        );
      }
    }

    return violations;
  }

  Set<String> _capabilityRows(String text) {
    return {
      ..._sectionRows(text, '## Capability matrix (P1)'),
      ..._markerRows(
        text,
        '<!-- GENERATOR:BEGIN p2-capability-rows -->',
        '<!-- GENERATOR:END p2-capability-rows -->',
      ),
    };
  }

  Set<String> _permissionRows(String text) {
    return {
      ..._sectionRows(text, '## Android permission matrix (P1)'),
      ..._markerRows(
        text,
        '<!-- GENERATOR:BEGIN p2-permission-rows -->',
        '<!-- GENERATOR:END p2-permission-rows -->',
      ),
    };
  }

  Set<String> _sectionRows(String text, String heading) {
    final start = text.indexOf(heading);
    if (start == -1) {
      return {};
    }
    final rest = text.substring(start + heading.length);
    final next = rest.indexOf('\n## ');
    final section = next == -1 ? rest : rest.substring(0, next);
    return _rowsIn(section);
  }

  Set<String> _markerRows(String text, String begin, String end) {
    final start = text.indexOf(begin);
    final stop = text.indexOf(end);
    if (start == -1 || stop == -1 || stop <= start) {
      return {};
    }
    return _rowsIn(text.substring(start, stop));
  }

  Set<String> _rowsIn(String text) {
    return {
      for (final line in text.split('\n'))
        if (_domainRow.firstMatch(line) case final match?) match.group(1)!,
    };
  }

  String? _read(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return file.readAsStringSync();
  }
}
