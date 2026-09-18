use dart_sysinfo_native::api::network;
use dart_sysinfo_native::shim::state;

fn reset_state() {
    state::dispose();
    state::init();
}

#[test]
fn network_snapshot_does_not_panic_after_init() {
    reset_state();
    let snapshot = network::network_snapshot();
    let _ = snapshot.interfaces;
    state::dispose();
}

#[test]
fn network_snapshot_maps_interface_fields_when_present() {
    reset_state();
    let snapshot = network::network_snapshot();

    if let Some(first) = snapshot.interfaces.first() {
        assert!(!first.name.is_empty());
        let _ = first.mac_address;
        let _ = first.ip_networks;
        let _ = first.mtu;
        let _ = first.operational_state;
        let _ = first.cumulative.total_received_bytes;
    }

    state::dispose();
}
