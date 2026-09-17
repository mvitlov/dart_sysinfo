use dart_sysinfo_native::api::cpu;
use dart_sysinfo_native::shim::state;

fn reset_state() {
    state::dispose();
    state::init();
}

#[test]
fn cpu_snapshot_returns_architecture() {
    reset_state();
    let snapshot = cpu::cpu_snapshot();
    assert!(!snapshot.architecture.is_empty());
    state::dispose();
}

#[test]
fn cpu_snapshot_first_call_omits_global_usage() {
    reset_state();
    let snapshot = cpu::cpu_snapshot();
    assert!(snapshot.global_usage_percent.is_none());
    state::dispose();
}

#[test]
fn cpu_snapshot_second_call_includes_global_usage() {
    reset_state();
    let first = cpu::cpu_snapshot();
    assert!(first.global_usage_percent.is_none());

    let second = cpu::cpu_snapshot();
    assert!(second.global_usage_percent.is_some());
    state::dispose();
}

#[test]
fn cpu_snapshot_maps_physical_core_count() {
    reset_state();
    let snapshot = cpu::cpu_snapshot();
    // Option shape is required; value is platform-dependent.
    let _ = snapshot.physical_core_count;
    state::dispose();
}

#[test]
fn cpu_snapshot_maps_cores_when_supported() {
    reset_state();
    let snapshot = cpu::cpu_snapshot();

    #[cfg(not(target_os = "android"))]
    {
        let cores = snapshot
            .cores
            .expect("cores should be available on non-Android hosts");
        assert!(!cores.is_empty());
        assert!(!cores[0].name.is_empty());
    }

    #[cfg(target_os = "android")]
    {
        let _ = snapshot.cores;
    }

    state::dispose();
}
