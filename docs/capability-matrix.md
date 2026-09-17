# P1 capability matrix

**Story:** [EPICS.md M1-13](../EPICS.md) — capability matrix + Android permission rows (P1)  
**Spec:** [PRD.md §2.5](../PRD.md), [PRD.md §6](../PRD.md); field detail in [TDD.md §4.1–§4.3](../TDD.md)

This document is the canonical capability and Android permission record for P1
domains (OS, CPU, Memory). Values match the hand-built M1 implementations in
`packages/dart_sysinfo`.

## Capability matrix (P1)

| Domain | Snapshot TTL | Stream | Min stream interval | Platforms | Apple store-profile impact | Notable `Reading<T>` fields |
|---|---|---|---|---|---|---|
| `os` | 2000 ms | none | — | Android, iOS, macOS, Linux, Windows (web excluded per PRD §1.6) | None — P1 OS fields do not require prohibited APIs | `name`, `kernelVersion`, `osVersion`, `longOsVersion`, `hostName` → `ReadingUnavailable` when absent; `loadAverage` → `ReadingUnsupported` on Windows |
| `cpu` | 500 ms | `cpu.load()` (broadcast, ref-counted) | 200 ms on Android/iOS; 50 ms on desktop | Android, iOS, macOS, Linux, Windows | None — P1 CPU fields do not require prohibited APIs | `physicalCoreCount` → `ReadingUnavailable` when not detectable; `globalUsagePercent` → `ReadingUnavailable` on first sample after init; `cores` → `ReadingUnsupported` when enumeration restricted (Android API levels per `sysinfo`) |
| `memory` | 500 ms | none | — | Android, iOS, macOS, Linux, Windows | None — P1 memory fields do not require prohibited APIs | `cgroupLimits` → `ReadingUnsupported` on non-Linux; `ReadingUnavailable` on Linux when absent; on Windows/FreeBSD, `freeMemoryBytes` and `availableMemoryBytes` are identical (documented platform behavior, not hidden) |

**Field-level mapping:** see [TDD.md §4.1–§4.3](../TDD.md) for the complete Dart field → `sysinfo` source → `Reading<T>` table for each domain.

**Apple store profile note:** the `apple-app-store` Cargo feature (M1-14) is a
first-class build dimension for App Store compliance on later domains. It does
not restrict any P1 OS/CPU/Memory field at this milestone.

## Android permission matrix (P1)

Per [PRD.md §2.5](../PRD.md):

| Domain | Permissions merged by `dart_sysinfo` | Consumer obligation |
|---|---|---|
| `os` | **None** | None beyond normal app process |
| `cpu` | **None** | None beyond normal app process |
| `memory` | **None** | None beyond normal app process |

**Policy:** the published packages must **not** merge extra Android permissions
into the consumer app by default. Each domain that would need a permission
documents it here, exposes it on the capability matrix, and returns
`ReadingUnsupported` / `ReadingUnavailable` when the permission is absent.
Future permission-gated domains (e.g. network in P2) require a matching docs
update and consumer manifest declaration — never a silent plugin merge.

## Manifest audit (P1)

| Package | Manifest | Permissions declared |
|---|---|---|
| `dart_sysinfo` | [`packages/dart_sysinfo/android/src/main/AndroidManifest.xml`](../packages/dart_sysinfo/android/src/main/AndroidManifest.xml) | Empty — no `<uses-permission>` entries |
| Example app | [`example/android/app/src/main/AndroidManifest.xml`](../example/android/app/src/main/AndroidManifest.xml) | No sysinfo-related permissions |

Audited 2026-09-17 as part of M1-13.

## Future domains

P2+ domains (disks, network, components, battery, processes, etc.) will add
rows to both tables when they ship, per [PRD.md §6](../PRD.md) domain
Definition of Done. A domain-completeness CI check (M3-02) will enforce that
every new domain folder has matching capability-matrix and permission-matrix
rows before merge.
