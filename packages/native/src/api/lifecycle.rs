//! Native lifecycle entry points exposed to Dart via FRB.

/// FRB-facing init result returned to Dart after the first native round-trip.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct InitResult {
    /// Whether this init created fresh native state.
    pub created_fresh: bool,
    /// ABI version of the loaded native library.
    pub abi_version: u32,
}

/// Initializes shared native state idempotently.
#[flutter_rust_bridge::frb(sync)]
pub fn init() -> InitResult {
    let result = crate::shim::state::init();
    InitResult {
        created_fresh: result.created_fresh,
        abi_version: result.abi_version,
    }
}

/// Disposes shared native state so a later init can recreate it cleanly.
#[flutter_rust_bridge::frb(sync)]
pub fn dispose() {
    crate::shim::state::dispose();
}
