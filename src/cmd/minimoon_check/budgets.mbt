///|
// vp migration review, 2026-09-21: initial core archive 323,623 B.
// The managed-process launcher and setup docs need one additional 8 KiB step.
// Retain the 8 KiB reserve; runtime, Starter and UI byte budgets are unchanged.
let registry_archive_hard_limit : Int32 = 328 * 1024

///|
let registry_archive_reserve : Int32 = 8 * 1024

///|
let registry_archive_operating_limit : Int32 = registry_archive_hard_limit -
  registry_archive_reserve

///|
let ui_registry_archive_hard_limit : Int32 = 250 * 1024

///|
let ui_registry_archive_reserve : Int32 = 16 * 1024

///|
// Approved query follow-up, 2026-10-19: runtime/aggregate 453,892/488,620 B.
// The +17,220 B feature/demo delta changes only these two example ceilings.
let conformance_runtime_limit : Int32 = 464000

///|
let conformance_javascript_limit : Int32 = 500000

///|
// Independent starter follow-up: optimized runtime/aggregate 226,205/253,966 B.
let starter_runtime_limit : Int32 = 230000

///|
let starter_javascript_limit : Int32 = 258000

///|
// Native navigation/layout calibration: no-App 17,501 B; App 18,276 B.
let page_host_limit : Int32 = 18000

///|
let application_host_limit : Int32 = 19000

///|
fn shared_host_limit(application : Bool) -> Int32 {
  if application {
    application_host_limit
  } else {
    page_host_limit
  }
}

///|
fn byte_budget_allows(size : Int32, limit : Int32) -> Bool {
  size >= 0 && size <= limit
}
