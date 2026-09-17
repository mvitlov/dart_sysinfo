# Example app manual QA (M1-16)

Traceability: [EPICS.md](../EPICS.md) M1-16 → [PRD.md](../PRD.md) §3.4, §8 →
[TDD.md](../TDD.md) §5.2 (Manual QA row).

This checklist verifies that Flutter hot restart does not leak duplicate native
CPU load stream workers when `dart_sysinfo_flutter` lifecycle glue is wired
correctly.

## Prerequisites

- FVM toolchain installed (see [`.fvmrc`](../.fvmrc))
- Debug mode — hot restart is a development workflow
- Primary target: **macOS desktop** (`fvm flutter run -d macos`)
- Optional additional sign-off rows: Linux, Windows

## Bootstrap order (must match example app)

```dart
WidgetsFlutterBinding.ensureInitialized();
await initDartSysinfoBridge();
await DartSysinfoFlutter.ensureInitialized();
// then SysInfo.instance / runApp
```

## Procedure

1. From `example/`, launch the app:
   ```bash
   fvm flutter run -d macos
   ```
   Optional log-friendly mode (auto-starts the stream; still complete steps 3–8
   manually or verify tick logs):
   ```bash
   fvm flutter run -d macos --dart-define=QA_AUTO_START=true
   ```
   Tick events print as `[CPU_LOAD] tick N` in the debug console.
2. Tap **Refresh** on OS, Memory, and CPU — confirm real data appears (not all
   `unavailable`).
3. Tap **Start** on the CPU load stream — confirm the tick counter increments
   about once per second.
4. Note the tick count at T₀; wait 5 seconds; confirm roughly 5 new ticks (not
   ~10).
5. Press **`R`** (hot restart) in the terminal or IDE **while the stream is
   active**.
6. After the UI rebuilds, tap **Start** on the CPU load stream again.
7. Wait 5 seconds — confirm the tick rate is still ~1/sec (duplicate workers
   would show ~2/sec).
8. Repeat steps 5–7 **three times**.
9. Optional negative control (document only — do not ship): comment out
   `DartSysinfoFlutter.ensureInitialized()` in `example/lib/main.dart` and repeat
   step 7 to observe a doubled tick rate. Revert before committing.

## Pass criteria

- No crash on hot restart.
- Tick rate remains ~1/sec after each restart cycle.
- Streams resume or fail closed with a visible error — never silently leak.
- Optional: Activity Monitor / `top` shows no runaway CPU from orphaned workers.

## Sign-off

| Date | Platform | Tester | Result | Notes |
|---|---|---|---|---|
| 2026-09-17 | macOS | agent | PASS | 3 hot restarts with active stream; `[CPU_LOAD]` ticks ~1/sec after each cycle |

Link from [CONTRIBUTING.md](../CONTRIBUTING.md) and [example/README.md](../example/README.md).
