# PRD: `dart_sysinfo` — Cross-Platform System Information for Dart & Flutter

**Document type:** Product Requirements Document (v1.3, implementation-ready)
**Status:** ✅ **APPROVED** — cross-functional sign-off complete (Engineering, DX/API Design, QA; see §14). Architecture (v1.0), SDK/build-backend/compliance (v1.1), developer-experience (v1.2), and consistency/sequencing (v1.3) reviews are all resolved.
**Implementation progress (repo):** M0 ✅ · M1 ✅ · M2 ✅ · M3–M5 not started — see [`EPICS.md`](./EPICS.md).
**SDK policy:** Minimum Flutter 3.38.0 / Dart 3.10.0; development & CI latest Flutter 3.47.4 / Dart 3.13.3 (see §1.5)
**Author role assumption:** Reader is a senior engineer; this document is prescriptive and implementation-ready.
**Companion documents:** [`TDD.md`](./TDD.md) specifies *how* every decision below is implemented (concrete types, module layout, field mappings — currently covers M0–M2); [`EPICS.md`](./EPICS.md) breaks the milestones in §12 into traceable Epics and Stories ready to become tracker issues.

***

## 1. Overview & Vision

### 1.1 Problem statement

Dart/Flutter lacks a single, deep, cross-platform system-information package covering Windows, Linux, macOS, iOS, and Android with a unified, friendly API. Existing packages are shallow, desktop-biased, or reimplement fragile shell parsing that structurally fails on iOS and is increasingly restricted on Android. The two industry references — `systeminformation` (Node.js, command-parsing) and `sysinfo` (Rust, native-API linkage) — prove that the native-linkage model is the only one that spans mobile and desktop without external tool dependencies.[^1][^2][^3]

### 1.2 Vision

Deliver an **industry-standard, modular, decoupled Dart package** that wraps a Rust core (built on the mature `sysinfo` crate plus a thin custom shim) and exposes an idiomatic, async, type-safe Dart API. The foundation must be structured so new domains (CPU, memory, disks, network, GPU, battery, sensors, etc.) can be added later without breaking public API contracts. Pure-Dart CLI/backend consumers must be able to depend on the core package **without a Flutter SDK**. Flutter apps consume the same core plus an optional thin Flutter integration package.

This is a package we intend to **build, enhance, and maintain indefinitely**. Every design choice in this revision is evaluated not just for "does it ship," but for "will this still be pleasant to depend on, contribute to, and upgrade after two years and a dozen contributors."

### 1.3 Goals and non-goals

| Goals | Non-goals (v1) |
|---|---|
| Unified async Dart API across 5 platforms | Web/WASM support (deferred; native assets have no Web code-asset path yet, and the package explicitly excludes `web` in `pubspec.yaml` — see §1.6[^4]) |
| Deep hardware/OS detail via Rust `sysinfo`[^1] | Full parity with `systeminformation`'s docker/printer/bluetooth breadth |
| Zero end-user native toolchain requirement | Real-time high-frequency telemetry dashboards (v2) |
| App Store **and** Play Store compliant builds[^1] | Server-only Node-style command parsing |
| Modular domains, additive evolution | Windows ARM64 desktop as a v1 hard requirement (best-effort) |
| Pure-Dart consumers with no Flutter SDK dependency | Official support for Flutter &lt; 3.38 / Dart &lt; 3.10 |
| Native Assets as the **eventual** default install path | Permanent dual-production Cargokit + Native Assets maintenance |
| **Testable by default** — first-party fakes, no real native calls required in `flutter test` / `dart test` | Widget helpers / state-management integrations (Provider/Riverpod/Bloc bindings) — may become separate community or first-party companion packages later, out of scope for this PRD |
| **Fast, friction-free first run** — one doctor command diagnoses toolchain issues | A GUI installer or IDE extension |
| **Predictable, documented evolution** — versioning, deprecation, and release process are specified, not tribal knowledge | — |

### 1.4 Target users & success metrics

Primary users are Flutter app developers **and** pure-Dart CLI/backend authors. Success is measured by:

- pub.dev likes/popularity and a **pub.dev score at or near the maximum** (topics, full-scoring example, 100% public API doc coverage)[^36][^37]
- all-five-platform CI green on both the minimum and latest supported SDKs
- **sub-frame API latency for cached snapshots**, made achievable and precise by the per-domain TTL cache in §5.5 — not an unqualified claim about raw native call cost
- zero-config install (no manual Gradle/Podspec/CMake edits by consumers)
- a Flutter-free `dart pub get` path for the core package
- a documented, low-friction "add a new metric" contributor path, backed by the scaffolding generator in §10.2 — not just prose
- **time-to-first-successful-build** for a new contributor or consumer, materially reduced by the `doctor` command in §9.1
- **zero required native mocking** to unit-test consumer code, via `package:dart_sysinfo/testing.dart` (§8)

### 1.5 SDK support policy

Treat “SDK baseline” as a **range**, not a single pin. Flutter **3.47.0 shipped with Dart 3.13.0**; Dart **3.13.3** appears in later 3.47 patches (3.47.3 / 3.47.4). Development pins the current latest valid pair, not the invalid `3.47.0` + `3.13.3` pairing.[^29]

| Role | Flutter | Dart |
|---|---|---|
| **Minimum (supported)** | `>=3.38.0` | `>=3.10.0 <4.0.0` |
| **Development SDK** | 3.47.4 | 3.13.3 |
| **CI** | Minimum + latest stable + one intermediate (e.g. 3.44) | Matching Dart for each Flutter line |

**Package `environment:` constraints**

```yaml
# packages/dart_sysinfo (published core — NO flutter: key)
environment:
  sdk: ">=3.10.0 <4.0.0"

# packages/dart_sysinfo_flutter and example/
environment:
  sdk: ">=3.10.0 <4.0.0"
  flutter: ">=3.38.0"
```

**Why 3.38 / 3.10 is the floor, not lower**

Flutter 3.38 is the first stable release where the `package_ffi` template officially uses build hooks and Native Assets without platform-specific CMake, Gradle, or CocoaPods build configuration; it shipped alongside Dart 3.10. From 3.38, Flutter also defaults to Android NDK r28 (16 KB page alignment) and requires Java 17.[^5][^30][^31][^32]

That floor is four stable lines behind 3.47 (3.38, 3.41, 3.44, 3.47), which is a reasonable support window without forcing a greenfield package to maintain pre-hooks native build workarounds.[^33]

Technically, FRB + Cargokit can run on older SDKs (third-party guidance cites ~Flutter 3.22 / Dart 3.4). That is **not** an official compatibility contract: it would force Cargokit and Native Assets to remain equal production paths, explode the Gradle/NDK/CocoaPods/Xcode matrix, and delay Native Assets as the canonical install path.[^6] Community patches for pre-3.38 may exist; they are unsupported.

**Upgrade policy:** raise the minimum only in a major release, or sooner if Native Assets, FRB, Rust target tooling, or store requirements force it.

**Two maturity axes (do not conflate them)**

1. **Flutter/Dart build hooks + code assets** — stable and foundational since 3.38. This is why the floor is 3.38, not 3.22.[^5][^16]
2. **FRB’s Native Assets integration/codegen** — still beta (`flutter_rust_bridge_codegen >= 2.13.0-beta.2`). This is why Cargokit is the *current* default, not because Flutter hooks themselves are shaky.[^7][^18][^19]

### 1.6 Platform support declaration

The package must be explicit, at the pubspec level, about which platforms it supports — not just in prose. `dart_sysinfo`'s `pubspec.yaml` declares:

```yaml
platforms:
  android:
  ios:
  linux:
  macos:
  windows:
  # web: intentionally absent
```

**Rationale:** there is currently no Native Assets code-asset path for Web.[^4] Declaring `web` absent (rather than present-but-degraded) means:

- pub.dev shows a clear "not supported on this platform" badge instead of implying partial support.
- `flutter build web` / `flutter run -d chrome` on a consuming app fails **fast and clearly at dependency-resolution time**, with a standard Flutter/pub error, instead of a confusing native-symbol-resolution failure deep in a build hook.
- The package does **not** claim runtime `ReadingUnsupported` behavior on Web, because the package cannot compile there at all. If a genuine Web-compatible stub is built in a future major version (conditional imports, all fields `ReadingUnsupported`), that is a deliberate, separately-scoped feature addition — not an implicit v1 promise.

***

## 2. Architecture

### 2.1 Layered, decoupled design

The product is a **federated monorepo** with a **published package split** so Flutter is never an accidental dependency of pure-Dart consumers:

