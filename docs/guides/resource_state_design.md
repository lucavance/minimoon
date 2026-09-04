# Resource state

Minimoon `0.1.0` provides one deliberately small, graph-owned, one-shot
resource helper:

```moonbit
pub enum Status[T] {
  Pending
  Loaded(T)
  Failed(Error)
}

pub fn[T : Eq] create_resource(
  (Emit[Result[T, Error]]) -> Cmd,
) -> Val[Status[T]]
```

`create_resource(load)` starts exactly one commit-gated initial command. The
loader receives a callable `Emit[Result[T, Error]]`; success becomes `Loaded`,
failure becomes `Failed`, and a completion after the owning scope is disposed
becomes a no-op.

The first terminal completion that successfully commits while the resource is
`Pending` wins. Duplicate success, duplicate failure, and success/failure
crossovers after `Loaded` or `Failed` are no-ops and do not dirty the graph. A
candidate completion that rolls back does not claim the resource, so a later
completion may still commit.

```moonbit
let profile = @minimoon.create_resource(done => {
  @minimoon.perform(done, async fn() noraise { load_local_profile() })
})

profile.view(status => render_profile(status))
```

There is no `Resource` handle or hidden `reload` method. Consequently the
helper has no overlapping generations: it represents construction-time work,
not a request cache or a retry controller. Model retry, refresh, stale data,
permission, unavailable, and cache policy as ordinary application messages and
state when the product needs them.

`Status[T]` implements `Enumerate`, so a dynamic status view can retain a scope
per `pending`, `loaded`, or `failed` tag. Remember that the builder's initial
tagged value is a snapshot while its same-tag `Val` continues to update.

Creating a resource inside a candidate dynamic branch is transactional. A
rejected projection discards its initial command; an accepted projection starts
it only after commit. Reading the returned `Val` never starts additional work,
and racing callbacks cannot overwrite its first committed terminal result.
