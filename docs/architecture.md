# Architecture

## Optional application ownership

`App[Deps]` creates a headless application graph and a generation-bound FIFO.
Its builder may create several domain machines with different Model/Msg types;
there is no mandatory global Model. `Shared[T]` has no public mutation/read API.
`PageContext.bind/select` installs a scoped page-local projection; application
commits notify only visible bindings whose selected value differs by `Eq`.

Page transactions stage application messages in a commit outbox. A rejected
page transaction publishes none. Once the application commits, page projection
failures do not roll back application state; the next refresh can recover.
There is deliberately no cross-page rendering transaction.

Launch executes initialization once. Show/Hide control foreground intervals,
not HTTP ownership. Page hide pauses projections; show catches up. Page unload
detaches bindings and page tasks without destroying the application. Explicit
application disposal invalidates addresses before cancelling tasks and releasing
pages. The host has no invented application shutdown lifecycle. Compile previews
create initial state, emit no commands, and dispose their temporary graphs.

See [the shared-state guide](guides/shared_state.md) for factories, capabilities,
business request epochs, and testing. This adapts Rabbita's owned state-machine
composition; it does not import its browser host or require a global mutable store.

## End-to-end path

```text
lampclaw/minimoon public API
  App / Shared / Emit / Cmd / Sub / Val / Page
    -> val_runtime + internal_duplix
       page-owned graph, local state, keyed scopes, transactions
    -> renderer_miniapp
       checked normalization, typed tree, indexed diff, PageRuntime
    -> runtime_core
       resident state, effects, command queue
    -> tooling_miniapp
       App Contract v9 compilation and artifact writing
    -> internal_host_js
       ordered scheduler, render acknowledgement, wx.* facade
    -> generated CommonJS + shared WXML/WXSS + page stubs
    -> Skyline / glass-easel / setData / wx.*
```

Applications import `lampclaw/minimoon` and may opt into public optional
packages or the independent `lampclaw/minimoon_ui` module. Core authoring types
are root-owned; public interfaces expose no implementation package names. The
renderer, runtime, graph, host templates, and tooling remain internal packages.

## Graph and local ownership

Each `Page` is a factory. Every `create_runtime()` call creates a distinct
graph, so two mounted instances of the same route do not share page-local
state, branch caches, subscriptions, or disposal state. They may independently
bind the same application-owned `Shared[T]`.

Each page-local state constructor returns a read-only `Val[Model]` plus a stable
callable `Emit[Msg]`. Calling the emitter builds an opaque command; executing that
command stages an update in the graph-owned state slot. `Emit::map` adapts a
child message into a parent message without exposing the slot. Keyed branches
preserve nested state and subscriptions while their key exists. Removal is
staged, disposed on commit, and restored on rollback.

Every graph owns a generation token, a generational state-dispatch registry,
and a generational subscription registry. A local emitter captures its graph
and state addresses; its command carries that address plus a privately erased
message payload. Execution resolves the address only against the current
ambient graph. A graph mismatch, disposed graph, freed state generation, or
reused slot therefore becomes a deterministic no-op instead of retaining or
calling an old state closure. Scope cleanup frees state entries, and graph
disposal resets both registries before releasing the graph token.
App emitters add an application address and a commit-gated inbox delivery;
they are deliberately usable from pages belonging to that application.

Dynamic branch tags identify structure while branch builders receive a
reactive same-tag input. `switch` retains one scope. `enumerate` retains a
finite tag set and pauses subscriptions in inactive scopes.
`enumerate_bounded_by` transactionally evicts the least-recent inactive scope
when its positive capacity is reached.

Headless components keep the same ownership rule. Their additive
`*_with_input` variants combine parent selection/open state with a separate
`Val[Input]`; slot renderers receive plain input and construct nodes only.
Child state is created once outside the renderer, so hiding a panel stops its
materialization without recreating or leaking its graph scope.