1. **Rust core (`packages/native/`)** — a `staticlib`+`cdylib` crate wrapping `sysinfo` plus a custom `extern`/async API surface. Domain logic lives here; this is the single source of truth for platform quirks. Shared native state is a single long-lived `sysinfo::System` guarded by a `Mutex`/`RwLock` (see §3.4).[^7][^8]
2. **Bridge layer** — generated Dart↔Rust glue (see Section 3). No hand-written marshalling of structs.
3. **Dart domain API (`packages/dart_sysinfo/lib/src/domains/`)** — one module per domain (cpu, memory, disks, network, os, components), each behind an abstract interface with immutable data models using `Reading<T>` (see §5.2).
4. **Dart public facade (`packages/dart_sysinfo/lib/dart_sysinfo.dart`)** — a stable, curated export surface. Internal reorganization never leaks to consumers. **No `flutter:` SDK constraint.**
5. **Testing surface (`packages/dart_sysinfo/lib/testing.dart`)** — first-party fakes for every domain, importable without pulling in Flutter or real native calls (see §8).
6. **Flutter integration (`packages/dart_sysinfo_flutter`)** — thin, optional. Wires `SysInfo.dispose()` into Flutter hot-restart / app lifecycle. It alone is Flutter-aware; it reads a platform-agnostic signal already exposed by the core's idempotent init (§3.4) to detect "native state already existed when I started" and, only from that Flutter-aware vantage point, emits the debug-mode "did you forget to wire lifecycle" warning (see §9.2). The core itself never references Flutter. Must not re-export a different API; it only adds Flutter-specific lifecycle glue.
7. **App/consumer** — Flutter apps depend on `dart_sysinfo` (and optionally `dart_sysinfo_flutter`); CLI/backend apps depend only on `dart_sysinfo`.

```
+----------------------------------------------------------------------+
|  Consumer: Flutter app          |  Consumer: Dart CLI / backend      |
|  dart_sysinfo + dart_sysinfo_flutter |  dart_sysinfo only            |
+----------------------------------------------------------------------+
|  dart_sysinfo_flutter (optional)  hot-restart / WidgetsBinding glue  |
+----------------------------------------------------------------------+
|  Public facade  (SysInfo, Reading<T>, SysInfoException, re-exports)  |
|  Testing facade  (lib/testing.dart — fakes, no native calls)         |
+----------------------------------------------------------------------+
|  Dart domain modules  cpu | memory | disks | network | os | ...      |
|   - abstract interface per domain                                    |
|   - immutable freezed-style models with Reading<T> fields            |
|   - snapshot (TTL-cached) vs broadcast stream access patterns        |
+----------------------------------------------------------------------+
|  Bridge (generated)  FRB glue  OR  ffigen bindings                   |
+----------------------------------------------------------------------+
|  Rust core  packages/native/  ->  sysinfo crate + custom shim        |
|   - Mutex/RwLock around a single System instance                     |
|   - feature-gated domains (system,disk,network,component)            |
|   - apple-app-store / apple-sandbox flags                             |
|   - ABI/version tag embedded in the compiled library                 |
+----------------------------------------------------------------------+
|  OS native APIs  libc | windows-rs | objc2 frameworks                |
+----------------------------------------------------------------------+
```

**M0 verification (blocking):** confirm that `packages/dart_sysinfo`’s `hook/build.dart` (and FRB/Cargokit integration) has **no hidden Flutter-only import or pubspec dependency**, so `dart pub get` + a Dart CLI build works on the Dart SDK alone.[^28]

### 2.2 Why a Rust core over the `sysinfo` C header

`sysinfo` ships a `sysinfo.h` C interface, but it is far narrower than the full Rust API — it exposes system/memory/swap/CPU basics, process enumeration via callbacks, networks, disks, and motherboard/product strings, but omits component temperatures, GPU, and per-disk detail that the Rust API provides. Binding the C header directly with `ffigen` would cap the feature ceiling. Writing a **thin Rust shim** over the full crate removes that ceiling and lets the bridge expose rich types (enums with values, `Result`, `Stream`) natively.[^9]

### 2.3 Feature-gated Rust core

Mirror `sysinfo`'s Cargo feature flags (`component`, `disk`, `gpu`, `network`, `system`, `user`) so the compiled binary only includes requested domains, keeping binary size down. The core crate must declare `crate-type = ["staticlib", "cdylib"]` (static for iOS/macOS framework linking, dynamic for Android/Linux/Windows) and pin an explicit stable toolchain via `rust-toolchain.toml`.[^8][^7]

### 2.4 Apple sandbox compliance (mandatory for App Store)

`sysinfo` is **not App Store compatible by default** because Apple restricts certain linked APIs. The core must expose a build profile that enables the `apple-app-store` feature flag (which also enables `apple-sandbox`), disabling prohibited features on iOS/macOS store builds. This is a first-class build dimension, not an afterthought.[^1]

CI builds this profile and asserts no prohibited APIs are linked (see §8).

### 2.5 Android / Play Store compliance (mandatory, parallel to §2.4)

Play compliance is a first-class build dimension, not an afterthought deferred to P3/P4.

**Toolchain / binary requirements**

- Android NDK **r28+** (Flutter 3.38’s default). Required for 16 KB page-size alignment on recent Play targets. Cargokit / Native Assets must install and use r28+, not r26.[^31]
- Java 17 as the Android build JDK, matching Flutter 3.38+.[^31]
- Targets: `aarch64-linux-android`, `armv7-linux-androideabi`, `x86_64-linux-android`.

**Per-domain permission & restriction matrix** (maintained as code + docs; expand as domains ship — enforced by the scaffolding generator in §10.2)

| Domain | Typical Android surface | Consumer obligation |
|---|---|---|
| OS / CPU / memory (P1) | No extra dangerous permissions | None beyond normal app process |
| Disks (P2) | Scoped storage; path visibility limits | Document which paths are readable; never claim full-disk access |
| Network (P2) | `ACCESS_NETWORK_STATE` (and possibly `ACCESS_WIFI_STATE`) | Declare in the **app** manifest; package must not silently inject them |
| Components / GPU (P3) | Often empty on devices/emulators without sensors | `ReadingUnsupported` — never fabricate |
| Battery (P4) | `BATTERY_STATS` is signature/privileged; public apps use `BatteryManager` | Use only APIs available to normal apps; document OEM gaps |
| Processes (P4) | Android 10+ / 12+ usage-stats and background restrictions | Capability-gated; never require `PACKAGE_USAGE_STATS` unless the consumer opts in |

**Policy:** the published packages must **not** merge extra Android permissions into the consumer app by default. Each domain that *would* need a permission documents it, exposes it on the capability matrix, and returns `ReadingUnsupported` / `ReadingUnavailable` when the permission is absent.

**CI/lint gate:** a check (custom lint, analyzer plugin, or example-app audit job) fails if:

1. A domain whose permission is undeclared in the **example / test app** is exercised as if supported, or
2. `dart_sysinfo` / `dart_sysinfo_flutter` Android manifests gain a new permission without a matching docs + capability-matrix update.

***

## 3. FFI Approach — Research & Recommendation

Three viable approaches exist in the current (2026) Dart/Flutter ecosystem. All are validated against official Dart and Flutter documentation.

### 3.1 The three candidate approaches

| Approach | Codegen | Native build/bundling | Best for |
|---|---|---|---|
| **A. `flutter_rust_bridge` v2 + Native Assets backend** | Auto (FRB generates Dart + Rust glue)[^6] | Native Assets build hook via `flutter_rust_bridge_hooks` wrapping `native_toolchain_rust`[^7] | Rich Rust types, async/streams, least manual glue; **eventual default** |
| **B. `ffigen` + Native Assets (`package_ffi` template)** | Auto from C header (`cbindgen`-generated)[^10][^11] | `hook/build.dart` + `native_toolchain_*`[^5][^12] | Pure-Dart-first, minimal dependencies, C-ABI purists |
| **C. `flutter_rust_bridge` v2 + Cargokit (legacy backend)** | Auto (FRB)[^13] | Cargokit integrates cargo with Gradle/CocoaPods/CMake per platform[^14][^8] | **Transitional default** until FRB Native Assets codegen is stable |

### 3.2 What changed recently (why this matters in 2026)

The decisive platform development is **Flutter Native Assets / build hooks**. Since Flutter 3.38, `flutter create --template=package_ffi` uses build hooks configured in a `hook/build.dart` script and **no longer requires OS-specific build files** (no CMakeLists, no Podspec, no Gradle native wiring), and this works for both Flutter and standalone Dart. Native code is compiled and bundled automatically per target platform/ABI. The mechanism is driven by the `hooks`, `code_assets`, and `native_toolchain_*` packages, with an optional `hook/link.dart` for tree-shaking unused native symbols.[^15][^16][^17][^12][^5]

`flutter_rust_bridge` v2 layered a **Native Assets backend** on top of this, available via `--integration-backend native-assets` (requires `flutter_rust_bridge_codegen >= 2.13.0-beta.2` and a build-hook-capable SDK). The generated `hook/build.dart` uses `flutter_rust_bridge_hooks`, which wraps `native_toolchain_rust` to compile the crate with Cargo and register it as a code asset. Cargokit remains FRB’s **current default** backend for compatibility — including with SDKs older than our official floor, which we do not support.[^18][^19][^13][^7]

### 3.3 Recommendation

**Target architecture: Approach A** — `flutter_rust_bridge` v2 with the Native Assets backend. It gives the richest developer experience (idiomatic Dart bindings, complex enums/structs, `Result` error handling, `Stream` support, and async that never blocks the Flutter main isolate) while letting Native Assets build and bundle the Rust library with zero consumer-side toolchain wiring.[^6][^7][^9]

**Current default (transitional): Approach C — Cargokit.** FRB’s Native Assets codegen is still beta. Until the sunset criterion below is met, **ship Cargokit as the default integration**. Native Assets is **not** a permanent equal production path: it runs as a **CI-gated parallel track** whose only purpose is to gather the evidence required to flip the default.[^19][^14][^7][^8]

