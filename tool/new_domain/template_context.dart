/// Token map for `{{token}}` template substitution.
library;

import 'naming.dart';

class TemplateContext {
  TemplateContext(this.naming);

  final DomainNaming naming;

  Map<String, String> toTokens() {
    final n = naming;
    return {
      'name': n.name,
      'Pascal': n.pascal,
      'Title': n.title,
      'ttlMs': '${n.ttlMs}',
      'streamMethod': n.streamMethod,
      'streamMethodPascal': n.streamMethodPascal,
      'snapshotFnDart': n.snapshotFnDart,
      'snapshotFnRust': n.snapshotFnRust,
      'streamFnDart': n.streamFnDart,
      'streamFnRust': n.streamFnRust,
      'domainStreamKey': n.domainStreamKey,
      'crateApiSnapshot': n.crateApiSnapshot,
      'crateApiStream': n.crateApiStream,
      'mockSnapshotResultField': n.mockSnapshotResultField,
      'mockSnapshotCallsField': n.mockSnapshotCallsField,
      'mockStreamCallsField': n.mockStreamCallsField,
      'mockStreamControllerField': n.mockStreamControllerField,
      'mockLastIntervalField': n.mockLastIntervalField,
    };
  }

  String render(String template) {
    var output = template;
    for (final entry in toTokens().entries) {
      output = output.replaceAll('{{${entry.key}}}', entry.value);
    }
    return output;
  }
}
