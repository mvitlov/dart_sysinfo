use std::sync::mpsc;
use std::thread::{self, JoinHandle};
use std::time::Duration;

use dart_sysinfo_native::api::{cpu, memory, os};
use dart_sysinfo_native::shim::state;

fn join_with_timeout(handle: JoinHandle<()>, timeout: Duration) -> Result<(), ()> {
    let (tx, rx) = mpsc::sync_channel(0);
    thread::spawn(move || {
        let _ = handle.join();
        let _ = tx.send(());
    });
    rx.recv_timeout(timeout).map(|_| ()).map_err(|_| ())
}

#[test]
fn snapshot_and_stream_refresh_do_not_deadlock() {
    state::dispose();
    state::init();

    let handles: Vec<_> = (0..8)
        .map(|_| {
            thread::spawn(|| {
                for _ in 0..200 {
                    let _ = cpu::cpu_snapshot();
                    let _ = memory::memory_snapshot();
                    let _ = os::os_snapshot();
                }
            })
        })
        .collect();

    for handle in handles {
        assert!(
            join_with_timeout(handle, Duration::from_secs(10)).is_ok(),
            "worker thread did not finish within 10s — possible deadlock on RwLock<System>"
        );
    }

    state::dispose();
}
