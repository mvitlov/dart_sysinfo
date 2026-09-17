//! Shared native state and idempotent init/dispose (TDD §2.1).

use std::sync::{Arc, Mutex, RwLock};

use sysinfo::System;

/// Shared long-lived `sysinfo::System` guarded for concurrent domain reads.
pub struct SharedState {
    /// Inner system handle contended by domain snapshot and stream workers.
    pub system: RwLock<System>,
}

impl SharedState {
    fn new() -> Self {
        Self {
            system: RwLock::new(System::new()),
        }
    }
}

static STATE: Mutex<Option<Arc<SharedState>>> = Mutex::new(None);

/// Result of [`init`]. `created_fresh` is the platform-agnostic signal that
/// `dart_sysinfo_flutter` reads to detect an un-disposed hot restart (PRD §3.4).
pub struct StateInitResult {
    /// Whether this call created new native state (`true`) or reused existing
    /// state (`false`).
    pub created_fresh: bool,
    /// ABI version embedded in the native library for Dart handshake (M1-05).
    pub abi_version: u32,
}

/// Idempotently initializes shared native state.
pub fn init() -> StateInitResult {
    let mut guard = STATE.lock().expect("state mutex poisoned");
    let created_fresh = guard.is_none();
    if guard.is_none() {
        *guard = Some(Arc::new(SharedState::new()));
    }
    StateInitResult {
        created_fresh,
        abi_version: crate::abi::DART_SYSINFO_ABI,
    }
}

/// Tears down shared native state so a later [`init`] can recreate it cleanly.
pub fn dispose() {
    let mut guard = STATE.lock().expect("state mutex poisoned");
    *guard = None;
}

/// Internal accessor used by domain modules after [`init`].
///
/// Not exported through FRB; public for in-crate domain modules and tests.
pub fn state() -> Arc<SharedState> {
    let maybe_state = STATE
        .lock()
        .expect("state mutex poisoned")
        .clone();
    maybe_state.expect("dart_sysinfo native state accessed before init()")
}
