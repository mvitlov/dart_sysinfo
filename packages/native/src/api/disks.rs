//! Disks domain API (TDD §2.1, §4.4).

use sysinfo::{Disk, DiskKind};

/// Disks snapshot DTO returned to Dart via FRB.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct DisksInfoDto {
    pub volumes: Vec<DiskVolumeDto>,
}

/// Single mounted volume in a disks snapshot.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct DiskVolumeDto {
    pub name: String,
    pub kind: DiskKindDto,
    pub file_system: String,
    pub mount_point: String,
    pub total_space_bytes: u64,
    pub available_space_bytes: u64,
    pub is_removable: bool,
    pub is_read_only: bool,
    pub io_usage: DiskIoUsageDto,
}

/// Physical disk kind exposed to Dart.
#[flutter_rust_bridge::frb]
pub enum DiskKindDto {
    Hdd,
    Ssd,
    Unknown,
}

/// Cumulative disk I/O counters from the last native refresh.
#[flutter_rust_bridge::frb(non_opaque)]
pub struct DiskIoUsageDto {
    pub read_bytes: u64,
    pub written_bytes: u64,
    pub total_read_bytes: u64,
    pub total_written_bytes: u64,
}

/// Returns a TTL-backed disks snapshot (refresh under write lock, TDD §4.4).
#[flutter_rust_bridge::frb(sync)]
pub fn disks_snapshot() -> DisksInfoDto {
    let state = crate::shim::state::state();
    let mut disks = state.disks.write().expect("disks lock poisoned");
    disks.refresh(true);

    DisksInfoDto {
        volumes: disks.list().iter().map(map_disk_volume).collect(),
    }
}

fn map_disk_volume(disk: &Disk) -> DiskVolumeDto {
    let usage = disk.usage();
    DiskVolumeDto {
        name: disk.name().to_string_lossy().into_owned(),
        kind: map_disk_kind(disk.kind()),
        file_system: disk.file_system().to_string_lossy().into_owned(),
        mount_point: disk.mount_point().display().to_string(),
        total_space_bytes: disk.total_space(),
        available_space_bytes: disk.available_space(),
        is_removable: disk.is_removable(),
        is_read_only: disk.is_read_only(),
        io_usage: DiskIoUsageDto {
            read_bytes: usage.read_bytes,
            written_bytes: usage.written_bytes,
            total_read_bytes: usage.total_read_bytes,
            total_written_bytes: usage.total_written_bytes,
        },
    }
}

fn map_disk_kind(kind: DiskKind) -> DiskKindDto {
    match kind {
        DiskKind::HDD => DiskKindDto::Hdd,
        DiskKind::SSD => DiskKindDto::Ssd,
        DiskKind::Unknown(_) => DiskKindDto::Unknown,
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
    fn disks_snapshot_does_not_panic_after_init() {
        reset_state();

        let snapshot = disks_snapshot();
        let _ = snapshot.volumes.len();

        state::dispose();
    }
}
