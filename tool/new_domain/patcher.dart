/// Surgical edits to existing repo files for new domain wiring.
library;

import 'naming.dart';

class MarkerBlock {
  MarkerBlock({
    required this.begin,
    required this.end,
    required this.lines,
  });

  final String begin;
  final String end;
  final List<String> lines;
}

class DomainPatcher {
  DomainPatcher(this.naming);

  final DomainNaming naming;

  String patchFile(String content, Map<String, String Function(String)> patches) {
    var updated = content;
    for (final entry in patches.entries) {
      updated = entry.value(updated);
    }
    return updated;
  }

  String insertAlphabeticallyInBlock(
    String content,
    String beginMarker,
    String endMarker,
    String newLine,
  ) {
    final beginIndex = content.indexOf(beginMarker);
    final endIndex = content.indexOf(endMarker);
    if (beginIndex == -1 || endIndex == -1 || endIndex <= beginIndex) {
      throw StateError('Missing markers: $beginMarker / $endMarker');
    }

    final blockStart = beginIndex + beginMarker.length;
    final blockContent = content.substring(blockStart, endIndex);
    final lines = blockContent
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();

    if (lines.any((line) => line.trim() == newLine.trim())) {
      throw StateError('Line already present in block: $newLine');
    }

    lines.add(newLine.trimRight());
    lines.sort((a, b) => a.trim().compareTo(b.trim()));

    final rebuiltBlock = '\n${lines.join('\n')}\n';
    return content.replaceRange(blockStart, endIndex, rebuiltBlock);
  }

