import 'dart:io';

import 'package:test/test.dart';

import '../ci/domain_completeness/checker.dart';
import '../new_domain/naming.dart';

void main() {
  group('DomainCompletenessChecker', () {
    test('discovers P1 domains and passes on this repo', () {
      final checker = DomainCompletenessChecker(
        repoRoot: Directory.current,
      );
      expect(checker.discoverDomains(), isNotEmpty);
      expect(checker.check(), isEmpty);
    });

    test('pascalCase matches generator naming', () {
      expect(DomainNaming.pascalCase('cpu'), 'Cpu');
      expect(DomainNaming.pascalCase('foo_bar'), 'FooBar');
    });

    test('passes on the committed valid fixture', () {
      final fixture = Directory(
        'tool/test/testdata/domain_completeness/valid',
      );
      final violations = DomainCompletenessChecker(
        repoRoot: fixture,
      ).check();
      expect(violations, isEmpty);
    });

    test('fails when capability row is missing', () async {
      final temp = await _copyValidFixture();
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/docs/capability-matrix.md').writeAsStringSync(
        '# matrix\n'
        '## Capability matrix (P1)\n'
        '| Domain | Snapshot TTL |\n'
        '|---|---|\n'
        '## Android permission matrix (P1)\n'
        '| Domain | Permissions merged by `dart_sysinfo` | Consumer |\n'
        '|---|---|---|\n'
        '| `cpu` | **None** | none |\n',
      );

      final violations = DomainCompletenessChecker(repoRoot: temp).check();
      expect(
        violations.map((v) => v.message),
        contains('no capability-matrix row'),
      );
    });

    test('fails when fake is missing', () async {
      final temp = await _copyValidFixture();
      addTearDown(() => temp.deleteSync(recursive: true));
      File(
        '${temp.path}/packages/dart_sysinfo/lib/src/testing/fake_cpu_domain.dart',
      ).deleteSync();

      final violations = DomainCompletenessChecker(repoRoot: temp).check();
      expect(
        violations.map((v) => v.message),
        contains(
          'missing lib/src/testing/fake_cpu_domain.dart',
        ),
      );
    });

    test('fails when domain test is missing', () async {
      final temp = await _copyValidFixture();
      addTearDown(() => temp.deleteSync(recursive: true));
      File(
        '${temp.path}/packages/dart_sysinfo/test/domains/cpu_domain_test.dart',
      ).deleteSync();

      final violations = DomainCompletenessChecker(repoRoot: temp).check();
      expect(
        violations.map((v) => v.message),
        contains('missing test/domains/cpu_domain_test.dart'),
      );
    });

    test('fails when fake is not exported', () async {
      final temp = await _copyValidFixture();
      addTearDown(() => temp.deleteSync(recursive: true));
      File('${temp.path}/packages/dart_sysinfo/lib/testing.dart')
          .writeAsStringSync("export 'src/testing/fake_sys_info.dart';\n");

      final violations = DomainCompletenessChecker(repoRoot: temp).check();
      expect(
        violations.map((v) => v.message),
        contains('fake is not exported from lib/testing.dart'),
      );
    });
  });
}

Future<Directory> _copyValidFixture() async {
  final source = Directory(
    'tool/test/testdata/domain_completeness/valid',
  );
  final temp = await Directory.systemTemp.createTemp('domain_complete_');
  await for (final entity in source.list(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final relative = entity.path.substring(source.path.length + 1);
    final target = File('${temp.path}/$relative');
    await target.parent.create(recursive: true);
    await entity.copy(target.path);
  }
  return temp;
}