**Sunset criterion (flip Cargokit → Native Assets as default)** — all of:

1. `flutter_rust_bridge_codegen` Native Assets backend is a **stable (non-beta)** release, and
2. The Native Assets CI matrix (minimum SDK + latest stable, all 5 platforms that Native Assets supports on that SDK) has been **green for at least two consecutive stable Flutter releases, or eight consecutive weeks of scheduled CI, whichever is later**, with zero build-backend regressions attributed to Native Assets, and
3. Prebuilt-binary download + hash + signature + ABI handshake (see §7.3) works on the Native Assets hook path.

When met: Native Assets becomes the default; Cargokit remains in-tree only as a documented community/legacy fallback with **no official CI guarantee**. This flip is **M5** and may happen before or after the 1.0 pub.dev release; 1.0 is **not** blocked on it.

**Keep a pure-`ffigen` path documented (Approach B)** as an escape hatch if dropping the FRB runtime dependency becomes necessary. FRB v2 is compatible with pure Dart, so a single FRB codebase serves Flutter and CLI consumers; `ffigen`-over-C-shim is not required to keep the core Flutter-free.[^20][^10][^28]

### 3.4 Concurrency, threading, and native lifecycle

FFI calls are **synchronous and run on the calling isolate**, so a slow native call freezes the UI unless moved off the main isolate. The design mandates:[^21]

- All public domain reads return `Future`/`Stream` (async Dart), never sync, except cheap cached getters.
- Use FRB's **Async Dart + Sync Rust** mode (Dart non-blocking, Rust on a thread pool) for CPU-bound snapshots, and **Async Dart + Async Rust** for IO-bound work.[^22]
- Continuous metrics (CPU load, per-interface network deltas) are exposed as Dart `Stream`s backed by Rust `StreamSink`, which is non-blocking by construction.[^23][^9]
- For any heavy pure-Dart post-processing, document `Isolate.run` usage; data crossing isolate boundaries is copied unless transferable.[^21]

**Shared native `System` (required):** this maps onto `sysinfo`'s stateful model, where most metrics require a previous measurement and a `refresh` diff. The Rust core holds a **single long-lived `System` instance**, not one per call.

**Synchronization (required):** wrap that instance in a `Mutex` or `RwLock`. Every domain snapshot and every stream tick **acquires the lock for its refresh + read**, then releases it before returning to Dart. No unsynchronized access from the FRB thread pool. Document the lock in the Rust shim module and in contributor docs so new domains cannot bypass it.

**Concurrency test (required):** a Rust stress test that concurrently hammers snapshot + stream refresh paths (`cargo test`, still with `--test-threads=1` for *sysinfo reliability* of the underlying OS reads where needed — the stress test itself may use multiple threads *inside* one test to contend the mutex). Fail on deadlock (timeout) or panic.

**Lifecycle (required):**

- Native init is **idempotent** (safe to call repeatedly; returns the existing instance) and reports back whether it created fresh state or found state already running from a prior init call in this process. This is a plain boolean/enum on the init result — the core needs it anyway for idempotency, and it doubles as the platform-agnostic signal `dart_sysinfo_flutter` reads for §9.2. The core does not interpret this signal itself and never references Flutter.
- Public `SysInfo.dispose()` tears down the native singleton, cancels active Rust `StreamSink`s / worker threads, and releases the `System`. After dispose, the next API call re-inits cleanly.
- `dart_sysinfo_flutter` wires `dispose()` into Flutter hot-restart / `WidgetsBinding` so Dart isolate reset does not leak native stream threads or duplicate `System` state.
- The example app’s manual QA checklist includes: start a CPU load stream → hot restart → confirm no duplicate native workers and streams resume or fail closed, never silently leak.

***

## 4. Repository Structure

A federated plugin monorepo keeps domains decoupled and the Flutter SDK off the core package:

```
dart_sysinfo/                      # git root (melos-managed workspace)
├─ packages/
│  ├─ dart_sysinfo/                # PUBLISHED CORE — pure Dart, no flutter: constraint
│  │  ├─ lib/
│  │  │  ├─ dart_sysinfo.dart      # curated public exports (SysInfo, Reading, exceptions, domains)
│  │  │  ├─ testing.dart           # first-party fakes (FakeSysInfo, per-domain fakes) — §8
│  │  │  └─ src/
│  │  │     ├─ domains/
│  │  │     │  ├─ cpu/             # interface + models + impl
│  │  │     │  ├─ memory/
│  │  │     │  ├─ disks/
│  │  │     │  ├─ network/
│  │  │     │  ├─ os/
│  │  │     │  └─ components/      # temperatures, fans
│  │  │     ├─ core/               # SysInfo entrypoint, dispose, resetForTesting,
│  │  │     │                      # overrideInstance, capability registry, exceptions
│  │  │     └─ bridge/             # generated FRB Dart glue (do not edit)
│  │  ├─ bin/
│  │  │  └─ doctor.dart            # `dart run dart_sysinfo:doctor` — §9.1
│  │  ├─ hook/
│  │  │  ├─ build.dart             # Native Assets build hook (parallel track → eventual default)
│  │  │  └─ link.dart              # optional tree-shaking
│  │  ├─ android/                  # Cargokit/Gradle wiring while Cargokit is default
│  │  ├─ ios/ macos/ linux/ windows/
│  │  ├─ CHANGELOG.md              # Keep a Changelog format — §9.3[^35]
│  │  └─ pubspec.yaml              # sdk: ">=3.10.0 <4.0.0"; platforms: (no web) — §1.6
│  ├─ dart_sysinfo_flutter/        # PUBLISHED, optional — Flutter lifecycle glue only
│  │  ├─ lib/dart_sysinfo_flutter.dart
│  │  ├─ CHANGELOG.md
│  │  └─ pubspec.yaml              # sdk + flutter: ">=3.38.0"; depends on dart_sysinfo
│  └─ native/                      # Rust core crate (not a Dart package)
│     ├─ Cargo.toml                # crate-type = [staticlib, cdylib]; feature-gated
│     ├─ rust-toolchain.toml       # pinned stable toolchain + target list
│     └─ src/
│        ├─ api/                   # FRB-facing public API (one module per domain)
│        ├─ shim/                  # System+Mutex, thin wrappers over sysinfo
│        ├─ abi.rs                 # embedded ABI/version tag (see §7.3)
│        └─ frb_generated.rs       # generated (do not edit)
├─ tool/
│  └─ new_domain.dart              # domain scaffolding generator — §10.2 (added pre-M3, extracted
│                                  # from the hand-built M1 domains, not built speculatively in M0)
├─ cargokit/                       # git subtree — TRANSITIONAL default backend
├─ example/                        # Flutter demo; depends on dart_sysinfo_flutter
├─ pubspec.yaml                    # Dart pub workspace + Melos 7 config (lockstep versioning — §10.3)
├─ analysis_options.yaml           # very_good_analysis baseline, inherited by all packages — §10.1
├─ CONTRIBUTING.md                 # release checklist, deprecation policy, domain checklist
└─ .github/workflows/              # CI matrix (see Section 7)
```

Domain isolation rule: a domain module may depend only on `core/` and the bridge, never on a sibling domain. Adding a domain = run the generator (§10.2) + fill in the Rust `api/` module + regenerate bindings; nothing else changes.[^7]

`dart_sysinfo_flutter` may depend on `dart_sysinfo`. `dart_sysinfo` must never depend on `dart_sysinfo_flutter`.

***

## 5. Public API Design

### 5.1 Principles

- **Immutable data models** with value equality (freezed-style), so snapshots are safely shareable across isolates.
- **Typed readings, never fabricated data:** every potentially platform-specific field is a `Reading<T>` (§5.2). Capability flags remain for cheap domain-level probes (`sys.components.isSupported`) but do **not** replace per-field readings.[^24][^1]
- **Two access patterns per domain:** one-shot, TTL-cached `Future` snapshot (§5.5) and continuous broadcast `Stream` (§5.4).
- **Explicit lifecycle and testability:** `SysInfo.instance` (idempotent init), `SysInfo.dispose()`, `SysInfo.resetForTesting()`, `SysInfo.overrideInstance()` (§5.6).
- **A small, closed exception hierarchy** for lifecycle/native failures, distinct from `Reading<T>` (§5.3).
- **Additive evolution:** new fields are added as `Reading<T>`; new domains as new namespaces. No breaking signature changes within a major version. Do **not** encode unsupported state as a bare nullable `T?`.

### 5.2 `Reading<T>` (required public type)

Unsupported, not-yet-measured, and failed reads are **not** interchangeable nulls. Use a sealed wrapper:

