//! CPU domain API (TDD §2.2, §2.3, §4.1).

use std::sync::Arc;
use std::thread;
use std::time::Duration;

use sysinfo::{CpuRefreshKind, System};

use crate::frb_generated::StreamSink;

use crate::shim::state::SharedState;

/// Per-core CPU fields exposed to Dart via FRB.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct CpuCoreDto {
    pub name: String,
    pub vendor_id: String,
    pub brand: String,
    pub frequency_mhz: u64,
    pub usage_percent: f32,
}

/// CPU snapshot DTO. `Option` fields carry §4.1 semantics for M1-07 `Reading<T>`.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct CpuInfoDto {
    pub architecture: String,
    pub physical_core_count: Option<u32>,
    pub global_usage_percent: Option<f32>,
    pub cores: Option<Vec<CpuCoreDto>>,
}

/// One CPU load stream tick (plain fields — no `Reading<T>` on streams, TDD §4.1).
#[flutter_rust_bridge::frb(non_opaque)]
pub struct CpuLoadSampleDto {
    pub global_usage_percent: f32,
    pub per_core_usage_percent: Vec<f32>,
}

/// Returns a TTL-backed CPU snapshot (refresh under write lock, TDD §2.2).
#[flutter_rust_bridge::frb(sync)]
pub fn cpu_snapshot() -> CpuInfoDto {
    let state = crate::shim::state::state();
    let mut sys = state.system.write().expect("system lock poisoned");
    sys.refresh_cpu_specifics(CpuRefreshKind::everything());

    let global_usage_percent = if state.is_cpu_usage_ready() {
        Some(sys.global_cpu_usage())
    } else {
        state.mark_cpu_usage_ready();
        None
    };

    CpuInfoDto {
        architecture: System::cpu_arch(),
        physical_core_count: System::physical_core_count().map(|count| count as u32),
        global_usage_percent,
        cores: map_cores(&sys),
    }
}

/// Spawns a worker that pushes CPU load samples until the Dart listener cancels.
#[flutter_rust_bridge::frb(sync)]
pub fn cpu_load_stream(sink: StreamSink<CpuLoadSampleDto>, interval_ms: u64) {
    let state = crate::shim::state::state();
    thread::spawn(move || cpu_load_worker(state, sink, interval_ms));
}

fn cpu_load_worker(
    state: Arc<SharedState>,
    sink: StreamSink<CpuLoadSampleDto>,
    interval_ms: u64,
) {
    loop {
        let sample = {
            let mut sys = match state.system.write() {
                Ok(guard) => guard,
                Err(_) => return,
            };
            next_cpu_load_sample(&state, &mut sys)
        };

        if let Some(sample) = sample {
            if sink.add(sample).is_err() {
                return;
            }
        }

        thread::sleep(Duration::from_millis(interval_ms));
    }
}

fn next_cpu_load_sample(state: &SharedState, sys: &mut System) -> Option<CpuLoadSampleDto> {
    sys.refresh_cpu_usage();

    if state.is_cpu_usage_ready() {
        Some(build_cpu_load_sample(sys))
    } else {
        state.mark_cpu_usage_ready();
        None
    }
}

fn build_cpu_load_sample(sys: &System) -> CpuLoadSampleDto {
    CpuLoadSampleDto {
        global_usage_percent: sys.global_cpu_usage(),
        per_core_usage_percent: sys.cpus().iter().map(|cpu| cpu.cpu_usage()).collect(),
    }
}

fn map_cores(sys: &System) -> Option<Vec<CpuCoreDto>> {
    if !cpu_enumeration_supported() {
        return None;
    }

    let cores = sys
        .cpus()
        .iter()
        .map(|cpu| CpuCoreDto {
            name: cpu.name().to_string(),
            vendor_id: cpu.vendor_id().to_string(),
            brand: cpu.brand().to_string(),
            frequency_mhz: cpu.frequency(),
            usage_percent: cpu.cpu_usage(),
        })
        .collect();

    #[cfg(target_os = "android")]
    if cores.is_empty() {
        return None;
    }

    Some(cores)
}

#[cfg(not(target_os = "android"))]
fn cpu_enumeration_supported() -> bool {
    true
}

/// sysinfo documents restricted CPU enumeration on Android below API 26.
#[cfg(target_os = "android")]
fn cpu_enumeration_supported() -> bool {
    std::process::Command::new("getprop")
        .arg("ro.build.version.sdk")
        .output()
        .ok()
        .and_then(|output| String::from_utf8(output.stdout).ok())
        .and_then(|value| value.trim().parse::<u32>().ok())
        .is_some_and(|sdk| sdk >= 26)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn build_cpu_load_sample_reads_global_and_per_core_usage() {
        let mut sys = System::new();
        sys.refresh_cpu_specifics(CpuRefreshKind::everything());
        sys.refresh_cpu_usage();

        let sample = build_cpu_load_sample(&sys);
        assert!(sample.global_usage_percent >= 0.0);
        assert_eq!(
            sample.per_core_usage_percent.len(),
            sys.cpus().len()
        );
    }

    #[test]
    fn next_cpu_load_sample_warmup_skips_first_emit() {
        let state = SharedState {
            system: std::sync::RwLock::new(System::new()),
            cpu_usage_ready: std::sync::atomic::AtomicBool::new(false),
        };
        let mut sys = state.system.write().unwrap();
        sys.refresh_cpu_specifics(CpuRefreshKind::everything());

        assert!(next_cpu_load_sample(&state, &mut sys).is_none());
        assert!(state.is_cpu_usage_ready());
        assert!(next_cpu_load_sample(&state, &mut sys).is_some());
    }
}
