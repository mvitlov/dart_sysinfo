# Apple store profile (`apple-app-store`)

**Story:** [EPICS.md M1-14](../EPICS.md) — Apple store-profile stub  
**Spec:** [PRD.md §2.4](../PRD.md)  
**Related:** [docs/capability-matrix.md](./capability-matrix.md)

Apple restricts which APIs may be linked into binaries distributed through the
App Store. The upstream `sysinfo` crate is not App Store compatible by default.
This repository exposes an opt-in Cargo feature that enables `sysinfo`'s
store-safe build profile.

## What the feature does

The `apple-app-store` feature in [`packages/native/Cargo.toml`](../packages/native/Cargo.toml)
forwards to `sysinfo/apple-app-store`, which also enables `sysinfo`'s
`apple-sandbox` feature. That disables APIs Apple prohibits in App Store
binaries on macOS and iOS.

## P1 impact

OS, CPU, and Memory snapshots remain available under the store profile. No P1
field is restricted at this milestone — see the capability matrix for per-field
`Reading<T>` platform notes that apply regardless of store profile.

## P2 impact (disks, M3-03)

The disks snapshot domain (`SysInfo.disks.snapshot()`) also remains available
under the store profile. Volume listing does not require prohibited APIs; mobile
sandboxes may still return a subset of volumes or an empty list.

## Local verification

From the repository root:

```bash
cd packages/native && cargo test --features apple-app-store --test apple_app_store -- --test-threads=1
```

The integration test is gated with `required-features = ["apple-app-store"]`, so
the default `cargo test` suite is unchanged unless the feature is explicitly
enabled.

## Apple-target compile checks (manual)

Maintainers with Apple Rust targets installed can cross-compile the native
crate:

```bash
cd packages/native
cargo build --features apple-app-store --target aarch64-apple-ios
cargo build --features apple-app-store --target aarch64-apple-darwin
```

These checks are manual in M1-14. Automated CI assertion is deferred to
[M4-01](../EPICS.md) (prohibited-API link scan).

## Cargokit / Flutter store builds

Default debug and CI builds use the standard profile (no store feature). For App
Store release builds, maintainers may add `extra_flags` to
[`packages/native/cargokit.yaml`](../packages/native/cargokit.yaml) **release**
configuration only:

```yaml
cargo:
  release:
    toolchain: stable
    extra_flags:
      - --features
      - apple-app-store
```

On non-Apple targets the flag is effectively a compile-time no-op for P1 code
paths; it is primarily intended for iOS and macOS App Store submission.

Do not enable this in the committed `cargokit.yaml` until store release
pipelines are validated (M4-01).

## Deferred to M4-01

- CI job that builds with `apple-app-store` on Apple targets
- Assertion that no prohibited APIs are linked (`nm` / `otool` scan)
