///|
// Shared-state budget review, 2026-09-07: expand the repository-owned core
// archive ceiling while retaining its 8 KiB reserve. UI budgets are unchanged.
let registry_archive_hard_limit : Int = 280 * 1024

///|
let registry_archive_reserve : Int = 8 * 1024

///|
let registry_archive_operating_limit : Int = registry_archive_hard_limit -
  registry_archive_reserve

///|
// Measured shared-state deltas: runtime +22,881 B; aggregate +28,324 B. Rounded
// increases preserve roughly the previous absolute headroom, not a multiplier.
let conformance_runtime_limit : Int = 383000

///|
let conformance_javascript_limit : Int = 453000

///|
let page_host_limit : Int = 15000

///|
let application_host_limit : Int = 16000

///|
fn shared_host_limit(application : Bool) -> Int {
  if application {
    application_host_limit
  } else {
    page_host_limit
  }
}

///|
fn byte_budget_allows(size : Int, limit : Int) -> Bool {
  size >= 0 && size <= limit
}
