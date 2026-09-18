use std::sync::Arc;

use dart_sysinfo_native::shim::state;

#[test]
fn init_returns_created_fresh_on_first_call() {
    state::dispose();
    let result = state::init();
    assert!(result.created_fresh);
    state::dispose();
}

#[test]
fn init_is_idempotent() {
    state::dispose();
    let first = state::init();
    assert!(first.created_fresh);

    let second = state::init();
    assert!(!second.created_fresh);

    state::dispose();
}

#[test]
#[should_panic(expected = "dart_sysinfo native state accessed before init()")]
fn dispose_clears_state() {
    state::dispose();
    state::init();
    state::dispose();
    let _ = state::state();
}

#[test]
fn dispose_then_init_recreates_fresh() {
    state::dispose();
    state::init();
    state::dispose();

    let result = state::init();
    assert!(result.created_fresh);

    state::dispose();
}

#[test]
fn abi_version_is_constant() {
    state::dispose();
    let first = state::init();
    assert_eq!(first.abi_version, 2);

    let second = state::init();
    assert_eq!(second.abi_version, 2);

    state::dispose();
}

#[test]
fn state_returns_live_system_after_init() {
    state::dispose();
    state::init();

    let shared: Arc<state::SharedState> = state::state();
    assert!(shared.system.read().is_ok());

    state::dispose();
}
