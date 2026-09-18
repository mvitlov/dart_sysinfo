//! Compile and runtime check for the App Store build profile (M1-14).
//!
//! Run:
//! ```bash
//! cd packages/native && cargo test --features apple-app-store --test apple_app_store -- --test-threads=1
//! ```

use dart_sysinfo_native::api::{cpu, disks, memory, network, os};
use dart_sysinfo_native::shim::state;

fn reset_state() {
    state::dispose();
    state::init();
}

#[test]
fn p1_snapshots_compile_and_run_with_apple_app_store_feature() {
    reset_state();

    let cpu_snapshot = cpu::cpu_snapshot();
    assert!(!cpu_snapshot.architecture.is_empty());

    let memory_snapshot = memory::memory_snapshot();
    assert!(memory_snapshot.total_memory_bytes > 0);

    let os_snapshot = os::os_snapshot();
    assert!(!os_snapshot.distribution_id.is_empty());

    let _disks_snapshot = disks::disks_snapshot();

    let _network_snapshot = network::network_snapshot();

    state::dispose();
}
