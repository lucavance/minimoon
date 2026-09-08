///|
// Approved authoring budget review, 2026-09-08: measured core archive 288,166 B.
// Retain the 8 KiB reserve; UI archive and package allowlists are unchanged.
let registry_archive_hard_limit : Int = 300 * 1024

///|
let registry_archive_reserve : Int = 8 * 1024

///|
let registry_archive_operating_limit : Int = registry_archive_hard_limit -
  registry_archive_reserve

///|
// Measured authoring runtime 387,977 B; fixed ceiling leaves 12,023 B headroom.
// Aggregate JS fell to 418,121 B, so its existing ceiling is not increased.
let conformance_runtime_limit : Int = 400000

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