```dart
sealed class Reading<T> {
  const Reading();

  bool get isValue => this is ReadingValue<T>;
  bool get isUnsupported => this is ReadingUnsupported<T>;
  bool get isUnavailable => this is ReadingUnavailable<T>;

  T? get valueOrNull => switch (this) {
        ReadingValue<T>(:final value) => value,
        _ => null,
      };

  /// Returns the value if present, otherwise [fallback].
  T orElse(T fallback) => valueOrNull ?? fallback;

  /// Exhaustive combinator. Safe to rely on forever within this major
  /// version: see the closed-variant policy below.
  R when<R>({
    required R Function(T value) value,
    required R Function(String? reason) unsupported,
    required R Function(String? reason) unavailable,
  }) =>
      switch (this) {
        ReadingValue<T>(value: final v) => value(v),
        ReadingUnsupported<T>(reason: final r) => unsupported(r),
        ReadingUnavailable<T>(reason: final r) => unavailable(r),
      };

  /// Partial combinator; anything omitted falls back to [orElse].
  R maybeWhen<R>({
    R Function(T value)? value,
    R Function(String? reason)? unsupported,
    R Function(String? reason)? unavailable,
    required R Function() orElse,
  }) =>
      switch (this) {
        ReadingValue<T>(value: final v) =>
          value != null ? value(v) : orElse(),
        ReadingUnsupported<T>(reason: final r) =>
          unsupported != null ? unsupported(r) : orElse(),
        ReadingUnavailable<T>(reason: final r) =>
          unavailable != null ? unavailable(r) : orElse(),
      };
}

final class ReadingValue<T> extends Reading<T> {
  const ReadingValue(this.value);
  final T value;
}

/// This platform / build profile can never report this field
/// (e.g. iOS App Store profile, missing sensor, Web — see §1.6).
final class ReadingUnsupported<T> extends Reading<T> {
  const ReadingUnsupported({this.reason});
  final String? reason;
}

/// Supported in principle, but this attempt failed or is not yet measured
/// (permission missing, transient OS error, first sample of a delta metric).
final class ReadingUnavailable<T> extends Reading<T> {
  const ReadingUnavailable({this.reason});
  final String? reason;
}
```

**Closed-variant policy (required, permanent for this major version):** `Reading<T>` has **exactly these three variants**. Because it is `sealed`, adding a fourth variant would break every consumer's exhaustive `switch`/`when` — that is treated as a **major-version-only** change, full stop. Any future nuance (e.g. "pending/warming up") is modeled as **data within an existing variant** (e.g. `ReadingUnavailable(reason: 'pending')`), never as a new type. This rule is non-negotiable without a deliberate major-version decision recorded in §11.

**Mapping rules**

| Situation | Variant |
|---|---|
| OS returned a real value | `ReadingValue` |
| `sysinfo` / capability matrix says not supported | `ReadingUnsupported` |
| Store profile disabled the API (`apple-app-store`) | `ReadingUnsupported` |
| Permission not granted; sensor empty this sample; refresh error | `ReadingUnavailable` |
| Platform excluded entirely (e.g. Web — §1.6) | N/A — package does not compile there |

Never synthesize zeros, empty strings, or “typical” hardware values to look complete.[^24][^1][^25]

`reason` strings on `ReadingUnsupported`/`ReadingUnavailable` are **developer-facing diagnostics** (for logs/debugging), not localized or intended for direct display in end-user UI without the consuming app's own copy/translation.

### 5.3 `SysInfoException` hierarchy (required public type)

`Reading<T>` covers per-field absence. It does **not** cover top-level lifecycle or native-loading failures — those are real exceptions, not sentinel values:

```dart
sealed class SysInfoException implements Exception {
  const SysInfoException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// The native library could not be located or loaded for this
/// platform/ABI.
final class SysInfoLoadException extends SysInfoException {
  const SysInfoLoadException(super.message);
}

/// The loaded native library's ABI does not match the version the Dart
/// bridge was generated against. See §7.3.
final class SysInfoAbiMismatchException extends SysInfoException {
  const SysInfoAbiMismatchException(
    super.message, {
    required this.expectedAbi,
    required this.actualAbi,
  });
  final int expectedAbi;
  final int actualAbi;
}

/// A `SysInfo` API was called after `SysInfo.dispose()`.
final class SysInfoDisposedException extends SysInfoException {
  const SysInfoDisposedException(super.message);
}

/// `SysInfo.instance` was accessed on a platform excluded by §1.6
/// (should normally be caught earlier, at build/dependency-resolution
/// time, but this is the runtime backstop).
final class SysInfoUnsupportedPlatformException extends SysInfoException {
  const SysInfoUnsupportedPlatformException(super.message);
}
```

This is the **complete list** of throwable errors from the public API. Every other failure mode is expressed as `Reading<T>`.

### 5.4 Streaming semantics (required contract)

Every domain stream (`sys.cpu.load(interval: ...)`, `sys.network.throughput(interval: ...)`, etc.) follows one contract:

- **Broadcast, not single-subscription.** Multiple `.listen()` calls on the *same* stream getter with the *same* interval share **one** underlying native poller (ref-counted); the native worker stops when the last listener cancels. Two widgets displaying CPU load do not double the native work.
- **Enforced minimum interval per platform**, documented per domain (e.g. 200 ms on mobile, 50 ms on desktop, subject to tuning during M1 implementation). Requesting a smaller interval is **clamped** to the minimum, with a one-time debug-mode log explaining the clamp — never a silent no-op and never an unbounded tight native loop.
- **Errors surface as `Stream` error events** (`onError`), never silently dropped and never a native panic — a failed refresh emits an error for that tick; the stream itself is not torn down unless the native worker itself is gone (e.g. after `dispose()`).

### 5.5 Snapshot caching semantics (required contract)

One-shot snapshots (`await sys.cpu.snapshot()`) are backed by a **per-domain TTL cache**, not a real native refresh on every call. This is what makes the "sub-frame latency" goal (§1.4) both true and safe to rely on from a widget `build()` method:

- Each domain declares a default cache TTL (e.g. 500 ms for CPU/memory/OS in P1 — exact defaults finalized during M1 and recorded in the capability matrix).
- `snapshot({bool forceRefresh = false})` bypasses the cache and performs a real native refresh when `forceRefresh: true`.
- The cache is per-`SysInfo` instance (so `resetForTesting()`/`overrideInstance()` in §5.6 get a clean cache too).

### 5.6 Lifecycle, singleton, and testability

`SysInfo.instance` remains the default, idiomatic entrypoint for application code — but it must not make consumer code hard to test:

```dart
final sys = SysInfo.instance;

// In a test file — resetForTesting and overrideInstance are both
// annotated @visibleForTesting on their declarations in dart_sysinfo.
void main() {
  tearDown(SysInfo.resetForTesting);

  test('shows fake CPU load', () {
    SysInfo.overrideInstance(FakeSysInfo(
      cpu: FakeCpuDomain(load: ReadingValue(0.42)),
    ));
    // ... exercise consumer code against sys ...
  });
}
```

- `SysInfo.resetForTesting()` tears down and clears any override, restoring the real singleton on next access.
- `SysInfo.overrideInstance(SysInfo fake)` swaps the singleton returned by `SysInfo.instance` for the remainder of the test/process — intended to be paired with the fakes in `package:dart_sysinfo/testing.dart` (§8).
- Both are `@visibleForTesting` and documented as such; using them in production code is a lint-flagged mistake, not a supported pattern.

### 5.7 Illustrative surface (target API shape — validated during M1, not yet locked)

The snippet below shows the **intended 1.0-shaped API**, including P2 network. It is the target to build toward, not a signature freeze: M1 implementation may reveal small ergonomic adjustments to the P1 portion (`cpu`, `memory`, `os`), which is expected and fine precisely because the doc-coverage gate is deferred to M3/M4 (§7.2) and no 1.0 has shipped yet. **M1 / P1 ships only OS, CPU, and memory** (plus `Reading<T>`, `SysInfoException`, `dispose`/`resetForTesting`/`overrideInstance`, capability matrix, and `testing.dart`). Disks and network land in M3 / P2.

```dart
final sys = SysInfo.instance;

// One-shot, TTL-cached snapshots (P1)
final CpuInfo cpu = await sys.cpu.snapshot();
final MemoryInfo mem = await sys.memory.snapshot();
final OsInfo os = await sys.os.snapshot(forceRefresh: true);

// Reading<T> — exhaustive combinator, no manual switch needed
final vendor = cpu.vendor.when(
  value: (v) => v,
  unsupported: (_) => 'not on this platform',
  unavailable: (reason) => 'retry later: $reason',
);

// Continuous, broadcast streams (P1: CPU load; P2: network)
sys.cpu.load(interval: Duration(seconds: 1)).listen(
      (load) => print(load),
      onError: (e) => print('refresh failed: $e'),
    );
sys.network.throughput().listen(...); // P2 — final shape, not M1

// Domain-level capability probe (does not replace per-field Reading)
if (sys.components.isSupported) { ... }

// Exceptions are reserved for lifecycle/native failures, not field absence
try {
  await sys.cpu.snapshot();
} on SysInfoAbiMismatchException catch (e) {
  // upgrade/rebuild instructions in e.message
}

// Lifecycle (required; Flutter wiring lives in dart_sysinfo_flutter)
await SysInfo.dispose();
```

The streaming design directly reflects FRB's `StreamSink`→Dart `Stream` bridge, which returns immediately and pushes values as they are produced.[^9][^23]

***

## 6. Domain Scope & Phasing

Scope is phased so v1 ships a solid, cross-validated core and later phases add breadth without refactoring foundations.

| Phase | Domains | Rust source | Platform coverage |
|---|---|---|---|
| **P1 (MVP)** | System/OS, CPU (info + load), Memory/swap | `sysinfo` system+cpu+mem[^1] | All 5 |
| **P2** | Disks/filesystems, Network interfaces + throughput | `sysinfo` disk+network features | All 5 (mobile subset) |
| **P3** | Components (temps/fans), GPU, Users | `sysinfo` component+gpu+user features | Desktop-first; mobile best-effort |
| **P4** | Battery, processes, extended hardware | shim + `sysinfo` process API | Per-platform capability matrix |

