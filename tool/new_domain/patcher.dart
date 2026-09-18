/// Surgical edits to existing repo files for new domain wiring.
library;

import 'naming.dart';

class DomainPatcher {
  DomainPatcher(this.naming);

  final DomainNaming naming;

  static final _assignmentStart = RegExp(
    r'^\s*:?\s*[A-Za-z_][A-Za-z0-9_]*\s*=',
  );

  String insertAlphabeticallyInBlock(
    String content,
    String beginMarker,
    String endMarker,
    String newEntry, {
    BlockKind kind = BlockKind.lines,
  }) {
    final beginIndex = content.indexOf(beginMarker);
    final endIndex = content.indexOf(endMarker);
    if (beginIndex == -1 || endIndex == -1 || endIndex <= beginIndex) {
      throw StateError('Missing markers: $beginMarker / $endMarker');
    }

    final blockStart = beginIndex + beginMarker.length;
    final blockContent = content.substring(blockStart, endIndex);
    final entries = _parseEntries(blockContent, kind);
    final incoming = _splitEntryLines(newEntry);

    if (entries.any((entry) => _sameEntry(entry, incoming))) {
      throw StateError('Line already present in block: $newEntry');
    }

    entries.add(incoming);
    entries.sort(
      (a, b) => _sortKey(a, kind).compareTo(_sortKey(b, kind)),
    );

    final rebuilt = _renderEntries(entries, kind);
    return content.replaceRange(blockStart, endIndex, rebuilt);
  }

  /// Makes chained initializer blocks a single valid Dart initializer list.
  ///
  /// Every entry except the last ends with `,`. The last entry ends with `;`.
  /// Stray `,` / `;` lines after the final END marker are removed.
  String normalizeChainedInitializerBlocks(
    String content,
    List<(String begin, String end)> blocks,
  ) {
    final parsed = <({
      String begin,
      String end,
      int blockStart,
      int endIndex,
      List<List<String>> entries,
    })>[];

    for (final (begin, end) in blocks) {
      final beginIndex = content.indexOf(begin);
      final endIndex = content.indexOf(end);
      if (beginIndex == -1 || endIndex == -1 || endIndex <= beginIndex) {
        throw StateError('Missing markers: $begin / $end');
      }
      final blockStart = beginIndex + begin.length;
      parsed.add((
        begin: begin,
        end: end,
        blockStart: blockStart,
        endIndex: endIndex,
        entries: _parseEntries(
          content.substring(blockStart, endIndex),
          BlockKind.initializer,
        ),
      ));
    }

    final allEntries = [
      for (final block in parsed) ...block.entries,
    ];
    if (allEntries.isEmpty) {
      return content;
    }

    var next = content;
    var offset = 0;
    var remaining = allEntries.length;
    for (final block in parsed) {
      final rendered = _renderInitializerEntries(
        block.entries,
        lastTerminator: remaining == block.entries.length ? ';' : ',',
      );
      remaining -= block.entries.length;
      next = next.replaceRange(
        block.blockStart + offset,
        block.endIndex + offset,
        rendered,
      );
      offset += rendered.length - (block.endIndex - block.blockStart);
    }

    return _stripTrailingPunctuationAfter(
      next,
      parsed.last.end,
    );
  }

