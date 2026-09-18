# M0-12: pub.dev publish deferral

**Story:** [EPICS.md M0-12](../../EPICS.md) — reserve `dart_sysinfo` on pub.dev  
**Decision:** Defer pub.dev placeholder during M0; document wait with owner and date.

## Record

| Field | Value |
|---|---|
| **Decision** | Do not publish a placeholder to pub.dev during M0 |
| **Owner** | mvitlov (repository maintainer) |
| **Decision date** | 2026-09-17 |
| **Revisit by** | Before **M4** 1.0 pub.dev publish, or immediately if either package name is claimed by a third party |
| **Names in scope** | `dart_sysinfo` (M0-12); `dart_sysinfo_flutter` (publish together at 1.0) |

## Name availability snapshot (2026-09-17)

Checked via pub.dev API:

| Package | API URL | Result |
|---|---|---|
| `dart_sysinfo` | `https://pub.dev/api/packages/dart_sysinfo` | **404 Not Found** (unclaimed) |
| `dart_sysinfo_flutter` | `https://pub.dev/api/packages/dart_sysinfo_flutter` | **404 Not Found** (unclaimed) |

Re-run before any publish:

```bash
curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/dart_sysinfo"
curl -s -o /dev/null -w "%{http_code}" "https://pub.dev/api/packages/dart_sysinfo_flutter"
```

Expect `404` while names remain available.

## Rationale

- **Monorepo layout:** `dart_sysinfo` uses `resolution: workspace` and `publish_to: none`; publishing requires an isolated export or melos publish flow not yet set up.
- **Native crate path:** Cargokit references `../../native` (sibling of `packages/dart_sysinfo`). A pub.dev tarball contains only the Dart package — not `packages/native` — so a placeholder would not build for pub.dev consumers and could mislead adopters.
- **PRD §9.3 trade-off:** Early placeholder reduces squatting risk; we accept that risk until a **consumable** 1.0 publish (M4) rather than shipping a non-functional package.
- **Scope:** M0-12 is satisfied by this documented deferral per EPICS acceptance criteria (publish **or** documented wait with owner and date).

## Risk accepted

- **`dart_sysinfo` and `dart_sysinfo_flutter` remain claimable** on pub.dev until we publish.
- Mitigation: revisit trigger includes immediate action if squatting is observed; PRD §14 recorded names as unclaimed at sign-off.

## Exit criteria to publish (M4+)

Before the first consumer-facing pub.dev release:

1. M0 exit gate green; M1 P1 domains shipped and API shape stable toward 1.0. *(M1 complete in repo — see EPICS.md.)*
2. Native layout consumable from pub.dev (in-package Rust tree and/or prebuilt binaries per M3/M4).
3. Package metadata: `README.md`, `LICENSE`, `repository` / `homepage` / `issue_tracker` in pubspec.
4. Re-verify both names unclaimed on pub.dev.
5. Resolve workspace publish wiring (`publish_to`, melos publish or isolated export).
6. `flutter pub publish --dry-run` then publish from a maintainer account with pub.dev uploader access.

## When we publish (M4+) — checklist stub

1. Re-verify `dart_sysinfo` / `dart_sysinfo_flutter` unclaimed on pub.dev.
2. Add package `README.md`, root `LICENSE`, and pubspec `repository` / `homepage` / `issue_tracker`.
3. Resolve `resolution: workspace` / `publish_to: none` for publish (melos publish or isolated export).
4. Resolve native crate path for pub consumers (`../native` → in-package or prebuilts per M3/M4).
5. `flutter pub publish --dry-run`, then publish lockstep versions of both packages.

If the team later chooses an early placeholder (PRD §9.3 recommendation), treat that as a new story — not a reversal of this record without an updated decision doc.