State initialization created by a dynamic branch is staged with that graph
transaction. A rejected projection discards it; a committed projection drains
it afterward in a new transaction. This prevents command execution during a
graph pull while preserving FIFO and cascading branch initialization.

State builders and their init callbacks still run while the graph is being
constructed or pulled. Only the command returned by an init callback is
commit-gated; a rejected candidate discards that command before it can execute.

For page-local subscriptions, the page renderer owns the live host interval
keys, intervals, and latest messages. A retained key/interval pair keeps one host
timer while each accepted render refreshes the typed message it will dispatch. Runtime core does
not maintain a second generic subscription registry. Application subscriptions
have a separate AppDriver-owned table and App host timers; Show/Hide pauses or
resumes those foreground intervals independently of any page render.

The graph-side subscription registry preserves declaration order separately
from generational identity. Visibility toggles the entry in place for retained
hidden scopes. Rollback, committed branch removal, bounded-cache eviction, and
ordinary scope disposal free the entry and remove its order record, so repeated
within-page branch churn does not grow an append-only closure array.

## Candidate transaction

One decoded message follows this sequence:

```text
begin graph transaction
  -> stage state and branch changes
  -> materialize the candidate Node tree
  -> validate event/subscription identity and normalize changed subtrees
  -> derive one revisioned renderer command
  -> commit graph, routes, subscriptions, cache, and tree
     or restore every candidate-owned change
  -> expose accepted commands to the host scheduler
```

Private retained identities plus indexed/keyed materialization paths let the
renderer reuse validated normalized subtrees. They never cross the runtime ABI.
The accepted typed tree flows directly into diffing without a complete-tree
stringify/parse round trip.

## Runtime entry and batching

`PageRuntime` is an opaque root wrapper. A single dispatch decodes one event;
`dispatch_batch` accepts a JSON array of `{ key, payload }` entries. The batch
limit is 2048. Its JSON shape and every event payload are decoded before the
first message is applied, so one malformed entry rejects the whole batch
without a partial state transition. A successful batch commits once and
produces at most one render command.

## Host scheduler and render acknowledgement

Each mounted page owns one scheduler:

1. The first entry starts immediately when idle.
2. Only one runtime entry and one host render may be in flight.
3. Lifecycle, subscription, effect, and UI entries retain queue order.
4. Discrete UI events remain lossless and ordered. Adjacent same-key, same-type
   scroll/changing entries, and same-key touchmove entries with the same touch identity, may
   collapse to the newest payload. Other entries are coalescing barriers.
5. A batch warns once at 256 entries and fails closed before accepting an entry
   beyond 2048.

Runtime ABI v11 installs an internal, generation-bound wake closure during the
synchronous runtime-creation entry. The created page runtime captures that
closure, and a suspended local effect requests a sequence-bounded `drain`
scheduler entry after it emits. Same-turn wakes and adjacent tail drains may
merge their watermarks; every intervening scheduler entry is an ordering
barrier. The reserved drain hook only collects messages through that watermark
and is never exposed to application lifecycle code. Unload and fail-close
invalidate the closure together with the page generation.

The host keeps a validated revisioned shadow. Patch application uses
copy-on-write along the changed path, so a scalar leaf update copies exactly
the root, child array, and target node rather than cloning the whole tree. A
set-only patch writes its data
and commit sentinel in one `setData` call with a callback. Structural patches
use one `groupUpdates` transaction followed by a sentinel `setData`; replacement
and snapshot recovery use one full-tree `setData`. A revision becomes host-
authoritative only in that callback.

If no acknowledgement arrives within three seconds, the bridge obtains the
runtime's `{ revision, tree }` snapshot and retries one full write. A second
timeout or write failure closes the scheduler. Generation tokens reject stale
callbacks, and unload clears queues, timers, subscriptions, effects, and the
runtime instance. Metrics expose acknowledgement samples/total/max/last
latency, queue depth, received/coalesced events, async drains, retries,
failures, and shadow copy count without changing the typed UI-event shape.

