/// Domain name normalization for the M3-01 scaffolding generator.
library;

const existingDomains = {'cpu', 'disks', 'memory', 'network', 'os'};

/// Validated domain naming derived from CLI input.
class DomainNaming {
  DomainNaming({
    required this.name,
    required this.pascal,
    required this.title,
    required this.ttlMs,
    required this.hasStream,
    required this.streamMethod,
  }) : streamMethodPascal = _pascalize(streamMethod);

  final String name;
  final String pascal;
  final String title;
  final int ttlMs;
  final bool hasStream;
  final String streamMethod;
  final String streamMethodPascal;

  String get dartPrefix => _camelCase(name);

  String get snapshotFnDart => '${dartPrefix}Snapshot';
  String get snapshotFnRust => '${name}_snapshot';

  String get streamFnDart => '$dartPrefix${streamMethodPascal}Stream';
  String get streamFnRust => '${name}_${streamMethod}_stream';

  String get domainStreamKey => '$name.$streamMethod';

  String get crateApiSnapshot => 'crateApi$pascal${pascal}Snapshot';

  String get crateApiStream =>
      'crateApi$pascal$pascal${streamMethodPascal}Stream';

  String get mockSnapshotResultField => '${name}SnapshotResult';
  String get mockSnapshotCallsField => '${name}SnapshotCalls';
  String get mockStreamCallsField => '${name}${streamMethodPascal}StreamCalls';
  String get mockStreamControllerField =>
      '${name}${streamMethodPascal}StreamController';
  String get mockLastIntervalField => 'last${streamMethodPascal}IntervalMs';

  static DomainNaming parse({
    required String rawName,
    required int ttlMs,
    required bool hasStream,
    required String streamMethod,
  }) {
    final name = rawName.trim().toLowerCase();
    _validateName(name);
    if (existingDomains.contains(name)) {
      throw FormatException('Domain "$name" already exists');
    }
    if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
      throw FormatException(
        'Invalid domain name "$rawName" (expected lowercase [a-z][a-z0-9_]*)',
      );
    }
    if (streamMethod.isEmpty || !RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(streamMethod)) {
      throw FormatException('Invalid stream method "$streamMethod"');
    }
    return DomainNaming(
      name: name,
      pascal: _pascalize(name),
      title: _pascalize(name),
      ttlMs: ttlMs,
      hasStream: hasStream,
      streamMethod: streamMethod,
    );
  }

  static void _validateName(String name) {
    if (name.isEmpty) {
      throw FormatException('Domain name is required');
    }
  }

  static String _pascalize(String value) {
    return value
        .split('_')
        .map(
          (part) => part.isEmpty
              ? ''
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join();
  }

  static String _camelCase(String value) {
    final parts = value.split('_').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) {
      return value;
    }
    final head = parts.first;
    if (parts.length == 1) {
      return head;
    }
    return head + parts.skip(1).map(_pascalize).join();
  }

  static String pascalCase(String value) => _pascalize(value);
}
