//! OS domain API (TDD §2.2, §4.3).

use sysinfo::System;

/// One-minute, five-minute, and fifteen-minute load averages.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct LoadAverageDto {
    pub one: f64,
    pub five: f64,
    pub fifteen: f64,
}

/// Carries §4.3 tri-state load-average semantics for Dart Reading mapping.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct LoadAverageReadingDto {
    /// False on Windows → Dart `ReadingUnsupported`.
    pub supported: bool,
    /// None on non-Windows when load average is unavailable → Dart `ReadingUnavailable`.
    pub value: Option<LoadAverageDto>,
}

/// OS snapshot DTO returned to Dart via FRB.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct OsInfoDto {
    pub name: Option<String>,
    pub kernel_version: Option<String>,
    pub os_version: Option<String>,
    pub long_os_version: Option<String>,
    pub host_name: Option<String>,
    pub distribution_id: String,
    pub distribution_id_like: Vec<String>,
    pub kernel_long_version: String,
    pub uptime_seconds: u64,
    pub boot_time_seconds: u64,
    pub load_average: LoadAverageReadingDto,
}

/// Returns a TTL-backed OS snapshot (refresh under write lock, TDD §2.2).
#[flutter_rust_bridge::frb(sync)]
pub fn os_snapshot() -> OsInfoDto {
    let state = crate::shim::state::state();
    let _sys = state.system.write().expect("system lock poisoned");

    OsInfoDto {
        name: System::name(),
        kernel_version: System::kernel_version(),
        os_version: System::os_version(),
        long_os_version: System::long_os_version(),
        host_name: System::host_name(),
        distribution_id: System::distribution_id(),
        distribution_id_like: System::distribution_id_like(),
        kernel_long_version: System::kernel_long_version(),
        uptime_seconds: System::uptime(),
        boot_time_seconds: System::boot_time(),
        load_average: map_load_average(),
    }
}

#[cfg(target_os = "windows")]
fn map_load_average() -> LoadAverageReadingDto {
    LoadAverageReadingDto {
        supported: false,
        value: None,
    }
}

#[cfg(not(target_os = "windows"))]
fn map_load_average() -> LoadAverageReadingDto {
    let load = System::load_average();
    LoadAverageReadingDto {
        supported: true,
        value: Some(LoadAverageDto {
            one: load.one,
            five: load.five,
            fifteen: load.fifteen,
        }),
    }
}
