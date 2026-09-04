# Keyed children and diff

Keyed local ownership is created before rendering:

```moonbit
let rows = items.assoc_by(
  (id, item) => row(id, item),
  by=item => item.id,
)
```

`assoc_by` preserves the nested `Val` graph for a stable key even when the
source vector changes order. The final view should render the corresponding
nodes through `keyed_fragment` so the renderer can emit a keyed `move` rather
than destroy and recreate native children.

The two identities serve related but distinct layers:

- `assoc_by` key: incremental branch state/subscription ownership
- `keyed_fragment` key: normalized tree and host child identity

Both should come from the same stable domain identifier. Keys must be unique.
Changing a key means removing one branch and creating another.

Branch removal is candidate-transactional. The old branch is temporarily hidden
from subscriptions, disposed only after render validation succeeds, and restored
unchanged if the candidate is rejected.

Renderer protocol v7 indexes prior and next child identities, then computes an
O(n log n) longest-increasing subsequence to minimize moves. Deterministic
coverage includes duplicate rejection, rotations, reverse order, mixed
move/update cases, and 100/500/2000-child stress inputs. It falls back to
full-tree replacement when a patch is unsafe or not cost-effective.