  Map<String, String Function(String)> buildPatches() {
    final n = naming;
    final pascal = n.pascal;
    final name = n.name;

    return {
      'packages/native/src/api/mod.rs': (content) =>
          insertAlphabeticallyInBlock(
            content,
            '// GENERATOR:BEGIN api-mod',
            '// GENERATOR:END api-mod',
            'pub mod $name;',
          ),
      'packages/dart_sysinfo/lib/dart_sysinfo.dart': (content) {
        var updated = insertAlphabeticallyInBlock(
          content,
          '// GENERATOR:BEGIN domain-exports',
          '// GENERATOR:END domain-exports',
          "export 'src/domains/$name/${name}_domain.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN info-exports',
          '// GENERATOR:END info-exports',
          "export 'src/domains/$name/${name}_info.dart';",
        );
        if (n.hasStream) {
          updated = insertAlphabeticallyInBlock(
            updated,
            '// GENERATOR:BEGIN stream-exports',
            '// GENERATOR:END stream-exports',
            "export 'src/domains/$name/${name}_stream_sample.dart';",
          );
        }
        return updated;
      },
      'packages/dart_sysinfo/lib/testing.dart': (content) =>
          insertAlphabeticallyInBlock(
            content,
            '// GENERATOR:BEGIN fake-exports',
            '// GENERATOR:END fake-exports',
            "export 'src/testing/fake_${name}_domain.dart';",
          ),
      'packages/dart_sysinfo/lib/src/core/sys_info.dart': (content) {
        var updated = insertAlphabeticallyInBlock(
          content,
          '// GENERATOR:BEGIN domain-imports',
          '// GENERATOR:END domain-imports',
          "import 'package:dart_sysinfo/src/domains/$name/${name}_domain.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-imports',
          '// GENERATOR:END domain-impl-imports',
          "import 'package:dart_sysinfo/src/domains/$name/${name}_domain_impl.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-getters',
          '// GENERATOR:END domain-getters',
          '  ${pascal}Domain get $name;',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-init',
          '// GENERATOR:END domain-impl-init',
          '        $name = ${pascal}DomainImpl(),',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-fields',
          '// GENERATOR:END domain-impl-fields',
          '  @override\n  final ${pascal}DomainImpl $name;',
        );
        return updated;
      },
      'packages/dart_sysinfo/lib/src/testing/fake_sys_info.dart': (content) {
        var updated = insertAlphabeticallyInBlock(
          content,
          '// GENERATOR:BEGIN fake-imports',
          '// GENERATOR:END fake-imports',
          "import 'package:dart_sysinfo/src/testing/fake_${name}_domain.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN fake-ctor-params',
          '// GENERATOR:END fake-ctor-params',
          '    Fake${pascal}Domain? $name,',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN fake-ctor-init',
          '// GENERATOR:END fake-ctor-init',
          '        $name = $name ?? Fake${pascal}Domain(),',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN fake-fields',
          '// GENERATOR:END fake-fields',
          '  @override\n  final Fake${pascal}Domain $name;',
        );
        return updated;
      },
      'packages/dart_sysinfo/test/support/mock_rust_lib_api.dart': (content) {
        var updated = insertAlphabeticallyInBlock(
          content,
          '// GENERATOR:BEGIN mock-imports',
          '// GENERATOR:END mock-imports',
          "import 'package:dart_sysinfo/src/bridge/api/$name.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN mock-ctor-params',
          '// GENERATOR:END mock-ctor-params',
          '    ${pascal}InfoDto? ${n.mockSnapshotResultField},',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN mock-ctor-init',
          '// GENERATOR:END mock-ctor-init',
          '        ${n.mockSnapshotResultField} =\n'
          '            ${n.mockSnapshotResultField} ??\n'
          '            const ${pascal}InfoDto(placeholder: \'mock\'),',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN mock-fields',
          '// GENERATOR:END mock-fields',
          '  ${pascal}InfoDto ${n.mockSnapshotResultField};\n'
          '  int ${n.mockSnapshotCallsField} = 0;',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN mock-methods',
          '// GENERATOR:END mock-methods',
          '  @override\n'
          '  ${pascal}InfoDto ${n.crateApiSnapshot}() {\n'
          '    ${n.mockSnapshotCallsField}++;\n'
          '    return ${n.mockSnapshotResultField};\n'
          '  }',
        );
        if (n.hasStream) {
          updated = insertAlphabeticallyInBlock(
            updated,
            '// GENERATOR:BEGIN mock-stream-ctor-params',
            '// GENERATOR:END mock-stream-ctor-params',
            '    StreamController<${pascal}StreamSampleDto>? '
            '${n.mockStreamControllerField},',
          );
          updated = insertAlphabeticallyInBlock(
            updated,
            '// GENERATOR:BEGIN mock-stream-ctor-init',
            '// GENERATOR:END mock-stream-ctor-init',
            '        ${n.mockStreamControllerField} = '
            '${n.mockStreamControllerField} ??\n'
            '            StreamController<${pascal}StreamSampleDto>.broadcast(),',
          );
          updated = insertAlphabeticallyInBlock(
            updated,
            '// GENERATOR:BEGIN mock-stream-fields',
            '// GENERATOR:END mock-stream-fields',
            '  final StreamController<${pascal}StreamSampleDto> '
            '${n.mockStreamControllerField};\n'
            '  int ${n.mockStreamCallsField} = 0;\n'
            '  BigInt? ${n.mockLastIntervalField};',
          );
          updated = insertAlphabeticallyInBlock(
            updated,
            '// GENERATOR:BEGIN mock-stream-methods',
            '// GENERATOR:END mock-stream-methods',
            '  @override\n'
            '  Stream<${pascal}StreamSampleDto> ${n.crateApiStream}({\n'
            '    required BigInt intervalMs,\n'
            '  }) {\n'
            '    ${n.mockStreamCallsField}++;\n'
            '    ${n.mockLastIntervalField} = intervalMs;\n'
            '    return ${n.mockStreamControllerField}.stream;\n'
            '  }',
          );
        }
        return updated;
      },
      'docs/capability-matrix.md': (content) => _patchCapabilityMatrix(content),
    };
  }

  String _patchCapabilityMatrix(String content) {
    const capabilityBegin = '<!-- GENERATOR:BEGIN p2-capability-rows -->';
    const capabilityEnd = '<!-- GENERATOR:END p2-capability-rows -->';
    const permissionBegin = '<!-- GENERATOR:BEGIN p2-permission-rows -->';
    const permissionEnd = '<!-- GENERATOR:END p2-permission-rows -->';

    final name = naming.name;
    final streamColumn = naming.hasStream
        ? '`$name.${naming.streamMethod}()` (scaffold)'
        : 'none';
    final intervalColumn = naming.hasStream
        ? '200 ms mobile / 50 ms desktop (scaffold)'
        : '—';
    final capabilityRow =
        '| `$name` | ${naming.ttlMs} ms | $streamColumn | $intervalColumn | '
        'Android, iOS, macOS, Linux, Windows | TBD | TBD — scaffold placeholder |';

    var updated = insertAlphabeticallyInBlock(
      content,
      capabilityBegin,
      capabilityEnd,
      capabilityRow,
    );

    updated = insertAlphabeticallyInBlock(
      updated,
      permissionBegin,
      permissionEnd,
      '| `$name` | **TBD** | TBD — fill when domain ships |',
    );

    return updated;
  }
}