## Generated artifact ownership

The generator emits one application runtime, one release-minified host helper,
one shared protocol/COW helper, one compact indexed initial-tree module, one
recursive `minimoon.templates.wxml`, and one global `app.wxss`. Page WXML files
import the shared template; page WXSS files stay empty. Page JavaScript contains
only an indexed registration and `require` calls.
When `application` is configured, `minimoon.app.js` adds the independent App
scheduler and lifecycle; otherwise `app.js` keeps the no-application registration.

CommonJS is a generated host-format decision, not an application-logic
dependency. Generated JavaScript is audited as ECMAScript 2019, checked for
forbidden syntax and unapproved globals, and tested with missing browser globals
such as `TextEncoder`.

Release evidence uses `fnv1a64-relpath-v2` over the complete raw-byte `dist/`
tree except the developer-local private config, plus the manifest and smoke
checklist. The sorted, length-framed app-relative paths make checkout location
irrelevant while ensuring WXSS, shared WXML, future assets, and manual acceptance
scope cannot drift behind a still-valid evidence record.

App Contract v9 and renderer protocol v8 retain native form/image/slider/progress
controls, precise touch payloads, and build-resource descriptors to the v7
focus/blur/confirm and dialog/menu baseline. Runtime ABI v11 retains the
page-owned local-effect wake/drain contract
independently of the source-level authoring API. `minimal-v1` retains its exact
bytes;
`minimal-v2` extends it with bounded overlay and menu CSS. A stylesheet is
injected only when
`componentTheme` opts in, and its descriptor is recorded in the manifest.

## Maintainer boundaries

The renderer, resident runtime, incremental graph, Val runtime, and verifier are
split at MoonBit `///|` block boundaries. A static gate limits every production
source in those packages and the component packages to 450 lines; tests and
benchmarks remain separate.
`moon info` is the interface authority. Mechanical movement must leave the
root, renderer, runtime, and Val `.mbti` surfaces unchanged; deliberate
versioned authoring changes must produce and review the expected root diff.

MoonBit release minification currently assigns symbols using source-file
boundaries. Therefore a source-only split can preserve `.mbti` and behavior but
still change `minimoon.runtime.js` bytes. Such drift is treated as a real new
artifact fingerprint and requires fresh Developer Tools evidence; old generated
bytes are never restored merely to retain evidence.

## Internal provenance

`internal_duplix` and `internal_slotmap` contain adapted Rabbita 0.13.1 work;
`internal_any` contains the small private erased-value primitive adapted from
Rabbita main at `b6cbf52`.
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) records both original
provenance points. No separate MiniApp facade package owns public core types.
The [Rabbita/RUI audit](https://github.com/lucavance/minimoon/blob/main/docs/reference/rabbita_and_rui_audit.md) compares the
current implementation against Rabbita 0.15.6 and RUI 0.1.1 without changing
those source pins. The independent UI module adapts the pinned RUI capabilities
with its own MIT notices and
[native migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md).

## Independent native UI

Core 0.2 owns finite native controls, precise touch payloads, layout measurement,
and generic build resources. `lampclaw/minimoon_ui` owns component behavior,
Vega theme recipes, icons and its independent six-page verification application.
Core never imports UI; UI imports only public core packages, not renderer or
graph internals. The original optional components remain source-compatible.

`layer` is a typed declarative marker removed by `layer_root` before normal
materialization. Lifted surfaces are keyed siblings after the page body; event
bindings and reactive content remain owned by their original Val scopes.
Removed branches leave no global registry entries. `UiContext` owns page
visibility and one toast queue; UI code does not author JavaScript or setData.

App Contract v9 resources name a dependency provider and a canonical feature list.
A native build probe returns a typed WXSS/static-asset bundle. Validation precedes
destructive output generation. Resource paths, contents and descriptors join the
artifact fingerprint; CSS and SVG strings stay out of the application JS graph.
