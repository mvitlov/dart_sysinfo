import 'package:dart_sysinfo/src/doctor/doctor_check.dart';
import 'package:dart_sysinfo/src/doctor/doctor_context.dart';
import 'package:dart_sysinfo/src/doctor/doctor_result.dart';
import 'package:dart_sysinfo/src/doctor/rust_toolchain_config.dart';

/// Verifies Rust toolchain version and cross-compile targets (TDD §6).
class RustToolchainCheck implements DoctorCheck {
  const RustToolchainCheck();

  @override
  String get name => 'Rust toolchain';

  @override
  Future<DoctorResult> run(DoctorContext context) async {
    final config = RustToolchainConfig.parseFile(context.rustToolchainFile);
    if (config == null) {
      return DoctorResult(
        ok: false,
        summary:
            'rust-toolchain.toml not found at ${context.rustToolchainFile}',
        fixCommand:
            'git checkout packages/native/rust-toolchain.toml  # restore pinned toolchain file',
      );
    }

    final pinnedChannel = config.channel;

    final rustcResult = await context.processRunner.run('rustc', [
      '--version',
    ]);
    if (rustcResult.exitCode != 0) {
      return const DoctorResult(
        ok: false,
        summary: 'rustc not found on PATH',
        fixCommand:
            "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh",
      );
    }

    final rustcVersion = _parseRustcVersion(rustcResult.stdout.toString());
    if (rustcVersion == null) {
      return DoctorResult(
        ok: false,
        summary:
            'Could not parse rustc version from: ${rustcResult.stdout}',
        fixCommand:
            'rustup toolchain install $pinnedChannel && rustup default $pinnedChannel',
      );
    }

    if (rustcVersion != pinnedChannel) {
      return DoctorResult(
        ok: false,
        summary:
            'Rust toolchain: found $rustcVersion, expected $pinnedChannel',
        fixCommand:
            'rustup toolchain install $pinnedChannel && rustup default $pinnedChannel',
      );
    }

    final targetsResult = await context.processRunner.run('rustup', [
      'target',
      'list',
      '--installed',
    ]);
    if (targetsResult.exitCode != 0) {
      return DoctorResult(
        ok: false,
        summary: 'rustup target list failed',
        fixCommand:
            'rustup toolchain install $pinnedChannel && rustup default $pinnedChannel',
      );
    }

    final installed = targetsResult.stdout
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toSet();

    final missing =
        config.targets.where((target) => !installed.contains(target)).toList();
    if (missing.isNotEmpty) {
      return DoctorResult(
        ok: false,
        summary:
            'Missing ${missing.length} rustup target(s): ${missing.join(', ')}',
        fixCommand: 'rustup target add ${missing.join(' ')}',
      );
    }

    return DoctorResult(
      ok: true,
      summary:
          'Rust toolchain $pinnedChannel installed; all ${config.targets.length} targets present',
    );
  }

  String? _parseRustcVersion(String output) {
    final match = RegExp(r'rustc (\d+\.\d+\.\d+)').firstMatch(output);
    return match?.group(1);
  }
}