Mobile caveat, validated: on virtual Linux (Docker/WSL) and some mobile contexts, hardware component data may be empty because host sensors are not exposed — this must be surfaced as `ReadingUnsupported` / `ReadingUnavailable` as appropriate, matching `sysinfo`'s documented behavior. Never fabricate temperatures or fan speeds.[^25][^1]

Each new domain ships with: capability-matrix row, Android permission row (even if “none”), Apple store-profile impact, snapshot TTL default, stream minimum interval (if applicable), and `Reading<T>` on every optional field — enforced by the scaffolding generator and its CI check (§10.2).

***

## 7. Build, CI/CD & Distribution

### 7.1 Native toolchain per platform

Cross-compilation targets and toolchains, validated against FRB/Cargokit docs:

- **Android:** `rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android`; **NDK r28+** via `ANDROID_NDK_ROOT` (16 KB page-size / Play compliance). Cargokit installs NDK and configures cross-compilation automatically while it remains the default; libraries land in `lib/{arch}/` of the APK. JDK 17.[^26][^6][^31]
- **iOS/macOS:** static lib linked into a CocoaPods framework while Cargokit is default; Cargokit builds all active architectures and `lipo`s them. XCFramework across device/simulator slices for distribution. Store builds compile with `apple-app-store`.[^14][^8][^1]
- **Linux/Windows:** dynamic library via CMake integration (Cargokit `build-cmake`) until Native Assets is default.[^14]

Windows ARM64 remains best-effort, not a v1 hard requirement. Web is not a target (§1.6).

### 7.2 CI matrix

GitHub Actions with `subosito/flutter-action` + `dtolnay/rust-toolchain` (the version pinned in `rust-toolchain.toml`), running `flutter_rust_bridge_codegen generate`, Android builds with NDK r28+, and `flutter build` / `dart` CLI builds per platform.[^6][^26]

**SDK axes (required):**

| Job | SDK |
|---|---|
| Minimum | Flutter 3.38.x / Dart 3.10.x |
| Intermediate | One line between min and latest (e.g. Flutter 3.44) |
| Latest | Flutter 3.47.4 / Dart 3.13.3 (bump with stable) |

**Package axes:** `dart_sysinfo` on Dart-only (`dart pub get`, Dart CLI example or test); `example/` + `dart_sysinfo_flutter` on Flutter.

**Backend axes:** Cargokit (default, must be green to merge) and Native Assets (parallel, must be green to *count* toward the §3.3 sunset clock; red Native Assets jobs do not block Cargokit-only fixes but do pause the sunset clock).

**Quality axes (new — see §10.1 / §8), phased deliberately rather than all-at-once:**

- **From M0:** Lint — `dart analyze` against the root `very_good_analysis` config, **zero warnings tolerated**.[^34] Cheap to run, catches real bugs early, and doesn't block API iteration the way documentation churn would.
- **From M3/M4 (pre-1.0 hardening), not M0/M1:** Doc coverage — 100% dartdoc on public symbols, CI-enforced.[^36] Deferred because documenting a P1 API that's still being validated during M1 implementation is wasted effort if signatures shift; see §5.7.
- **From M3 (alongside the domain generator, §10.2), not M0:** Domain-completeness — scaffolding generator's CI check — a domain folder without matching capability/permission-matrix rows and tests fails the build.

**Prebuild native artifacts in CI** so consumers never need a Rust toolchain; Cargokit / Native Assets then bundle them.[^6][^26][^21]

**Store / permission gates:** see §8.

### 7.3 Distribution

Two shipping modes, both documented:

1. **Build-from-source** (Cargokit today; Native Assets after sunset) — simplest to maintain; requires the consumer to have Rust only when prebuilts are missing or `DART_SYSINFO_FROM_SOURCE=1`.
2. **Prebuilt binaries (stable-release target)** — the build hook downloads the artifact for the current OS/ABI, then:
   1. **Verifies the hash** against a pinned map in the package.
   2. **Verifies provenance** via signed attestations (GitHub Artifact Attestations or Sigstore/cosign) — hash-only is **not** sufficient, because a compromised release can update the hash in the same PR.[^5]
   3. **Places** the library in the hook output directory.

**ABI / version handshake (required):** the Rust library embeds a monotonic `DART_SYSINFO_ABI` integer (and crate semver string) exported to Dart. At load time the Dart bridge compares it to the ABI it was generated against. **Mismatch throws `SysInfoAbiMismatchException`** (§5.3) with upgrade/rebuild instructions; never proceed with a skew binary. Bump ABI on any breaking native layout / FRB signature change — enforced by the CI ABI gate (§10.3).

### 7.4 Native Assets sunset checkpoint

Tracked as **M5**. Owners: whoever maintains CI. When §3.3’s three bullets are true, open a dedicated PR that (a) switches FRB integrate/default backend to Native Assets, (b) demotes `cargokit/` to unsupported, (c) updates this PRD status line and §3.3 “current default”.

***

## 8. Quality, Security & Testing

- **Memory safety:** FRB manages malloc/free automatically, eliminating a whole class of FFI leaks; the Rust core is memory-safe by language guarantee. The `System` mutex is still required — memory safety does not equal data-race freedom across FRB worker threads.[^27]
- **Testing tiers:**
  - Rust unit tests per shim module, including mutex contention / deadlock timeout.
  - Dart unit tests against a mockable domain interface, including all three `Reading<T>` variants and the `SysInfoException` hierarchy.
  - **`package:dart_sysinfo/testing.dart`** — first-party fakes (`FakeSysInfo` and one fake per domain), each field independently settable to any `Reading<T>` variant via simple constructors/builders. No Flutter dependency, no real native calls. Shipped alongside P1 in **M1**, not bolted on later, so it's available from the very first published version.
  - Integration tests on real devices/emulators per platform in CI.
  - Dart-only package test (`dart test` without Flutter SDK on the core package).
  - Example-app **manual QA:** hot restart with an active CPU stream (see §3.4).
- Run `cargo test -- --test-threads=1` for tests that *read OS counters via sysinfo*, per `sysinfo` guidance that process-level parallelism reduces reliability. Mutex stress is an exception documented next to the test.[^25]
- **No fabricated data:** unsupported / failed metrics return `ReadingUnsupported` / `ReadingUnavailable`; never synthesize values.[^24][^1]
- **Supply chain:** pin `sysinfo`, FRB, and toolchain versions; hash-verify **and** attestation-verify downloaded binaries; ABI handshake at load.[^5]
- **Apple store gate:** CI builds `apple-app-store` and asserts no prohibited APIs are linked.[^1]
- **Android / Play gate:** NDK r28+; permission-matrix lint (§2.5); example app does not claim supported-on-Android for permission-gated fields without the permission declared.
- **Lint gate:** `very_good_analysis`, zero warnings, active from **M0** (§10.1).
- **Doc coverage gate:** 100% dartdoc on public API, active from **M3/M4**, not before — see the phasing rationale in §7.2 and §5.7 (§9.3).

***

## 9. Developer Experience & Ecosystem

This section exists because the PRD's success metrics (§1.4) explicitly include first-run friction, testability, and discoverability — not just "does it compile."

### 9.1 Setup diagnostics (`doctor`)

Because the toolchain spans Rust, NDK, Xcode/CocoaPods, and (currently) Cargokit, setup failures without tooling produce cryptic native-build errors. `dart run dart_sysinfo:doctor` ships as part of **M0** and checks:

- Rust toolchain presence and version against `rust-toolchain.toml`.
- Android NDK presence, version (flags &lt;r28), and `ANDROID_NDK_ROOT`.
- Xcode / CocoaPods presence and version on macOS hosts.
- Cargokit/Native-Assets backend consistency for the current SDK.

