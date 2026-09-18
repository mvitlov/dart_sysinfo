# Contributing to dart_sysinfo

Thank you for contributing. **EPIC-M0, EPIC-M1, and EPIC-M2 are complete** — the
repo ships P1 domains (OS, CPU, memory), lifecycle glue, testing fakes, a P1 CI
gate, and the parallel Native Assets track (build hook, CI matrix, sunset clock).
Release automation, P2 domains, and domain-checklist CI land in M3/M4 (see notes
below). **Next milestone options:** **M3** (disks/network + generator) or **M5**
(Native Assets default, after PRD §3.3 sunset criterion).

## Governing documents

Requirements and implementation detail live in three docs, in order of authority:

1. [`PRD.md`](./PRD.md) — approved requirements and architecture
2. [`TDD.md`](./TDD.md) — implementation detail (M0–M2 complete; M3+ stubbed)
3. [`EPICS.md`](./EPICS.md) — milestone stories sized for tracker issues
4. [`docs/capability-matrix.md`](./docs/capability-matrix.md) — P1 capability +
   Android permission rows (M1-13)
5. [`docs/apple-store-profile.md`](./docs/apple-store-profile.md) — Apple
   `apple-app-store` build profile stub (M1-14)
6. [`docs/example-app-qa.md`](./docs/example-app-qa.md) — example app hot-restart
   manual QA checklist (M1-16)

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

Flutter lifecycle package tests:

```bash
cd packages/dart_sysinfo_flutter && fvm flutter test
```

Example app (P1 demo + optional hot-restart QA):

```bash
cd example && fvm flutter run -d macos
# optional log-friendly QA mode — see docs/example-app-qa.md
fvm flutter run -d macos --dart-define=QA_AUTO_START=true
```

Rust integration tests (M1-15):

```bash
cd packages/native && cargo test -- --test-threads=1
```

Rust store-profile verification (M1-14):

```bash
cd packages/native && cargo test --features apple-app-store --test apple_app_store -- --test-threads=1
```

## Native Assets hook (M2)

The Native Assets build hook in `packages/dart_sysinfo/hook/build.dart` is **always-on**
during Flutter builds: it compiles `packages/native` in parallel with Cargokit.
Runtime loading still uses Cargokit until M5.

The hook **no-ops** when `rustup` is not available (Flutter-free `dart pub get` /
`dart test`) or when `DART_SYSINFO_SKIP_NATIVE_ASSETS_HOOK=1` is set. CI sets the
latter in `dart-only-test`.

Verify locally (macOS or Linux):

```bash
fvm dart pub get
cd example && fvm flutter build macos --debug   # or linux --debug
bash tool/ci/verify_native_assets.sh macos      # or linux / android / ...
# Expect native_assets output, e.g.:
# example/build/.../native_assets/dart_sysinfo_native.framework/...
fvm dart run melos doctor   # Backend consistency: dual-backend OK
```

## Native Assets CI (M2-02)

[`.github/workflows/ci.yaml`](./.github/workflows/ci.yaml) defines a parallel
**`native-assets`** job that mirrors the 9-cell `flutter-build` matrix (same
Flutter SDK tiers and platforms). Each cell runs `flutter build` on `example/`
and then `tool/ci/verify_native_assets.sh` to assert a `dart_sysinfo_native`
Native Assets artifact exists under `example/build/.../native_assets/`.

**Merge policy:** `native-assets` is **not** wired into `m0-exit-gate` (PRD
§7.2). A red Native Assets cell on a PR does not block merges.

## Sunset clock (M2-03)

Weekly scheduled workflow
[`Native Assets Sunset Clock (PRD §3.3)`](.github/workflows/native-assets-sunset-clock.yaml)
runs the same 9-cell Native Assets matrix on `main` every Monday 06:00 UTC and
records pass/fail in [`docs/sunset-clock/history.jsonl`](docs/sunset-clock/README.md).

```bash
bash tool/ci/sunset_clock_report.sh
gh run list --workflow="Native Assets Sunset Clock (PRD §3.3)" --limit 20
gh workflow run "Native Assets Sunset Clock (PRD §3.3)"
```

See [`docs/sunset-clock/README.md`](docs/sunset-clock/README.md) for streak
semantics (scheduled samples only) and JSONL schema.

## CI / P1 merge gate (PRD §7.2)

Pull requests must pass the **`M1 P1 CI gate (PRD §7.2)`** check in
[`.github/workflows/ci.yaml`](./.github/workflows/ci.yaml). The job id is still
`m0-exit-gate` for branch-protection compatibility. It aggregates:

- **Flutter-free tests** — `dart-only-test` (3 Dart SDK tiers)
- **Lint** — `dart analyze --fatal-warnings` on latest Flutter (PRD §10.1)
- **Flutter builds** — `flutter-build` (9 cells; see SDK matrix below)
- **Rust tests** — `rust-test` (`cargo test -- --test-threads=1`)

Parallel (non-blocking): **`native-assets`** (9 cells; same matrix as
`flutter-build` with post-build Native Assets verification) and weekly
**`Native Assets Sunset Clock`** (records §3.3 evidence; also non-blocking).

**SDK matrix (PRD §7.2 / §1.5):**

| Tier | Flutter (`flutter-build`) | Dart (`dart-only-test`) | Platforms built |
|---|---|---|---|
| Minimum | 3.38.1 | `dart:3.10.0` | Android, Linux (spot-check) |
| Intermediate | 3.44.0 | `dart:3.12.2` | Android, Linux (spot-check) |
| Latest | 3.47.4 | `dart:3.13.3` | All 5 (Android, iOS, Linux, macOS, Windows) |

This yields **9** `flutter-build` cells and **3** `dart-only-test` cells per CI
run. Min/intermediate tiers spot-check mobile + desktop Unix on Ubuntu; latest
tier runs the full five-platform matrix. iOS/macOS/Windows compile paths are
covered on the latest SDK only.

**Note:** CI uses Flutter **3.38.1** (not 3.38.0) for the minimum tier because
3.38.0 shipped a Dart beta that does not satisfy `sdk: >=3.10.0 <4.0.0`.

**CI safeguards:**

- `concurrency.cancel-in-progress` — superseded runs on the same branch are
  cancelled instead of piling up
- `timeout-minutes` on every job — prevents hung workflows from running
  indefinitely
- Explicit `flutter-build` matrix `include` list — avoids ambiguous GitHub
  Actions matrix expansion
- Platform-scoped Rust targets + `Swatinem/rust-cache` — faster native builds

**Policy:** configure `m0-exit-gate` as a required status check in GitHub
branch protection for `main` (repository admin setting).

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

## Manual QA (M1)

The example app includes a manual hot-restart checklist required by TDD §5.2 and
EPIC-M1 story M1-16. See [`docs/example-app-qa.md`](./docs/example-app-qa.md)
for the full procedure and sign-off table.

Run from `example/`:

```bash
fvm flutter run -d macos
```

Start the CPU load stream, hot restart (`R`), and confirm tick rate stays ~1/sec
(not ~2/sec) after each cycle.

## Domain checklist (deferred — PRD §10.2)

Domain completeness checks (capability-matrix row, permission row, testing fake,
unit tests for every domain folder) and the `tool/new_domain.dart` generator are
**not part of M0**. They land in **M3**, extracted from the hand-built M1 domain
pattern. Do not add per-domain checklist rows here until that milestone — see
[`EPICS.md`](./EPICS.md) EPIC-M3.
