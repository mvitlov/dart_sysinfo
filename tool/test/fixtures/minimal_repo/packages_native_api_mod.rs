//! FRB-facing public API (one module per domain).

pub mod abi;
// GENERATOR:BEGIN api-mod
pub mod cpu;
pub mod lifecycle;
pub mod memory;
pub mod os;
// GENERATOR:END api-mod
pub mod smoke;
