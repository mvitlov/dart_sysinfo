//! Memory domain API (TDD §2.2, §4.2).

use sysinfo::{MemoryRefreshKind, System};

/// Root cgroup memory limits exposed to Dart via FRB.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct CGroupLimitsDto {
    pub total_memory_bytes: u64,
    pub free_memory_bytes: u64,
    pub free_swap_bytes: u64,
    pub rss_bytes: u64,
}

/// Carries §4.2 tri-state cgroup semantics for M1-08 Dart Reading mapping.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct CGroupLimitsReadingDto {
    /// False on non-Linux → Dart `ReadingUnsupported`.
    pub supported: bool,
    /// None on Linux when sysinfo returns no cgroup → Dart `ReadingUnavailable`.
    pub value: Option<CGroupLimitsDto>,
}

/// Memory snapshot DTO returned to Dart via FRB.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct MemoryInfoDto {
    pub total_memory_bytes: u64,
    pub free_memory_bytes: u64,
    pub available_memory_bytes: u64,
    pub used_memory_bytes: u64,
    pub total_swap_bytes: u64,
    pub free_swap_bytes: u64,
    pub used_swap_bytes: u64,
    pub cgroup_limits: CGroupLimitsReadingDto,
}

/// Returns a TTL-backed memory snapshot (refresh under write lock, TDD §2.2).
#[flutter_rust_bridge::frb(sync)]
pub fn memory_snapshot() -> MemoryInfoDto {
    let state = crate::shim::state::state();
    let mut sys = state.system.write().expect("system lock poisoned");
    sys.refresh_memory_specifics(MemoryRefreshKind::everything());

    MemoryInfoDto {
        total_memory_bytes: sys.total_memory(),
        free_memory_bytes: sys.free_memory(),
        available_memory_bytes: sys.available_memory(),
        used_memory_bytes: sys.used_memory(),
        total_swap_bytes: sys.total_swap(),
        free_swap_bytes: sys.free_swap(),
        used_swap_bytes: sys.used_swap(),
        cgroup_limits: map_cgroup_limits(&sys),
    }
}

#[cfg(not(target_os = "linux"))]
fn map_cgroup_limits(_sys: &System) -> CGroupLimitsReadingDto {
    CGroupLimitsReadingDto {
        supported: false,
        value: None,
    }
}

#[cfg(target_os = "linux")]
fn map_cgroup_limits(sys: &System) -> CGroupLimitsReadingDto {
    CGroupLimitsReadingDto {
        supported: true,
        value: sys.cgroup_limits().map(|limits| CGroupLimitsDto {
            total_memory_bytes: limits.total_memory,
            free_memory_bytes: limits.free_memory,
            free_swap_bytes: limits.free_swap,
            rss_bytes: limits.rss,
        }),
    }
}
