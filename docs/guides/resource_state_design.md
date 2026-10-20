# Resource state

Minimoon provides one deliberately small, graph-owned, one-shot
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
not a request cache or a retry controller. For cursor lists, the optional query
package below supplies refresh/retry state. Other policies remain ordinary
application messages and state.

`Status[T]` implements `Enumerate`, so a dynamic status view can retain a scope
per `pending`, `loaded`, or `failed` tag. Remember that the builder's initial
tagged value is a snapshot while its same-tag `Val` continues to update.

Creating a resource inside a candidate dynamic branch is transactional. A
rejected projection discards its initial command; an accepted projection starts
it only after commit. Reading the returned `Val` never starts additional work,
and racing callbacks cannot overwrite its first committed terminal result.

## Paginated queries (since 0.3.1)

Core `0.3.1` adds optional `lampclaw/minimoon/query`; see
[availability](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).
Create it once in a page or local component builder:

```moonbit
let (state, emit) = @query.create_infinite_query("", (text, _cursor : Int?, done) => {
  // Replace this local result with an HTTP or other command.
  done(Ok({ items: [text], next_cursor: None }))
})
state.view(state => @minimoon.div([
  @minimoon.p(state.items.to_array().join(",")),
  @minimoon.button(on_tap=emit(@query.Refresh), "Refresh"),
  @minimoon.button(
    disabled=!state.can_load_more,
    on_tap=emit(@query.LoadMore),
    "Load more",
  ),
]))
```

The loader returns a `Cmd`; side effects belong inside that command. Adapt HTTP
`expect_json` with `done.map(...)` to produce `QueryPage { items, next_cursor }`.
Initial cursor `None` requests the first page; response cursor `None` ends the
list. Empty pages may still have a cursor. Items retain server order and duplicates.
Calling `done` copies the array into an immutable vector. Treat queries, cursors
and individual items as immutable too.

`SetQuery(new_query)` clears data and starts the first page; equal queries are
ignored. Keep draft input in ordinary local state and send SetQuery on button
or keyboard confirmation. `Refresh` retains existing rows, replacing all pages
on success. Repeated refresh/load-more commands while busy are ignored; a refresh
can supersede an append, and a changed query can supersede any request.

`QueryState` exposes query, items, phase, has_loaded, has_more, can_load_more and
the original Error. Idle can contain an error. has_loaded distinguishes an empty
success from an initial failure. A failed append retains its cursor and rows;
`Retry` repeats that append. A failed refresh retains rows but blocks appending
until a refresh succeeds. Retry without a failure is a no-op. Error equality
uses identity and retains the original typed error.

Only the current request's first committed completion wins. Stale/duplicate
responses and disposed-scope callbacks are ignored. Rollback does not consume a
completion. Supersession invalidates results; transport cancellation remains
page-owned. No cache, automatic retry, debounce or cross-page ownership is added.
