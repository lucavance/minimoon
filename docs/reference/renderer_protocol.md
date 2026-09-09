# Renderer protocol

## Versions

- App Contract schema: 11
- runtime API/state ABI: 13
- renderer protocol: 8
- generated runtime module format: CommonJS

The application runtime exports version/state-ABI queries, page-aware create,
mount, single dispatch, batch dispatch, lifecycle, resolve-effect,
subscription, snapshot, and dispose. Every mounted page receives an independent
instance. When `application` is configured, the runtime also exports App start,
lifecycle, effect resolution, subscription, flush, and disposal entries. Its
independent scheduler does not render a page tree; pages bind shared state into
their own transactional projections.

The ABI v13 host/runtime convention additionally installs a temporary
generation-bound wake callback around synchronous runtime creation. The new
page runtime captures it for later async local effects, which request a
sequence-bounded internal command drain. It is not a CommonJS export or an
application lifecycle hook.

## Normalized tree

```text
Node = {
  kind: finite string,
  identity: "root" | "i:<index>" | "k:<key>",
  text: string,
  props: sparse typed object,
  events: sparse string-key object,
  children: Node[]
}
```

Props and events have finite allowlists. Authoring-retention identity never
appears in this protocol. Cache, routes, subscriptions, and the active tree
change atomically; rejected candidates cannot poison the accepted cache.

Protocol v8 carries finite semantic props: `role`, `ariaLabel`, `ariaExpanded`,
`ariaSelected`, `ariaDisabled`, `ariaHidden`, `ariaChecked`, `ariaModal`,
`ariaControls`, `ariaLabelledBy`, `ariaDescribedBy`, `ariaOrientation`, and
`ariaHasPopup`. Boolean semantic states stay booleans through normalization and
host validation. Focus, blur, and confirm remain finite event keys.

## Renderer commands

`ReplaceViewTree(component_id, base_revision, revision, tree)` carries the
complete tree. `PatchViewTree(..., ops)` carries protocol-v8 operations:

- `set`: replace `text`, `props`, or `events`;
- `splice`: change a children range;
- `move`: relocate one keyed child with expected identity/item validation.

Each command advances exactly one revision. Paths contain only allowlisted
fields and non-negative indices. Patch bytes must be at most 75% of replacement
bytes and weighted host cost at most 32; set/splice cost one and move costs two.

## Batch and scheduler protocol

`dispatch_batch` accepts at most 2048 JSON objects containing `key` and
`payload`. Parsing, object shape validation, and every event decoder complete
before applying the first message. Each message retains its candidate
transaction; the batch returns at most one collected render command.

The host starts an idle entry immediately, preserves queue order, runs one
render at a time, and combines adjacent waiting UI events. Async wakes from the
same turn, or an adjacent tail drain, may coalesce to the greatest message
watermark. An intervening UI, lifecycle, subscription, effect, or render entry
is a barrier, so a later completion cannot move ahead of it. The host warns at
256 entries and fails closed rather than exceeding 2048.

## Render acknowledgement

The host data envelope is `{ tree, commit }`. Every renderer write carries a
new commit sentinel; the `setData` callback acknowledges it. Structural glass-
easel updates finish with a sentinel-only `setData`. The shadow revision changes
only after acknowledgement.

A three-second timeout triggers one full authoritative snapshot write. A second
timeout, invalid snapshot, or retry write failure closes the scheduler. Stale
callbacks cannot acknowledge a new attempt or a new page generation.

## Lifecycle

```text
onLoad: decode actual input -> create graph -> Load -> full Replace revision 0 to 1
onShow: refresh shared projections -> optional lifecycle message
onReady: first mount -> initial commands -> start subscriptions
event/tick/effect: ordered entry -> candidate transaction -> acknowledged render
onUnload: invalidate generation -> lifecycle/dispose -> clear owned resources
```

Verification requires generated App Contract v11, runtime ABI v13, and renderer
protocol v8 artifacts. Both App and no-App configurations require schema `11`;
schema `8` and `9` are migration errors. Unsafe routes, missing packages/programs, forbidden JavaScript,
invalid shared artifacts, or host simulation failures are rejected.

Runtime creation returns a JSON success-ID or input-error envelope. Failed
decoding creates no page graph and runs no initialization. A created page
retains a copy of its normalized input; Load must match that copy. Repeated
Load yields `duplicate_page_load`, mismatched input yields
`page_input_mismatch`, and pre-Load interactions yield `page_not_loaded`.
Mount is idempotent; disposed entries are harmless no-ops. Preview trees never
hydrate the host. Its empty boot tree stays at revision 0 until the mandatory
first full replacement is acknowledged.
