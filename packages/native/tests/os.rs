use dart_sysinfo_native::api::os;
use dart_sysinfo_native::shim::state;

fn reset_state() {
    state::dispose();
    state::init();
}

#[test]
fn os_snapshot_returns_nonempty_distribution_id() {
    reset_state();
    let snapshot = os::os_snapshot();
    assert!(!snapshot.distribution_id.is_empty());
    state::dispose();
}

#[test]
fn os_snapshot_maps_plain_fields() {
    reset_state();
    let snapshot = os::os_snapshot();

    assert!(!snapshot.kernel_long_version.is_empty());
    let _ = snapshot.uptime_seconds;
    let _ = snapshot.boot_time_seconds;
    let _ = snapshot.distribution_id_like;

    state::dispose();
}

#[test]
fn os_snapshot_maps_reading_string_fields() {
    reset_state();
    let snapshot = os::os_snapshot();

    let _ = snapshot.name;
    let _ = snapshot.kernel_version;
    let _ = snapshot.os_version;
    let _ = snapshot.long_os_version;
    let _ = snapshot.host_name;

    state::dispose();
}

#[test]
fn os_snapshot_load_average_unsupported_on_windows() {
    reset_state();
    let snapshot = os::os_snapshot();

    #[cfg(target_os = "windows")]
    {
        assert!(!snapshot.load_average.supported);
        assert!(snapshot.load_average.value.is_none());
    }

    #[cfg(not(target_os = "windows"))]
    {
        let _ = snapshot.load_average;
    }

    state::dispose();
}

#[test]
fn os_snapshot_load_average_supported_on_non_windows() {
    reset_state();
    let snapshot = os::os_snapshot();

    #[cfg(not(target_os = "windows"))]
    {
        assert!(snapshot.load_average.supported);
    }

    #[cfg(target_os = "windows")]
    {
        let _ = snapshot.load_average;
    }

    state::dispose();
}
