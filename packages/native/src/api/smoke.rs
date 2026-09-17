/// Compile-only FRB surface for M0-03; called from Dart in M0-04.
#[flutter_rust_bridge::frb(sync)]
pub fn frb_platform_smoke_ping() -> i32 {
    42
}
