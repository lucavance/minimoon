///|
/// Install the first accepted candidate before a PageProgram has active refs.
/// The initial candidate follows the same commit order as later projections.
fn[Msg] commit_initial_candidate(
  candidate : RenderCandidate[Msg],
  normalization_cache : Ref[Map[String, NormalizedCacheEntry]],
  normalization_roots : Ref[Array[String]],
) -> Unit {
  candidate.commit()
  commit_normalized_candidate(
    candidate.normalization,
    normalization_cache,
    normalization_roots,
  )
}

///|
/// Run cleanup for scopes that disappeared from an accepted candidate.
fn cleanup_removed_scopes(
  previous : Map[String, () -> Unit],
  next : Map[String, () -> Unit],
) -> Unit {
  for scope, cleanup in previous {
    if !next.contains(scope) {
      cleanup()
    }
  }
}

///|
/// Install a validated candidate and publish its active renderer metadata.
/// Candidate construction and validation happen before this function runs.
fn[Msg] accept_candidate(
  candidate : RenderCandidate[Msg],
  active_tree : Ref[Json],
  active_events : Ref[Array[PageEvent[Msg]]],
  active_event_index : Ref[Map[String, PageEvent[Msg]]],
  active_subscriptions : Ref[Array[HostSubscription[Msg]]],
  active_scope_cleanups : Ref[Map[String, () -> Unit]],
  normalization_cache : Ref[Map[String, NormalizedCacheEntry]],
  normalization_roots : Ref[Array[String]],
) -> Unit {
  cleanup_removed_scopes(active_scope_cleanups.val, candidate.scope_cleanups)
  candidate.commit()
  commit_normalized_candidate(
    candidate.normalization,
    normalization_cache,
    normalization_roots,
  )
  active_tree.val = candidate.tree
  active_events.val = candidate.events
  active_event_index.val = candidate.event_index
  active_subscriptions.val = candidate.subscriptions
  active_scope_cleanups.val = candidate.scope_cleanups
}
