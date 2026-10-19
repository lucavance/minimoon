///|
/// Commands for a page- or component-owned query. Equal queries are a no-op;
/// use Refresh to reload the current query.
pub(all) enum QueryAction[Q] {
  SetQuery(Q)
  Refresh
  LoadMore
  Retry
}

///|
pub(all) enum QueryPhase {
  Idle
  Loading
  Refreshing
  LoadingMore
} derive(Eq)

///|
/// None ends pagination. Items retain server order, including duplicates.
pub(all) struct QueryPage[T, Cursor] {
  items : Array[T]
  next_cursor : Cursor?
}

///|
/// Immutable list snapshot. Idle may carry an error. has_loaded distinguishes
/// empty success from initial failure; can_load_more accounts for busy requests
/// and failed refreshes. Queries and individual items must also be immutable.
pub struct QueryState[Q, T] {
  query : Q
  items : @vector.Vector[T]
  phase : QueryPhase
  has_loaded : Bool
  has_more : Bool
  can_load_more : Bool
  error : Error?
}

///|
pub impl[Q : Eq, T : Eq] Eq for QueryState[Q, T] with fn equal(a, b) {
  a.query == b.query &&
  a.items == b.items &&
  a.phase == b.phase &&
  a.has_loaded == b.has_loaded &&
  a.has_more == b.has_more &&
  a.can_load_more == b.can_load_more &&
  (match (a.error, b.error) {
    (None, None) => true
    (Some(a), Some(b)) => physical_equal(a, b)
    _ => false
  })
}

///|
pub extend QueryPhase with Eq::{equal, not_equal}

///|
pub extend QueryState with Eq::{equal, not_equal}
