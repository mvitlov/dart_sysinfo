import 'dart:io';

/// Parsed contents of `packages/native/rust-toolchain.toml`.
class RustToolchainConfig {
  const RustToolchainConfig({
    required this.channel,
    required this.targets,
  });

  final String channel;
  final List<String> targets;

  static RustToolchainConfig? parseFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      return null;
    }
    return parse(file.readAsStringSync());
  }

  static RustToolchainConfig? parse(String content) {
    final channelMatch = RegExp(
      r'channel\s*=\s*"([^"]+)"',
    ).firstMatch(content);
    if (channelMatch == null) {
      return null;
    }

    final targets = <String>[];
    final inTargets = RegExp(r'targets\s*=\s*\[').firstMatch(content);
    if (inTargets != null) {
      final afterBracket = content.substring(inTargets.end);
      final targetPattern = RegExp('"([^"]+)"');
      for (final match in targetPattern.allMatches(afterBracket)) {
        final value = match.group(1)!;
        if (value.contains('-')) {
          targets.add(value);
        }
      }
    }

    return RustToolchainConfig(
      channel: channelMatch.group(1)!,
      targets: targets,
    );
  }
}
