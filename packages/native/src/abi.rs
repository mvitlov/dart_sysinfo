//! ABI/version tag for Dart↔native handshake.

/// Monotonic ABI integer; bump on any breaking native layout / FRB signature
/// change (PRD §7.3). Full handshake wiring lands in M1-05.
pub const DART_SYSINFO_ABI: u32 = 1;
