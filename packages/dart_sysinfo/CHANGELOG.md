# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Domain scaffolding generator `tool/new_domain.dart` (M3-01): templates,
  integration patches, and `melos new-domain` script; see TDD §9.1.
- Native Assets build hook (`hook/build.dart`) via `flutter_rust_bridge_hooks`
  (M2-01; compiles `packages/native` in parallel with Cargokit).
- Parallel `native-assets` CI job (M2-02) mirroring the 9-cell `flutter-build`
  matrix with post-build artifact verification via `tool/ci/verify_native_assets.sh`.
- Sunset-clock automation (M2-03): weekly scheduled workflow records Native Assets
  matrix results to `docs/sunset-clock/history.jsonl`; `tool/ci/sunset_clock_report.sh`
  reports consecutive green weeks for PRD §3.3.
- P1 domains: OS, CPU, and memory snapshots with TTL caching.
- CPU load stream (`cpu.load`) with broadcast, ref-count, and interval clamping.
- `Reading<T>` sealed type and `SysInfoException` hierarchy.
- `SysInfo` singleton with `disposeInstance`, `prepareFreshIsolate`, and test hooks.
- `package:dart_sysinfo/testing.dart` fakes for all P1 domains.
- `dart run dart_sysinfo:doctor` toolchain diagnostics (from M0).

### Changed

- Example app upgraded from FFI smoke test to P1 domain demo with hot-restart QA.

### Documentation

- M2 milestone sign-off: PRD, EPICS, CONTRIBUTING, and agent rules synced.
- P1 capability matrix (`docs/capability-matrix.md`).
- Apple store-profile stub docs (`docs/apple-store-profile.md`).
- Example app manual QA checklist (`docs/example-app-qa.md`).
