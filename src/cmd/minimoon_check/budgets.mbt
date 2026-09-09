///|
// Approved native navigation/layout review, 2026-09-08: core archive 304,861 B.
// Retain the 8 KiB reserve; UI archive and package allowlists are unchanged.
let registry_archive_hard_limit : Int = 320 * 1024

///|
let registry_archive_reserve : Int = 8 * 1024

///|
let registry_archive_operating_limit : Int = registry_archive_hard_limit -
  registry_archive_reserve

///|
// Retain the prior authoring review's fixed runtime and aggregate ceilings.
let conformance_runtime_limit : Int = 400000

///|
let conformance_javascript_limit : Int = 453000

///|
// Independent starter follow-up: optimized runtime/aggregate 226,205/253,966 B.
let starter_runtime_limit : Int = 230000

///|
let starter_javascript_limit : Int = 258000

///|
// Native navigation/layout calibration: no-App 17,501 B; App 18,276 B.
let page_host_limit : Int = 18000

///|
let application_host_limit : Int = 19000

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
