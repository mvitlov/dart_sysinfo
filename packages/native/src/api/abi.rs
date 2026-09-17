//! ABI/version exports exposed to Dart via FRB (TDD §2.5).

/// Returns the native crate semver embedded at compile time (PRD §7.3).
#[flutter_rust_bridge::frb(sync)]
pub fn native_crate_version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
