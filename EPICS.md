# Epics & Traceability: `dart_sysinfo`

**Purpose:** bridge from requirements to execution. Every Epic here maps 1:1 to a PRD milestone (`PRD.md` §12) and cites the PRD/TDD sections it implements. Every Story is sized to become **one child issue** in whatever tracker this project ends up using (GitHub Issues, Linear, etc.) — copy a Story row into an issue, keep its ID in the title (e.g. `[M1-06] CPU domain: Rust snapshot + load stream`), and its "Acceptance criteria" column becomes the issue's Definition of Done.

**Traceability rule:** nothing gets built without a Story here, and no Story exists without a PRD §  and (where one exists yet) a TDD § backing it. If work comes up that doesn't trace to either, that's a signal to go amend `PRD.md`/`TDD.md` first, not to silently add a Story.

**Status legend:** ⬜ not started · 🟨 in progress · ✅ done · ⛔ blocked

***

## Traceability overview

| Epic | Milestone | PRD § | TDD § | Status |
|---|---|---|---|---|
| [EPIC-M0](#epic-m0--scaffolding) | M0 | §2.1, §2.5, §7.1, §9.1, §10.1, §12 | §1, §6, §8 | ✅ |
| [EPIC-M1](#epic-m1--p1-domains-os-cpu-memory) | M1 | §3.4, §5.1–§5.6, §6, §8, §12 | §2, §3, §4, §5 | ✅ |
| [EPIC-M2](#epic-m2--native-assets-track) | M2 | §3.3, §7.1, §12 | §7 | ✅ |
| [EPIC-M3](#epic-m3--p2-domains--tooling-hardening) | M3 | §6, §7.2, §7.3, §9.3, §10.2, §10.3, §12 | §9 (stub) | ⬜ |
| [EPIC-M4](#epic-m4--store-hardening--10-release) | M4 | §2.4, §2.5, §3.3, §9.2, §9.3, §10.3, §12 | — | ⬜ |
| [EPIC-M5](#epic-m5--native-assets-default) | M5 | §3.3, §7.4, §12 | — | ⬜ |

Dependency chain is strictly sequential at the Epic level (M0 → M1 → ... → M5); M2's Native Assets track runs *in parallel* with M1/M3 once started but does not block them, per PRD §3.3.

***

## EPIC-M0 — Scaffolding

**Goal:** prove the repo, build wiring, and Flutter-free package split all work — before any domain logic exists. This is a go/no-go gate (PRD §14), not routine setup.

**Definition of done:** all Stories below are ✅, and the M0 exit-criteria CI job (M0-11) has been green at least once on all 5 platforms.

| ID | Title | Status | Area | PRD § | TDD § | Acceptance criteria |
|---|---|---|---|---|---|---|
| M0-01 | Melos monorepo + package split scaffolding | ✅ | Repo | §2.1, §4 | §1.1 | Root `pubspec.yaml` (`workspace:` + `melos:` lockstep config) + `packages/dart_sysinfo`, `packages/dart_sysinfo_flutter`, `packages/native` exist with the directory tree in TDD §1.1 |
| M0-02 | Rust crate skeleton | ✅ | Rust | §2.3, §7.1 | §1.2, §1.3 | `Cargo.toml` (`staticlib`+`cdylib`, feature flags), `rust-toolchain.toml` pinned, targets listed |
| M0-03 | FRB + Cargokit wired as default backend | ✅ | Bridge | §3.3 | §1.1 | `flutter_rust_bridge_codegen generate` runs cleanly; Cargokit builds on all 5 platforms |
| M0-04 | Minimal FFI smoke test | ✅ | Dart/Rust | §12 | §1.4, §8 | Example app makes one round-trip native call and prints the result; no domains exist yet |
| M0-05 | Flutter-free verification CI job | ✅ | CI | §2.1 | §1.4, §8 | CI job on a Flutter-free container runs `dart pub get && dart test` against `dart_sysinfo` and passes |
| M0-06 | Android NDK r28+ / JDK17 CI wiring | ✅ | CI | §2.5, §7.1 | §1.3, §8 | Android CI job installs NDK r28+, builds with JDK 17 |
| M0-07 | Exclude `web` in `pubspec.yaml` `platforms:` | ✅ | Dart | §1.6 | §1.4 | `flutter build web` on a consumer fails fast at dependency resolution, not at runtime |
| M0-08 | Lint baseline (`very_good_analysis`) | ✅ | Repo/CI | §10.1 | §8 | Root `analysis_options.yaml` inherited by all packages; CI fails on any warning |
| M0-09 | `doctor` tool (initial checks) | ✅ | Dart/Tooling | §9.1 | §6 | `dart run dart_sysinfo:doctor` checks Rust toolchain, NDK, Xcode/CocoaPods, backend consistency; each failure prints an exact fix command |
| M0-10 | `CONTRIBUTING.md` stubs | ✅ | Docs | §10.3, §10.4 | — | Release checklist and deprecation-policy sections exist, even if skeletal |
| M0-11 | M0 go/no-go exit-criteria CI gate | ✅ | CI | §12, §14 | §1.4 | A single CI gate aggregates "all 5 platforms build" + "Flutter-free test passes"; red blocks M1 kickoff by policy |
| M0-12 | Reserve `dart_sysinfo` name on pub.dev | ✅ | Release | §9.3, §14 | — | A placeholder version is published (or a documented decision to wait, with an owner and date) |

***

## EPIC-M1 — P1 domains (OS, CPU, Memory)

**Goal:** ship the first real, hand-built domains and every cross-cutting API contract (`Reading<T>`, exceptions, lifecycle, caching, streaming, testability) that every future domain will reuse. Per PRD §10.2, this Epic is deliberately hand-built, not generated — it's what the generator gets extracted from later (EPIC-M3).

**Definition of done:** `dart_sysinfo` 0.x publishable with OS/CPU/Memory snapshots, CPU load stream, full testing fakes, and CI green on min+intermediate+latest SDKs.

**Status:** ✅ complete — all stories below are done; P1 CI gate green on min + intermediate + latest SDKs.

| ID | Title | Status | Area | PRD § | TDD § | Acceptance criteria |
|---|---|---|---|---|---|---|
| M1-01 | `Reading<T>` sealed type | ✅ | Dart | §5.2 | §3.1 | `ReadingValue`/`ReadingUnsupported`/`ReadingUnavailable` + `when`/`maybeWhen`/`orElse`, unit-tested exhaustively |
| M1-02 | `SysInfoException` hierarchy | ✅ | Dart | §5.3 | §3.1 | 4 sealed subtypes exist and are the *only* throwable public errors |
| M1-03 | `SysInfo` base + singleton + testability hooks | ✅ | Dart | §5.6 | §3.2 | `instance`, `resetForTesting()`, `overrideInstance()` implemented and unit-tested per TDD §3.2 |
| M1-04 | Rust shared state (`Mutex<Option<Arc<SharedState>>>`) | ✅ | Rust | §3.4 | §2.1 | `init()`/`dispose()` idempotent; `dispose()` → `init()` re-init verified by test |
| M1-05 | ABI versioning + `AbiGuard` | ✅ | Rust/Dart | §7.3, §5.3 | §2.5, §3.5 | Deliberate ABI mismatch in a test throws `SysInfoAbiMismatchException` with actionable message |
| M1-06 | CPU domain: Rust snapshot + load stream | ✅ | Rust | §6 | §2.2, §2.3, §4.1 | `cpu_snapshot()` and `cpu_load_stream()` implemented per TDD §4.1 field table |
| M1-07 | CPU domain: Dart API | ✅ | Dart | §6 | §3.3, §3.4, §4.1 | `CpuDomain`/`CpuInfo`/`CpuDomainImpl` with TTL cache (500 ms) and clamped stream (200 ms mobile / 50 ms desktop) |
| M1-08 | Memory domain: Rust + Dart | ✅ | Rust/Dart | §6 | §4.2 | All 7 plain fields + `cgroupLimits` (`Reading<CGroupLimits>`) per TDD §4.2 |
| M1-09 | OS domain: Rust + Dart | ✅ | Rust/Dart | §6 | §4.3 | All fields per TDD §4.3, including `loadAverage` `ReadingUnsupported` on Windows |
| M1-10 | `SharedStreamRegistry` (broadcast/ref-count/clamp) | ✅ | Dart | §5.4 | §3.3 | Two listeners on the same interval share one native poller (test asserts single underlying subscription); clamp logs once per domain |
| M1-11 | Concurrency stress test | ✅ | Rust | §3.4, §8 | §2.4 | 8-thread contention test on `RwLock<System>` passes with a 10s deadlock timeout in CI |
| M1-12 | `testing.dart` fakes (cpu/memory/os) | ✅ | Dart | §8 | §5.1 | `FakeSysInfo` + per-domain fakes; each field independently settable; no Flutter/native dependency |
| M1-13 | Capability matrix + Android permission rows (P1) | ✅ | Docs | §2.5, §6 | — | Table in repo docs lists OS/CPU/Memory rows (permissions: none) |
| M1-14 | Apple store-profile stub | ✅ | Rust | §2.4 | — | `apple-app-store` feature flag compiles; CI assertion deferred to M4 |
| M1-15 | CI SDK matrix for P1 | ✅ | CI | §7.2 | §8 | Min + one intermediate + latest Flutter/Dart pairs green |
| M1-16 | Example app: P1 domains + hot-restart manual QA | ✅ | Dart/QA | §3.4, §8 | §5.2 | Manual checklist executed: start `cpu.load` stream → hot restart → no duplicate workers |

***

## EPIC-M2 — Native Assets track

**Goal:** stand up the parallel, CI-gated Native Assets backend so evidence accumulates toward the PRD §3.3 sunset criterion. Runs alongside M1/M3, never blocks them.

**Definition of done:** all Stories below are ✅, the `native-assets` CI matrix has been green at least once, and the sunset-clock workflow has recorded at least one scheduled sample on `main`.

**Status:** ✅ complete — sunset clock is accumulating toward PRD §3.3 bullet 2; Cargokit remains default until M5.

| ID | Title | Status | Area | PRD § | TDD § | Acceptance criteria |
|---|---|---|---|---|---|---|
| M2-01 | `hook/build.dart` via `flutter_rust_bridge_hooks` | ✅ | Bridge | §3.3, §7.1 | §7 | Build hook compiles the Rust crate via `native_toolchain_rust` and registers it as a code asset |
| M2-02 | Native Assets CI job (5-platform matrix) | ✅ | CI | §7.2 | §7, §8 | Parallel job runs the same smoke test as Cargokit; red does not block merges |
| M2-03 | Sunset-clock tracking automation | ✅ | CI/Release | §3.3 | §7 | Each scheduled CI run's pass/fail is queryable, so "green for ≥2 stable releases or ≥8 weeks" is answerable without manual log-keeping |

***

## EPIC-M3 — P2 domains + tooling hardening

**Goal:** extract the domain generator from the now-proven M1 pattern, use it for disks/network, and turn on the quality gates deliberately deferred from M0/M1 (PRD §7.2). Per TDD §9, exact field tables for these domains are **not yet designed** — the first Stories here are about building the *process* (generator), and per-field mapping happens when each domain Story is picked up, following the same method as TDD §4.

| ID | Title | Status | Area | PRD § | TDD § | Acceptance criteria |
|---|---|---|---|---|---|---|
| M3-01 | Extract `tool/new_domain.dart` generator | ✅ | Tooling | §10.2 | §9.1 | Generator produces a domain skeleton matching the M1 pattern (interface, model, fake, blank matrix rows) |
| M3-02 | Domain-completeness CI check | ✅ | CI | §10.2, §7.2 | §9.2 | A domain folder missing a capability-matrix/permission-matrix row or fake fails CI |
| M3-03 | Disks domain | ✅ | Rust/Dart | §6 | §4.4 | Field table authored (`sysinfo::Disks` audit, à la TDD §4), then implemented; snapshot only |
| M3-04 | Network domain + throughput stream | ✅ | Rust/Dart | §6 | §9 (process) | Field table authored; snapshot + clamped broadcast stream |
| M3-05 | Android permission rows for network | ✅ | Docs/CI | §2.5 | §9.3 | `ACCESS_NETWORK_STATE`/`ACCESS_WIFI_STATE` documented; lint fails if undeclared in example app |
| M3-06 | Prebuilt-binary distribution (hash + attestation + ABI) | ⬜ | Release | §7.3 | — | Build hook downloads, hash-verifies, and attestation-verifies a real artifact end-to-end |
| M3-07 | CI ABI diff/bump gate | ⬜ | CI | §10.3 | — | A native-layout change without an `abi.rs` bump fails release automation |
| M3-08 | 100% dartdoc coverage CI gate | ⬜ | CI | §7.2, §9.3 | — | `dart doc` coverage check enforced from this milestone onward, not before |

***

## EPIC-M4 — Store hardening + 1.0 release

**Goal:** close every store-compliance gap and ship the first stable release, still on the Cargokit default.

| ID | Title | Status | Area | PRD § | Acceptance criteria |
|---|---|---|---|---|---|
| M4-01 | `apple-app-store` CI assertion | ⬜ | CI | §2.4 | CI build with the feature flag asserts no prohibited APIs are linked |
| M4-02 | Play/NDK/permission gates finalized | ⬜ | CI | §2.5 | Full permission-matrix lint active across all shipped domains |
| M4-03 | `ffigen` escape-hatch documented | ⬜ | Docs | §3.3 | Approach B documented as a maintained-but-not-default fallback |
| M4-04 | Missing-`dart_sysinfo_flutter` detection shipped | ⬜ | Dart | §9.2 | One-time debug-mode warning fires on the documented hot-restart-without-dispose scenario |
| M4-05 | Pub.dev discoverability polish | ⬜ | Docs/Release | §9.3 | Topics, full-scoring example, Keep-a-Changelog CHANGELOGs in place |
| M4-06 | 1.0 release | ⬜ | Release | §10.3 | `dart_sysinfo` + `dart_sysinfo_flutter` published at 1.0.0, Cargokit still default |

***

## EPIC-M5 — Native Assets default

**Goal:** execute the PRD §3.3 sunset — flip the default backend once the criterion is objectively met. Not a 1.0 blocker; may land before or after M4.

| ID | Title | Status | Area | PRD § | Acceptance criteria |
|---|---|---|---|---|---|
| M5-01 | Verify §3.3 sunset criterion | ⬜ | Release | §3.3 | All three bullets (stable codegen, CI green streak, prebuilt path works on Native Assets) confirmed with evidence linked |
| M5-02 | Flip default backend to Native Assets | ⬜ | Bridge | §3.3 | New consumers get Native Assets by default without extra config |
| M5-03 | Demote `cargokit/` to unsupported fallback | ⬜ | Repo/CI | §7.4 | Cargokit path remains in-tree, documented as community/legacy, dropped from required CI |
| M5-04 | Update `PRD.md` status/§3.3 text | ⬜ | Docs | §7.4 | PRD reflects the new default backend post-flip |

***

## Current focus

**Completed:** EPIC-M0 (scaffolding), EPIC-M1 (P1 domains), EPIC-M2 (Native Assets track).

**Next (pick one):**

- **EPIC-M3** — P2 domains (M3-03 disks ✅; M3-04 network ✅; M3-05 permission lint ✅), domain generator ✅, dartdoc/ABI CI gates.
- **EPIC-M5** — Native Assets default (after PRD §3.3 sunset criterion met; not a 1.0 blocker). Sunset clock runs weekly on `main`; query with `bash tool/ci/sunset_clock_report.sh`.

**Known M1 deferrals (not gaps in story completion):**

- `lib/src/core/capability_registry.dart` — runtime-queryable registry stubbed; P1 capability data lives in [`docs/capability-matrix.md`](./docs/capability-matrix.md) (M1-13). Runtime registry lands with M3 domain-completeness work unless a new story is added.
- M4-04 — missing-`dart_sysinfo_flutter` debug warning not implemented in M1 (explicitly EPIC-M4).

## How this doc evolves

- When EPIC-M3's field-mapping Stories are picked up, add the resulting tables to a future `TDD.md` revision (§9), the same way TDD §4 exists for P1 — then backfill the PRD § / TDD § columns here.
- If a Story is discovered mid-implementation that isn't listed here, that's a sign either (a) it's genuinely new scope — stop and amend `PRD.md`/`TDD.md` first, or (b) it's an implementation detail of an existing Story — fold it in as a sub-task in the tracker, not a new top-level row here.