  String normalizeInitializerBlock(
    String content,
    String beginMarker,
    String endMarker,
  ) {
    return normalizeChainedInitializerBlocks(content, [
      (beginMarker, endMarker),
    ]);
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
          '// GENERATOR:BEGIN domain-exports',
          '// GENERATOR:END domain-exports',
          "export 'src/domains/$name/${name}_info.dart';",
        );
        if (n.hasStream) {
          updated = insertAlphabeticallyInBlock(
            updated,
            '// GENERATOR:BEGIN domain-exports',
            '// GENERATOR:END domain-exports',
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
          "import 'package:dart_sysinfo/src/domains/$name/"
          "${name}_domain.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-imports',
          '// GENERATOR:END domain-impl-imports',
          "import 'package:dart_sysinfo/src/domains/$name/"
          "${name}_domain_impl.dart';",
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-getters',
          '// GENERATOR:END domain-getters',
          '  /// $pascal metrics namespace.\n'
          '  ${pascal}Domain get $name;',
          kind: BlockKind.docMembers,
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-init',
          '// GENERATOR:END domain-impl-init',
          '        $name = ${pascal}DomainImpl()',
          kind: BlockKind.initializer,
        );
        updated = normalizeInitializerBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-init',
          '// GENERATOR:END domain-impl-init',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN domain-impl-fields',
          '// GENERATOR:END domain-impl-fields',
          '  @override\n  final ${pascal}DomainImpl $name;',
          kind: BlockKind.overrideFields,
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
          '        $name = $name ?? Fake${pascal}Domain()',
          kind: BlockKind.initializer,
        );
        updated = normalizeInitializerBlock(
          updated,
          '// GENERATOR:BEGIN fake-ctor-init',
          '// GENERATOR:END fake-ctor-init',
        );
        updated = insertAlphabeticallyInBlock(
          updated,
          '// GENERATOR:BEGIN fake-fields',
          '// GENERATOR:END fake-fields',
          '  @override\n  final Fake${pascal}Domain $name;',
          kind: BlockKind.overrideFields,
        );
        return updated;
      },
      'packages/dart_sysinfo/test/support/mock_rust_lib_api.dart':
          (content) {
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
          "            const ${pascal}InfoDto(placeholder: 'mock')",
          kind: BlockKind.initializer,
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
          kind: BlockKind.overrideFields,
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
            '        ${n.mockStreamControllerField} =\n'
            '            ${n.mockStreamControllerField} ??\n'
            '            StreamController<'
            '${pascal}StreamSampleDto>.broadcast()',
            kind: BlockKind.initializer,
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
            kind: BlockKind.overrideFields,
          );
        }
        return normalizeChainedInitializerBlocks(updated, [
          (
            '// GENERATOR:BEGIN mock-ctor-init',
            '// GENERATOR:END mock-ctor-init',
          ),
          (
            '// GENERATOR:BEGIN mock-stream-ctor-init',
            '// GENERATOR:END mock-stream-ctor-init',
          ),
        ]);
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
        'Android, iOS, macOS, Linux, Windows | TBD | '
        'TBD — scaffold placeholder |';

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

  List<List<String>> _parseEntries(String block, BlockKind kind) {
    final rawLines = block
        .split('\n')
        .map((line) => line.trimRight())
        .toList();
    final lines = rawLines
        .where((line) => line.trim().isNotEmpty)
        .where((line) => !RegExp(r'^\s*[,;]\s*$').hasMatch(line))
        .toList();
    if (lines.isEmpty) {
      return [];
    }

    switch (kind) {
      case BlockKind.lines:
        return [for (final line in lines) [line]];
      case BlockKind.initializer:
        return _parseInitializerEntries(lines);
      case BlockKind.docMembers:
      case BlockKind.overrideFields:
        return _parseMemberEntries(lines);
    }
  }

  List<List<String>> _parseInitializerEntries(List<String> lines) {
    final entries = <List<String>>[];
    var current = <String>[];
    for (final line in lines) {
      if (_assignmentStart.hasMatch(line) && current.isNotEmpty) {
        entries.add(current);
        current = [line];
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) {
      entries.add(current);
    }
    return [
      for (final entry in entries) _stripTrailingPunctuation(entry),
    ];
  }

  List<List<String>> _parseMemberEntries(List<String> lines) {
    final entries = <List<String>>[];
    var current = <String>[];
    for (final line in lines) {
      final trimmed = line.trimLeft();
      final startsMember = trimmed.startsWith('///') ||
          trimmed.startsWith('@override') ||
          trimmed.startsWith('final ') ||
          trimmed.startsWith('Stream<') ||
          (trimmed.contains(' get ') && trimmed.endsWith(';')) ||
          (current.isEmpty && !trimmed.startsWith('///'));
      if (startsMember &&
          current.isNotEmpty &&
          !current.last.trimLeft().startsWith('///') &&
          !current.last.trimLeft().startsWith('@override')) {
        entries.add(current);
        current = [line];
      } else if (trimmed.startsWith('///') &&
          current.isNotEmpty &&
          !current.last.trimLeft().startsWith('///')) {
        entries.add(current);
        current = [line];
      } else if (trimmed.startsWith('@override') &&
          current.isNotEmpty &&
          !current.last.trimLeft().startsWith('///')) {
        entries.add(current);
        current = [line];
      } else {
        current.add(line);
      }
    }
    if (current.isNotEmpty) {
      entries.add(current);
    }
    return entries;
  }

  String _renderEntries(List<List<String>> entries, BlockKind kind) {
    switch (kind) {
      case BlockKind.initializer:
        return _renderInitializerEntries(entries, lastTerminator: ';');
      case BlockKind.lines:
        return '\n${[for (final e in entries) e.join('\n')].join('\n')}\n';
      case BlockKind.docMembers:
      case BlockKind.overrideFields:
        return '\n${[
          for (final e in entries) e.join('\n'),
        ].join('\n\n')}\n';
    }
  }

  String _renderInitializerEntries(
    List<List<String>> entries, {
    required String lastTerminator,
  }) {
    if (entries.isEmpty) {
      return '\n';
    }
    final chunks = <String>[];
    for (var i = 0; i < entries.length; i++) {
      final terminator = i == entries.length - 1 ? lastTerminator : ',';
      final aligned = _alignInitializerColon(entries[i], leadingColon: i == 0);
      chunks.add(_applyTerminator(aligned, terminator).join('\n'));
    }
    return '\n${chunks.join('\n')}\n';
  }

  List<String> _alignInitializerColon(
    List<String> entry, {
    required bool leadingColon,
  }) {
    final first = entry.first;
    final match = RegExp(r'^(\s*):?\s*(.*)$').firstMatch(first);
    if (match == null) {
      return entry;
    }
    final rest = match.group(2)!;
    final alignedFirst = leadingColon ? '      : $rest' : '        $rest';
    return [alignedFirst, ...entry.skip(1)];
  }

  List<String> _applyTerminator(List<String> entry, String terminator) {
    final cleaned = _stripTrailingPunctuation(entry);
    final last = cleaned.last;
    return [...cleaned.sublist(0, cleaned.length - 1), '$last$terminator'];
  }

  List<String> _stripTrailingPunctuation(List<String> entry) {
    final last = entry.last.replaceFirst(RegExp(r'[,;]+\s*$'), '');
    return [...entry.sublist(0, entry.length - 1), last];
  }

  String _stripTrailingPunctuationAfter(String content, String endMarker) {
    final index = content.indexOf(endMarker);
    if (index == -1) {
      return content;
    }
    final after = index + endMarker.length;
    final rest = content.substring(after);
    final stripped = rest.replaceFirst(RegExp(r'^\s*[,;][ \t]*\n'), '\n');
    return content.substring(0, after) + stripped;
  }

  List<String> _splitEntryLines(String entry) {
    return entry
        .split('\n')
        .map((line) => line.trimRight())
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  bool _sameEntry(List<String> a, List<String> b) {
    return a.map((l) => l.trim()).join('\n') ==
        b.map((l) => l.trim()).join('\n');
  }

  String _sortKey(List<String> entry, BlockKind kind) {
    final joined = entry.join(' ');
    if (kind == BlockKind.initializer) {
      final match = RegExp(r':?\s*([A-Za-z_][A-Za-z0-9_]*)\s*=').firstMatch(
        joined,
      );
      return match?.group(1) ?? joined.trim();
    }
    final getter = RegExp(r'\bget\s+([A-Za-z_][A-Za-z0-9_]*)').firstMatch(
      joined,
    );
    if (getter != null) {
      return getter.group(1)!;
    }
    final field = RegExp(
      r'\bfinal\s+\S+\s+([A-Za-z_][A-Za-z0-9_]*)',
    ).firstMatch(joined);
    if (field != null) {
      return field.group(1)!;
    }
    return entry.first.trim();
  }
}

enum BlockKind {
  lines,
  initializer,
  docMembers,
  overrideFields,
}