Output is actionable (what's wrong, the exact command to fix it), and the README's troubleshooting section leads with "run `doctor` first."

### 9.2 Detecting a missing `dart_sysinfo_flutter`

A Flutter developer who adds only `dart_sysinfo` (forgetting the lifecycle package) still gets working snapshots — the failure mode (leaked native stream workers across hot restart) is invisible until it isn't. Mitigation, **debug builds only**:

- The core (`dart_sysinfo`) is and remains Flutter-unaware. It only exposes the plain idempotent-init signal from §3.4: "did this init call create fresh native state, or find state already running." It does not know about Flutter, hot restart, or lifecycle at all.
- `dart_sysinfo_flutter` — the only package that knows it's running under Flutter — checks that signal the moment it starts registering its lifecycle hook. If native state already existed *and* this is the first time this Flutter binding instance is registering, that combination means a hot restart happened previously without a proper `dispose()`.
- On that detection, `dart_sysinfo_flutter` logs a **one-time**, clear debug-console warning pointing back at itself/the docs (e.g. "make sure `dart_sysinfo_flutter` is initialized before use") — useful both for consumers who forgot to depend on the package at all (nothing will be there to catch it, so this specific warning only fires for consumers who *do* depend on it but wired it late/inconsistently) and for consumers who wired it correctly but still hit an edge case.
- **No behavior change in release builds** — this is a developer nudge, not a runtime feature, and must never add overhead or noise to production apps.

Note the residual gap: a consumer who never depends on `dart_sysinfo_flutter` at all gets no warning from anywhere, by construction — there's no Flutter-aware code running to emit one. That case is handled by documentation (README quickstart states plainly that Flutter apps need both packages), not by runtime detection, since the core must stay Flutter-free.

### 9.3 Discoverability & pub.dev score

Documentation and discoverability are CI-gated, not aspirational — but the doc-coverage gate specifically is phased in at M3/M4, not M0/M1, so it hardens the API once its shape is proven rather than taxing early iteration (see §7.2):

- **100% dartdoc coverage** on all public symbols, checked in CI (`dart doc` plus a coverage-check step) from **M3/M4** onward.[^36]
- Curated `topics:` in `pubspec.yaml` (e.g. `system-info`, `ffi`, `cross-platform`, `hardware`).[^37]
- `example/` maintained to score full pub.dev "example" points.
- `CHANGELOG.md` per published package in **Keep a Changelog** format, updated as part of the release checklist (§10.3), not after the fact.[^35]

**Name availability (verified at cross-functional sign-off, §14):** `dart_sysinfo`, `dart_sysinfo_flutter`, and the unprefixed `sysinfo` are all unclaimed on pub.dev as of this revision. Recommend publishing a minimal placeholder for `dart_sysinfo` early in M0 to prevent squatting, since pub.dev names cannot be reserved without publishing something.

***

## 10. Contributor Workflow & Release Engineering

Operationalizes the "low-friction contributor path" and "predictable evolution" goals from §1.3 — without this section, both become tribal knowledge.

### 10.1 Lint & style baseline

The monorepo standardizes on **`package:very_good_analysis`**[^34] via a single root `analysis_options.yaml` inherited by every package (`dart_sysinfo`, `dart_sysinfo_flutter`, `example/`). CI runs `dart analyze` and fails on **any** warning, not just errors — this is decided once, here, so it never becomes a PR-review argument.

### 10.2 Domain scaffolding generator

**Sequencing (deliberate):** the generator is **not** built speculatively before any domain exists. P1 (OS, CPU, memory — M1) is hand-built first, so the domain pattern is proven by three real examples rather than guessed. `tool/new_domain.dart` is then **extracted from that proven pattern** before M3, ahead of the first domains that actually use it (disks, network). Building it earlier risks templating the wrong shape and reworking both the generator and the domains it already scaffolded.

Once built, `tool/new_domain.dart <name>` generates, for a new domain:

- Dart interface + immutable model stub with `Reading<T>` fields in `packages/dart_sysinfo/lib/src/domains/<name>/`.
- A blank Rust `api/<name>.rs` module stub wired into the shim.
- Blank rows in the capability matrix (§6) and the Android permission matrix (§2.5).
- A fake stub in `testing.dart` (§8) and skeleton unit tests.

**CI check (also introduced alongside the generator, i.e. before M3, not M0):** a domain folder present without matching capability-matrix row, permission-matrix row, `testing.dart` fake, and tests **fails the build**. This is what makes "low-friction to add a domain" a guarantee rather than a hope, once there's a real pattern to enforce.

### 10.3 Release process & versioning

- **Lockstep versioning** for all Dart packages via melos: `dart_sysinfo` and `dart_sysinfo_flutter` bump together on every release; `dart_sysinfo_flutter`'s pubspec pins an exact-matching `dart_sysinfo` version range.
- **Native ABI** (the `DART_SYSINFO_ABI` integer, §7.3) bumps **independently**, only on breaking native-layout/FRB-signature changes.
- **CI ABI gate:** release automation fails if the Rust public API changed (detected via a checksum/diff of `frb_generated.rs` and the `api/` modules) but `abi.rs`'s version integer was not bumped.
- The full step-by-step release checklist (version bump, changelog update per §9.3, ABI check, tag, publish) lives in `CONTRIBUTING.md`.

### 10.4 Deprecation policy

- Deprecated public symbols are annotated `@Deprecated('use X instead, removed in vN.0.0')` and remain functional for **at least 2 minor releases** before removal in the next major version.
- Breaking changes in the upstream `sysinfo` Rust crate are **absorbed inside the Rust shim** whenever feasible, so they never reach the Dart API. Only when the shim genuinely cannot paper over an upstream break is it forwarded to Dart consumers — and then only as a documented deprecation or major-version change, never a silent behavior shift.

***

## 11. Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| FRB Native Assets **codegen** still beta; Flutter **hooks** themselves are stable at ≥3.38[^7][^5] | Build instability if we default too early | Transitional Cargokit default; Native Assets CI track; **defined sunset** (§3.3, M5) — not a permanent dual production system |
| iOS App Store rejection from prohibited APIs[^1] | Store blocker | `apple-app-store` feature flag as first-class build profile + CI gate[^1] |
| Play rejection / 16 KB page-size / undeclared permissions | Store / install blocker | NDK r28+; permission matrix; CI lint; no silent manifest merges |
| Blocking FFI freezes UI[^21] | Jank | Async-only public API; streams via `StreamSink`; `Isolate.run` for heavy work[^22] |
| Concurrent FRB workers + shared `System` | Data races / deadlock | `Mutex`/`RwLock` + contention test (§3.4) |
| Hot restart leaks native streams | Dev-mode resource leak / duplicate state | Idempotent init, `dispose()`, Flutter wiring, QA checklist, missing-package detection (§9.2) |
| Mobile hardware data gaps (sensors not exposed)[^25] | Feature gaps | Capability matrix + `Reading<T>` per field |
| Rust toolchain burden on consumers | Adoption friction | Prebuilt binaries with hash + attestation + ABI handshake[^5]; `doctor` tool (§9.1) |
| Compromised prebuilt artifact | Supply-chain compromise | Attestations, not hash-only; pin versions |
| ABI skew between Dart glue and downloaded `.so`/`.a` | Silent native crash | Load-time ABI check, throws `SysInfoAbiMismatchException`, CI ABI gate (§10.3) |
| Flutter SDK accidentally required by CLI users | Contradicts target users | Package split; M0 verify hook has no Flutter dependency[^28] |
| `sysinfo` C header too narrow | Feature ceiling | Custom Rust shim over full crate API, not the C header |
| No Web/WASM native-assets path[^4] | Platform gap | Explicit `platforms:` exclusion (§1.6), fails fast at build-resolution time |
| Windows ARM64 | Coverage gap | Best-effort only in v1 |
| Adding a `Reading<T>` variant later breaks every consumer's exhaustive switch | Hidden breaking change | Closed-variant policy: 3 variants forever within a major version (§5.2) |
| Consumers forget `dart_sysinfo_flutter`, leak native streams silently | Erodes trust ("worked in dev, weird later") | Debug-mode one-time detection + warning (§9.2) |
| `snapshot()` called from `build()` assumed cheap, actually a real native refresh every time | Jank, contradicts §1.4 latency goal | Per-domain TTL cache + `forceRefresh` (§5.5) |
| Unbounded stream interval (e.g. 1ms) drains battery / hammers native layer | Battery/perf foot-gun | Enforced/clamped minimum interval per platform, broadcast sharing (§5.4) |
| Version skew across `dart_sysinfo`, `dart_sysinfo_flutter`, native ABI | Confusing install/upgrade failures | Melos lockstep + independent CI-gated ABI bump (§10.3) |
| Global `SysInfo.instance` singleton complicates consumer unit tests | Adoption friction, flaky tests | `resetForTesting()` / `overrideInstance()` + `testing.dart` fakes (§5.6, §8) |
| Low pub.dev score / poor discoverability | Slower adoption despite good engineering | CI-gated doc coverage, topics, full-scoring example, Keep a Changelog (§9.3) |
| Upstream `sysinfo` Rust crate has a small maintainer base (bus-factor risk) | Stalled fixes or unmaintained dependency long-term | Breaking changes absorbed in the shim (§10.4); versions pinned; the shim is thin enough that forking `sysinfo` is a viable fallback if it's ever abandoned — accepted risk, revisit only if it materializes |

***

## 12. Milestones

1. **M0 — Scaffolding:** melos monorepo with **package split** (`dart_sysinfo` Flutter-free, `dart_sysinfo_flutter`, `packages/native/`), FRB **Cargokit** integration as default, example app with a **minimal FFI smoke test** (a trivial round-trip call proving the Rust↔Dart bridge works end-to-end — no domains exist yet) compiling on all 5 platforms, **verify** `dart pub get` on core without Flutter. Pin `rust-toolchain.toml`. NDK r28+ on Android jobs. `platforms:` excludes web (§1.6). Root `analysis_options.yaml` (`very_good_analysis`, zero-warning CI — active from M0; doc-coverage gate deliberately **not** yet, see §7.2). `dart run dart_sysinfo:doctor` (§9.1). `CONTRIBUTING.md` with release checklist and deprecation policy stubs. **No domain generator yet** — see M3.[^8][^28]

   **M0 exit criteria (go/no-go, added at Engineering sign-off — §14):** M0 is the first real validation of the whole architectural bet, not just plumbing. It is complete only when the FFI smoke test builds and round-trips cleanly on **all 5 target platforms** (Android, iOS, Linux, macOS, Windows) in CI, and `dart pub get`/`dart test` succeed on `dart_sysinfo` with no Flutter SDK present. If any platform cannot be made to build cleanly through Cargokit within M0, that is treated as an architecture-level signal requiring explicit reassessment (not a bug to route around silently) before committing M1 effort.
2. **M1 — P1 domains:** OS/System, CPU, Memory snapshots (TTL-cached, §5.5) + CPU load stream (broadcast, clamped interval, §5.4), **hand-built** (not generated — this is what the future generator will be extracted from, §10.2); `Reading<T>` (closed, with `when`/`maybeWhen`/`orElse`, §5.2); `SysInfoException` hierarchy (§5.3); `SysInfo.dispose()` / `resetForTesting()` / `overrideInstance()` + idempotent init reporting fresh-vs-existing state (§3.4); `Mutex`/`RwLock` + contention test; `package:dart_sysinfo/testing.dart` fakes for all P1 domains (§8); capability matrix; CI on min + intermediate + latest, plus the lint gate (doc-coverage gate still deferred); Apple store profile stub; Android permission matrix for P1 (likely empty).[^26]
3. **M2 — Native Assets track:** parallel `hook/build.dart` via `flutter_rust_bridge_hooks` / `native_toolchain_rust` on beta codegen; start the sunset clock only while this matrix is green.[^7]
4. **M3 — P2 domains:** **extract `tool/new_domain.dart` from the proven M1 pattern** and bring its CI domain-completeness check online (§10.2) — then use it for disks + network throughput streams; Android permission rows + lint for network; prebuilt-binary distribution with **hash + attestation + ABI handshake**; CI ABI gate live (§10.3); **100% dartdoc coverage gate goes live** (§7.2, §9.3) now that the P1 API shape is proven and P2 is being added on top of it.
5. **M4 — Store hardening + 1.0:** `apple-app-store` CI assertion, Play/NDK/permission gates, ffigen escape-hatch documentation, Flutter hot-restart QA documented, missing-package detection (§9.2, implemented entirely within `dart_sysinfo_flutter`) shipped, pub.dev discoverability polish (topics, full-scoring example, Keep-a-Changelog CHANGELOGs, §9.3), 1.0 pub.dev release of `dart_sysinfo` (+ `dart_sysinfo_flutter`). **1.0 may still default to Cargokit.**[^1]
6. **M5 — Native Assets default:** execute §3.3 sunset; demote Cargokit to unsupported fallback. Not a 1.0 blocker.

***

## 13. Decision log

Resolved before implementation; do not re-open without a major-version or milestone revision.

### 13.1 v1.0 → v1.1

| # | Decision | Resolution |
|---|---|---|
| 1 | SDK policy | Min Flutter 3.38.0 / Dart 3.10.0; dev/CI latest Flutter 3.47.4 / Dart 3.13.3; CI = min + latest + one intermediate. Invalid `3.47.0`+`3.13.3` pairing dropped. |
| 2 | Build backend | Cargokit is the **transitional** default. Native Assets is the **eventual** default after the §3.3 sunset. Not a permanent dual-production system. |
| 3 | Android NDK | **r28+** (16 KB pages / Play / Flutter 3.38 default). |
| 4 | Package split | Published `dart_sysinfo` (no `flutter:` constraint) + optional `dart_sysinfo_flutter`. M0 verifies the build hook is Flutter-free. |
| 5 | Native concurrency | Single shared `System` behind `Mutex`/`RwLock`; contention test. |
| 6 | Unsupported values | Public `Reading<T>`: `value` / `unsupported` / `unavailable`. Not `T?`. |
| 7 | Play Store | §2.5 permission matrix + CI/lint; no silent permission merges. |
| 8 | Prebuilts | Hash + **signed attestation** + **ABI handshake**. |
| 9 | Hot restart | Idempotent init, `SysInfo.dispose()`, Flutter wiring, example QA. |
| 10 | §5.3 example | Final API shape; network is P2 / M3, not M1. |

### 13.2 v1.1 → v1.2 (developer-experience & maintenance review)

| # | Decision | Resolution |
|---|---|---|
| 1 | Web platform behavior | Exclude `web` in `pubspec.yaml` `platforms:` (§1.6) — fails fast/clearly at build-resolution time; no runtime `ReadingUnsupported` claim for a platform the package can't compile on |
| 2 | `Reading<T>` extensibility | Closed forever at 3 variants for this major version (§5.2); new nuance is data, never a new variant |
| 3 | Streaming semantics | Broadcast, shared ref-counted poller per interval, enforced/clamped minimum interval, errors via `onError` (§5.4) |
| 4 | Release process | Melos lockstep Dart versioning + independently CI-gated ABI bumps; documented release checklist (§10.3) |
| 5 | Deprecation policy | `@Deprecated` ≥2 minor versions before removal; upstream `sysinfo` breaks absorbed in the shim when possible (§10.4) |
| 6 | Domain scaffolding | CLI generator (`tool/new_domain.dart`) + CI check enforcing matrix/test completeness (§10.2) |
| 7 | Lint baseline | `package:very_good_analysis`, repo-root shared config, CI fails on any warning (§10.1) |
| 8 | Testing story | `package:dart_sysinfo/testing.dart` with fakes + `Reading<T>` builders, shipped in M1 (§8) |
| 9 | Exception taxonomy | Sealed `SysInfoException` hierarchy — Load/AbiMismatch/Disposed/UnsupportedPlatform (§5.3) |
| 10 | Doctor tool | `dart run dart_sysinfo:doctor` in M0, referenced first in README (§9.1) |
| 11 | Snapshot caching | Per-domain default TTL cache + `forceRefresh: true` override (§5.5) |
| 12 | Singleton testability | `SysInfo.resetForTesting()` + `SysInfo.overrideInstance()`, `@visibleForTesting` (§5.6) |
| 13 | Pub.dev discoverability | CI-gated 100% dartdoc coverage, `topics:`, full-scoring example, Keep a Changelog (§9.3) |
| 14 | Missing `dart_sysinfo_flutter` | Debug-mode one-time runtime warning on undisposed hot restart (§9.2) |
| 15 | `Reading<T>` ergonomics | Full freezed-style helpers: `when`, `maybeWhen`, `orElse` (§5.2) |

### 13.3 v1.2 → v1.3 (consistency & sequencing pass)

| # | Decision | Resolution |
|---|---|---|
| 1 | §9.2 architecture contradiction | Core (`dart_sysinfo`) stays fully Flutter-unaware; it only exposes the fresh-vs-existing-state signal its idempotent init already needs (§3.4). `dart_sysinfo_flutter` alone reads that signal and decides whether to log the missing-lifecycle warning (§2.1, §9.2). |
| 2 | Domain scaffolding generator timing | Deferred: P1 domains (M1) are hand-built first; `tool/new_domain.dart` is extracted from that proven pattern before M3, not built speculatively in M0 (§10.2, M0/M1/M3 milestones). |
| 3 | Quality-gate timing | Split: `very_good_analysis` zero-warning lint active from **M0**. 100% dartdoc coverage and the domain-completeness CI check both deferred to **M3/M4**, once the API shape and domain pattern are proven (§7.2, §8, §9.3). |
| 4 | M0 example-app scope | Clarified as a minimal FFI round-trip smoke test — no domains exist until M1 (M0 milestone). |
| 5 | §5.7 example labeling | Softened from "final API shape" to "target API shape, validated during M1" to avoid implying a signature freeze before implementation. |

***

## 14. Cross-Functional Review & Sign-Off

Held before any implementation work, per role, to surface hidden blockers and stress-test assumptions ahead of formal approval. This is the gate that moves the PRD from Draft to Approved.

### 14.1 Engineering

**Assumptions stress-tested:**
- *"Rust + FRB + Cargokit will build cleanly across all 5 platforms."* This is a real bet, not a proven fact — it's the single biggest technical risk in the document, and M0 is the first time it gets tested for real by this team. Resolution: M0 is now explicitly framed as a **go/no-go validation gate**, not just plumbing work (see the M0 exit criteria added to §12). If any platform can't build cleanly, that's escalated before M1 investment, not silently patched around.
- *"The upstream `sysinfo` crate is a safe long-term dependency."* It's actively used and reasonably maintained, but has a small maintainer base. Resolution: accepted as a documented risk (§11) — the shim already absorbs upstream breaking changes (§10.4), and forking is a realistic fallback given how thin the shim is. No process change needed beyond recording it.
- *Timeline/staffing* (how long M0–M5 will take, who does Rust vs. Dart work) is explicitly **out of scope for this PRD** — that's a project-planning/resourcing exercise, not a product requirement. Noted, not blocking.

**Sign-off: APPROVE.** Architecture is sound, risks are enumerated with real mitigations (not hand-waves), and the single biggest unknown (cross-platform Rust/FFI build) now has an explicit validation checkpoint instead of being assumed away.

### 14.2 DX / API Design (standing in for UX/UI — this product's "user interface" is its public API)

**Assumptions stress-tested:**
- *"The package names are actually available."* This was checked live for this sign-off: `dart_sysinfo`, `dart_sysinfo_flutter`, and `sysinfo` are all unclaimed on pub.dev. This closes out a gap that had been open since the very first PRD review and never explicitly verified. Recorded in §9.3, with a recommendation to publish an early placeholder to prevent squatting.
- *API ergonomics* (`Reading<T>`, `SysInfoException`, streaming/caching contracts, testability hooks) were already stress-tested across the two prior review rounds — no new issues surfaced here. Terminology (Reading, Snapshot, Domain, Capability) is used consistently throughout.
- *Package-split discoverability* (would a Flutter dev searching pub.dev easily find both `dart_sysinfo` and `dart_sysinfo_flutter`?) is adequately covered by the `topics:`/README guidance in §9.2–§9.3.

**Sign-off: APPROVE.** No open API-design concerns; the one real open item (name availability) is now closed.

### 14.3 QA

**Assumptions stress-tested:**
- *"Real devices/emulators per platform in CI" (§8) is achievable.* The PRD correctly states the requirement but doesn't pick a specific device farm/vendor (e.g. Firebase Test Lab, physical lab, cloud emulators) — and it shouldn't; that's an infrastructure/tooling choice for M0 kickoff, not a product requirement. Flagged as an **open execution question for M0**, explicitly not a PRD blocker.
- *"Every domain has a clear Definition of Done."* Confirmed already present and sufficient (§6: capability-matrix row, permission row, store-profile impact, TTL/interval defaults, `Reading<T>` coverage).
- *Release-blocking bug policy for 1.0* (a formal severity taxonomy) is not defined. Considered and deliberately **not** added — a formal triage taxonomy for a project at this stage would be process overhead without current value; "no known data-corruption or crash bugs at the 1.0 tag" is sufficient judgment to apply informally at M4.
- *Testing tiers already cover the exception hierarchy and all `Reading<T>` variants* (§8) — confirmed sufficient.

**Sign-off: APPROVE**, with one execution note carried forward (not a PRD change): decide on the concrete device/emulator matrix (cloud farm vs. physical vs. emulator-only per platform) at M0 kickoff.

### 14.4 Final disposition

| Role | Decision | Conditions |
|---|---|---|
| Engineering | Approve | M0 treated as an explicit go/no-go gate (§12) |
| DX / API Design | Approve | None outstanding — name availability confirmed |
| QA | Approve | Device/emulator strategy to be picked at M0 kickoff (execution detail, not a PRD gap) |

**Overall: APPROVED.** No conditions require a PRD change beyond what's already incorporated in this revision (M0 exit criteria, `sysinfo` bus-factor risk, confirmed name availability). The document is cleared to move from Draft to Approved, and implementation may begin at M0.

***

## References

1. [sysinfo - Rust - Docs.rs](https://docs.rs/sysinfo/latest/sysinfo/) - sysinfo

2. [Flutter or Dart: How to I get device information such as CPU ...](https://stackoverflow.com/questions/55859730/flutter-or-dart-how-to-i-get-device-information-such-as-cpu-count-total-memory) - Using Flutter, I would like to get device information details such as CPU count, bitness, Total Memo...

3. [flutter_perf_monitor | Flutter package](https://pub.dev/packages/flutter_perf_monitor) - A lightweight package to track real-time performance metrics in your Flutter applications, including...

4. [Build hook for Flutter Web? · Issue #138992 · flutter/flutter](https://github.com/flutter/flutter/issues/138992) - Is there an existing issue for this? I have searched the existing issues I have read the guide to fi...

5. [Bind to native code using FFI - Flutter documentation](https://docs.flutter.dev/platform-integration/bind-native-code) - To use native code in your Flutter program, use the dart:ffi library with the package_ffi template.

6. [Flutter Native Assets Rust with flutter_rust_bridge v2](https://www.appxiom.com/blogs/flutter-native-assets-rust/) - Ship high performance Flutter native code without plugins. Learn flutter native assets rust with flu...

7. [Native assets | flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/manual/integrate/native-assets) - Native Assets are the Dart/Flutter build hooks mechanism for building and bundling native code asset...

8. [Matej Knopp](https://matejknopp.com/) - Step by step instructions for building a Flutter FFI plugin with Rust code and Cargokit. 1. Create a...

9. [flutter_rust_bridge | Dart package](https://pub.dev/packages/flutter_rust_bridge) - Async Rust: Support asynchronous Rust. Async & sync, Async Dart to avoid blocking the main thread, a...

10. [ffigen - Git at Google](https://dart.googlesource.com/ffigen/) - This bindings generator can be used to call C code -- or code in another language that compiles to C...

11. [ffigen | Dart package](https://pub.dev/packages/ffigen) - This bindings generator can be used to call C code or code in another language that compiles to C mo...

12. [flutter/dart-setup-ffi-assets | SkillRepo](https://skillrepo.dev/skills/flutter/dart-setup-ffi-assets) - This skill guides agents in compiling and packaging C/C++ source code into Dart Native Assets using ...

13. [Cargokit | flutter_rust_bridge - fzyzcjy.github.io](https://cjycode.com/flutter_rust_bridge/manual/integrate/cargokit) - flutterrustbridge uses Cargokit for seamless integration of cargo build

14. [cargokit/docs/architecture.md at main · irondash/cargokit](https://github.com/irondash/cargokit/blob/main/docs/architecture.md) - Integrate cargo build with flutter plugins and applications. - irondash/cargokit

15. [code_assets | Dart package - Pub.dev](https://pub.dev/packages/code_assets) - This package is used in a build hook ( hook/build.dart ) to inform the Dart and Flutter SDKs about t...

16. [Hooks - Dart programming language](https://dart.dev/tools/hooks) - With build hooks, a package can do things such as compile or download native assets such as C or Rus...

17. [hooks | Dart package - Pub.dev](https://pub.dev/packages/hooks) - You can use a build hook to do things such as compile or download code assets, and then call these a...

18. [Quickstart | flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/quickstart) - If you like to setup in one command:

19. [flutter_rust_bridge_codegen create/integrate command](https://cjycode.com/flutter_rust_bridge/manual/integrate/builtin) - As is seen in the overview and quickstart,

20. [High-level memory-safe binding generator for Flutter/Dart <-> Rust | RustRepo](https://rustrepo.com/repo/fzyzcjy-flutter_rust_bridge) - fzyzcjy/flutter_rust_bridge, flutter_rust_bridge: High-level memory-safe binding generator for Flutt...

21. [Talking to Native: FFI, Pigeon, and Knowing Which One You Need](https://dev.to/devshakib/talking-to-native-ffi-pigeon-and-knowing-which-one-you-need-37pj) - Flutter native interop compared: dart:ffi vs Pigeon vs MethodChannel. When to use each, type-safe in...

22. [Overview | flutter_rust_bridge](https://cjycode.com/flutter_rust_bridge/guides/concurrency/overview) - Async Dart + Async Rust: Dart is non-blocking, Rust uses async runtime; Sync Dart + Sync Rust: Dart ...

23. [Possible Solution for Async Rust Functions · Issue #966 · fzyzcjy/flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge/issues/966) - Is your feature request related to a problem? Please describe. According to the documentation Sectio...

24. [GitHub - sebhildebrandt/systeminformation: System Information Library for Node.JS](https://github.com/sebhildebrandt/systeminformation) - sebhildebrandt / **systeminformation** Public

25. [GuillaumeGomez/sysinfo: Cross-platform library to fetch ...](https://github.com/guillaumegomez/sysinfo) - GuillaumeGomez / **sysinfo** Public

26. [Flutter and Android Builds | ncc2025seisaku/AKARI-Proxy | DeepWiki](https://deepwiki.com/ncc2025seisaku/AKARI-Proxy/8.2-flutter-and-android-builds) - This document details the Flutter CI/CD pipeline and Android release build process for the AKARI-Pro...

27. [flutter_rust_bridge 1.82.6 | Dart package - Pub.dev](https://pub.dev/packages/flutter_rust_bridge/versions/1.82.6) - High-level memory-safe binding generator for Flutter/Dart <-> Rust

28. [Using flutter_rust_bridge in Dart-only apps](https://cjycode.com/flutter_rust_bridge/guides/miscellaneous/pure-dart) - FRB without a Flutter SDK dependency.

29. [Flutter versions / Dart pairing](https://flutterreleases.com/flutter-versions/) - Flutter 3.47.0 ships Dart 3.13.0; Dart 3.13.3 appears in 3.47.3+.

30. [Developing packages and plugins](https://docs.flutter.dev/packages-and-plugins/developing-packages) - Native Assets / `package_ffi` with `hook/build.dart` from Flutter 3.38.

31. [What’s new in Flutter 3.38](https://flutter.dev/blog/whats-new-in-flutter-3.38) - Default Android NDK r28 (16 KB pages), Java 17.

32. [Bind to native code using FFI (CN mirror cited in prior notes)](https://docs.flutter.cn/platform-integration/bind-native-code.md) - `package_ffi` + build hooks from 3.38 / Dart 3.10.

33. [Flutter SDK archive](https://docs.flutter.dev/install/archive) - Stable lines 3.38, 3.41, 3.44, 3.47.

34. [very_good_analysis | Dart package](https://pub.dev/packages/very_good_analysis) - Stricter-than-default lint rules used as the repo's shared `analysis_options.yaml` baseline.

35. [Keep a Changelog](https://keepachangelog.com/) - CHANGELOG.md format standard adopted for `dart_sysinfo` and `dart_sysinfo_flutter`.

36. [dart doc | Dart](https://dart.dev/tools/dart-doc) - dartdoc generation and public-API documentation coverage tooling.

37. [Pub.dev package scoring](https://pub.dev/help/scoring) - Scoring factors (topics, example, documentation) targeted by §9.3.
