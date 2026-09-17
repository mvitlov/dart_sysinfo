# Contributing to dart_sysinfo

Thank you for contributing. This document covers contributor workflow stubs for
the M0 scaffolding phase. Release automation and domain-checklist CI land in
later milestones (see notes below).

## Governing documents

Requirements and implementation detail live in three docs, in order of authority:

1. [`PRD.md`](./PRD.md) — approved requirements and architecture
2. [`TDD.md`](./TDD.md) — implementation detail (M0–M2 complete; M3+ stubbed)
3. [`EPICS.md`](./EPICS.md) — milestone stories sized for tracker issues
4. [`docs/capability-matrix.md`](./docs/capability-matrix.md) — P1 capability +
   Android permission rows (M1-13)
5. [`docs/apple-store-profile.md`](./docs/apple-store-profile.md) — Apple
   `apple-app-store` build profile stub (M1-14)

**Spec-first rule:** new work should map to an existing story in
[`EPICS.md`](./EPICS.md). If it does not, amend the governing docs first rather
than building untracked scope.

## Getting started

### Toolchain

This repo pins Flutter via [FVM](https://fvm.app/) (see [`.fvmrc`](./.fvmrc) —
currently Flutter **3.47.4** / Dart **3.13.3**). Prefer `fvm flutter` /
`fvm dart` over bare commands on `PATH`.

Before debugging native build failures, run setup diagnostics:

```bash
fvm dart run melos doctor
# equivalent: fvm dart run dart_sysinfo:doctor
```

Each failed check prints an exact fix command (PRD §9.1).

### Common commands

From the repository root:

```bash
fvm dart pub get
fvm dart run melos analyze          # zero-warning lint gate (PRD §10.1)
fvm dart run melos frb:generate     # regenerate FRB glue after Rust API changes
```

Flutter-free core tests (no Flutter SDK required):

```bash
cd packages/dart_sysinfo && fvm dart test
```

Rust store-profile verification (M1-14):

```bash
cd packages/native && cargo test --features apple-app-store --test apple_app_store -- --test-threads=1
```

## CI / M0 exit gate (PRD §12)

Pull requests must pass the **`M0 go/no-go exit gate (PRD §12)`** check in
[`.github/workflows/ci.yaml`](./.github/workflows/ci.yaml). That job aggregates:

- **Flutter-free tests** — `dart-only-test` on Flutter-free Dart containers
- **Lint** — `dart analyze --fatal-warnings` (PRD §10.1)
- **Five-platform builds** — `flutter-build` matrix (Android, iOS, Linux,
  macOS, Windows) compiling the example FFI smoke app via Cargokit

**Policy:** a red M0 exit gate blocks M1 kickoff. Configure it as a required
status check in GitHub branch protection for `main` (repository admin setting).

## Pub.dev (M0-12)

**M0-12 is satisfied by a documented deferral**, not a live pub.dev package. See
[`docs/decisions/M0-12-pubdev-deferral.md`](./docs/decisions/M0-12-pubdev-deferral.md)
(owner, decision date, revisit trigger, name-availability snapshot).

- **`dart_sysinfo` and `dart_sysinfo_flutter` are not published yet.**
- First intended **consumer-facing** publish is **M4** (1.0 release).
- Before any publish: re-run the name-availability check in the decision doc and
  follow the **When we publish (M4+)** checklist there.

## Release checklist (PRD §10.3)

Skeletal checklist for maintainers. Automation (ABI diff gate, publish scripts)
lands in **M3/M4**; until then these steps are manual.

- [ ] **Pre-flight:** Run `fvm dart run melos doctor`; confirm CI is green on
  the release branch.
- [ ] **Dart version bump:** Run `fvm dart run melos version` — lockstep bump
  for `dart_sysinfo` and `dart_sysinfo_flutter` ([`pubspec.yaml`](./pubspec.yaml)
  `melos.command.version.mode: fixed`).
- [ ] **Dependency pin:** Ensure
  [`packages/dart_sysinfo_flutter/pubspec.yaml`](./packages/dart_sysinfo_flutter/pubspec.yaml)
  pins an exact matching `dart_sysinfo` version (same semver as the core
  package).
- [ ] **Changelogs:** Move `[Unreleased]` entries into a dated version section in
  both [`packages/dart_sysinfo/CHANGELOG.md`](./packages/dart_sysinfo/CHANGELOG.md)
  and
  [`packages/dart_sysinfo_flutter/CHANGELOG.md`](./packages/dart_sysinfo_flutter/CHANGELOG.md)
  (Keep a Changelog format, PRD §9.3).
- [ ] **Native / ABI:** If `packages/native/src/api/` or FRB-generated glue
  changed native layout or signatures, bump `DART_SYSINFO_ABI` in
  [`packages/native/src/abi.rs`](./packages/native/src/abi.rs). The Dart
  packages version and native ABI bump **independently** — only bump ABI on
  breaking native-layout changes (PRD §7.3, §10.3). **ABI diff CI gate: manual
  until M3.**
- [ ] **FRB regen:** If the Rust public API surface changed, run
  `fvm dart run melos frb:generate` and commit generated bridge files.
- [ ] **Verify:** Run `fvm dart run melos analyze`; `fvm dart test` in
  `packages/dart_sysinfo`; confirm platform smoke builds pass in CI.
- [ ] **Tag:** Create a git tag (melos `workspaceTag: true` assists lockstep
  tagging).
- [ ] **Publish:** Publish `dart_sysinfo` and `dart_sysinfo_flutter` to pub.dev
  (M4 1.0). See [M0-12 pub.dev deferral](./docs/decisions/M0-12-pubdev-deferral.md)
  for pre-publish checks; M0-12 name reservation is deferral-only, not a live package.

## Deprecation policy (PRD §10.4)

Public API evolution follows these rules:

- Deprecated symbols are annotated with
  `@Deprecated('use X instead; removed in vN.0.0')`.
- Deprecated symbols remain **functional for at least two minor releases** before
  removal in the next **major** version.
- Breaking changes in the upstream `sysinfo` Rust crate are **absorbed inside
  the Rust shim** whenever feasible, so they do not reach the Dart API. Only
  when the shim cannot paper over an upstream break is the change forwarded to
  Dart consumers — and then only as a documented deprecation or major-version
  change, never a silent behavior shift.

Example annotation:

```dart
@Deprecated('Use newMethod() instead; removed in v2.0.0')
Future<void> oldMethod() => newMethod();
```

## Domain checklist (deferred — PRD §10.2)

Domain completeness checks (capability-matrix row, permission row, testing fake,
unit tests for every domain folder) and the `tool/new_domain.dart` generator are
**not part of M0**. They land in **M3**, extracted from the hand-built M1 domain
pattern. Do not add per-domain checklist rows here until that milestone — see
[`EPICS.md`](./EPICS.md) EPIC-M3.
