use dart_sysinfo_native::api::memory;
use dart_sysinfo_native::shim::state;

fn reset_state() {
    state::dispose();
    state::init();
}

#[test]
fn memory_snapshot_returns_nonzero_total_on_host() {
    reset_state();
    let snapshot = memory::memory_snapshot();
    assert!(snapshot.total_memory_bytes > 0);
    state::dispose();
}

#[test]
fn memory_snapshot_maps_all_seven_plain_fields() {
    reset_state();
    let snapshot = memory::memory_snapshot();

    assert!(snapshot.total_memory_bytes > 0);
    let _ = snapshot.free_memory_bytes;
    let _ = snapshot.available_memory_bytes;
    let _ = snapshot.used_memory_bytes;
    let _ = snapshot.total_swap_bytes;
    let _ = snapshot.free_swap_bytes;
    let _ = snapshot.used_swap_bytes;

    state::dispose();
}

#[test]
fn memory_snapshot_cgroup_unsupported_on_non_linux() {
    reset_state();
    let snapshot = memory::memory_snapshot();

    #[cfg(not(target_os = "linux"))]
    {
        assert!(!snapshot.cgroup_limits.supported);
        assert!(snapshot.cgroup_limits.value.is_none());
    }

    #[cfg(target_os = "linux")]
    {
        let _ = snapshot.cgroup_limits;
    }

    state::dispose();
}

#[test]
fn memory_snapshot_cgroup_supported_on_linux() {
    reset_state();
    let snapshot = memory::memory_snapshot();

    #[cfg(target_os = "linux")]
    {
        assert!(snapshot.cgroup_limits.supported);
    }

    #[cfg(not(target_os = "linux"))]
    {
        let _ = snapshot.cgroup_limits;
    }

    state::dispose();
}
