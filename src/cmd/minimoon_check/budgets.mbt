///|
// HTTP budget review, 2026-09-07: retain the core archive hard cap while
// allocating 8 KiB of its former 16 KiB reserve to the typed request surface.
let registry_archive_hard_limit : Int = 250 * 1024

///|
let registry_archive_reserve : Int = 8 * 1024

///|
let registry_archive_operating_limit : Int = registry_archive_hard_limit -
  registry_archive_reserve

///|
// Measured HTTP deltas: runtime +16,051 B; aggregate +17,083 B. Rounded
// increases preserve roughly the previous absolute headroom, not a multiplier.
let conformance_runtime_limit : Int = 360000

///|
let conformance_javascript_limit : Int = 424000

///|
fn byte_budget_allows(size : Int, limit : Int) -> Bool {
  size >= 0 && size <= limit
}
