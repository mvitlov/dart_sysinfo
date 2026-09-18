# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Native Assets build hook (`hook/build.dart`) via `flutter_rust_bridge_hooks`
  (M2-01; compiles `packages/native` in parallel with Cargokit).
- P1 domains: OS, CPU, and memory snapshots with TTL caching.
- CPU load stream (`cpu.load`) with broadcast, ref-count, and interval clamping.
- `Reading<T>` sealed type and `SysInfoException` hierarchy.
- `SysInfo` singleton with `disposeInstance`, `prepareFreshIsolate`, and test hooks.
- `package:dart_sysinfo/testing.dart` fakes for all P1 domains.
- `dart run dart_sysinfo:doctor` toolchain diagnostics (from M0).

### Changed

- Example app upgraded from FFI smoke test to P1 domain demo with hot-restart QA.

### Documentation

- P1 capability matrix (`docs/capability-matrix.md`).
- Apple store-profile stub docs (`docs/apple-store-profile.md`).
- Example app manual QA checklist (`docs/example-app-qa.md`).
