//! Network domain API (TDD §2.1, §2.3, §4.5).

use std::sync::Arc;
use std::thread;
use std::time::Duration;

use sysinfo::{InterfaceOperationalState, NetworkData, Networks};

use crate::frb_generated::StreamSink;
use crate::shim::state::SharedState;

/// Network snapshot DTO returned to Dart via FRB.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct NetworkInfoDto {
    pub interfaces: Vec<NetworkInterfaceDto>,
}

/// Static network interface metadata in a snapshot.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct NetworkInterfaceDto {
    pub name: String,
    pub mac_address: String,
    pub ip_networks: Vec<IpNetworkEntryDto>,
    pub mtu: u64,
    pub operational_state: NetworkOperationalStateDto,
    pub cumulative: NetworkCumulativeStatsDto,
}

/// IP network assigned to an interface.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct IpNetworkEntryDto {
    pub address: String,
    pub prefix_length: u8,
}

/// Operational state of a network interface.
#[flutter_rust_bridge::frb]
pub enum NetworkOperationalStateDto {
    Up,
    Down,
    Testing,
    Unknown,
    Dormant,
    NotPresent,
    LowerLayerDown,
}

/// Lifetime cumulative counters for a network interface.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct NetworkCumulativeStatsDto {
    pub total_received_bytes: u64,
    pub total_transmitted_bytes: u64,
    pub total_packets_received: u64,
    pub total_packets_transmitted: u64,
    pub total_errors_on_received: u64,
    pub total_errors_on_transmitted: u64,
}

/// One network throughput stream tick (plain fields — TDD §4.5).
#[flutter_rust_bridge::frb(non_opaque)]
pub struct NetworkThroughputSampleDto {
    pub interfaces: Vec<NetworkThroughputInterfaceDto>,
}

/// Per-interface throughput deltas since the last native refresh.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct NetworkThroughputInterfaceDto {
    pub name: String,
    pub received_bytes: u64,
    pub transmitted_bytes: u64,
    pub packets_received: u64,
    pub packets_transmitted: u64,
    pub errors_on_received: u64,
    pub errors_on_transmitted: u64,
}

/// Returns a TTL-backed network snapshot (refresh under write lock, TDD §4.5).
#[flutter_rust_bridge::frb(sync)]
pub fn network_snapshot() -> NetworkInfoDto {
    let state = crate::shim::state::state();
    let mut networks = state.networks.write().expect("networks lock poisoned");
    networks.refresh(true);

    NetworkInfoDto {
        interfaces: networks
            .list()
            .iter()
            .map(|(name, data)| map_network_interface(name, data))
            .collect(),
    }
}

/// Spawns a worker that pushes network throughput samples until cancelled.
#[flutter_rust_bridge::frb(sync)]
pub fn network_throughput_stream(
    sink: StreamSink<NetworkThroughputSampleDto>,
    interval_ms: u64,
) {
    let state = crate::shim::state::state();
    thread::spawn(move || network_throughput_worker(state, sink, interval_ms));
}

fn network_throughput_worker(
    state: Arc<SharedState>,
    sink: StreamSink<NetworkThroughputSampleDto>,
    interval_ms: u64,
) {
    loop {
        let sample = {
            let mut networks = match state.networks.write() {
                Ok(guard) => guard,
                Err(_) => return,
            };
            next_network_throughput_sample(&state, &mut networks)
        };

        if let Some(sample) = sample {
            if sink.add(sample).is_err() {
                return;
            }
        }

        thread::sleep(Duration::from_millis(interval_ms));
    }
}

fn next_network_throughput_sample(
    state: &SharedState,
    networks: &mut Networks,
) -> Option<NetworkThroughputSampleDto> {
    networks.refresh(true);

    if state.is_network_throughput_ready() {
        Some(build_network_throughput_sample(networks))
    } else {
        state.mark_network_throughput_ready();
        None
    }
}

fn build_network_throughput_sample(networks: &Networks) -> NetworkThroughputSampleDto {
    NetworkThroughputSampleDto {
        interfaces: networks
            .list()
            .iter()
            .map(|(name, data)| NetworkThroughputInterfaceDto {
                name: name.clone(),
                received_bytes: data.received(),
                transmitted_bytes: data.transmitted(),
                packets_received: data.packets_received(),
                packets_transmitted: data.packets_transmitted(),
                errors_on_received: data.errors_on_received(),
                errors_on_transmitted: data.errors_on_transmitted(),
            })
            .collect(),
    }
}

fn map_network_interface(name: &str, data: &NetworkData) -> NetworkInterfaceDto {
    NetworkInterfaceDto {
        name: name.to_string(),
        mac_address: data.mac_address().to_string(),
        ip_networks: data
            .ip_networks()
            .iter()
            .map(|network| IpNetworkEntryDto {
                address: network.addr.to_string(),
                prefix_length: network.prefix,
            })
            .collect(),
        mtu: data.mtu(),
        operational_state: map_operational_state(data.operational_state()),
        cumulative: NetworkCumulativeStatsDto {
            total_received_bytes: data.total_received(),
            total_transmitted_bytes: data.total_transmitted(),
            total_packets_received: data.total_packets_received(),
            total_packets_transmitted: data.total_packets_transmitted(),
            total_errors_on_received: data.total_errors_on_received(),
            total_errors_on_transmitted: data.total_errors_on_transmitted(),
        },
    }
}

fn map_operational_state(state: InterfaceOperationalState) -> NetworkOperationalStateDto {
    match state {
        InterfaceOperationalState::Up => NetworkOperationalStateDto::Up,
        InterfaceOperationalState::Down => NetworkOperationalStateDto::Down,
        InterfaceOperationalState::Testing => NetworkOperationalStateDto::Testing,
        InterfaceOperationalState::Unknown => NetworkOperationalStateDto::Unknown,
        InterfaceOperationalState::Dormant => NetworkOperationalStateDto::Dormant,
        InterfaceOperationalState::NotPresent => NetworkOperationalStateDto::NotPresent,
        InterfaceOperationalState::LowerLayerDown => NetworkOperationalStateDto::LowerLayerDown,
        _ => NetworkOperationalStateDto::Unknown,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::shim::state;

    fn reset_state() {
        state::dispose();
        state::init();
    }

    #[test]
    fn network_snapshot_does_not_panic_after_init() {
        reset_state();

        let snapshot = network_snapshot();
        let _ = snapshot.interfaces.len();

        state::dispose();
    }
}
