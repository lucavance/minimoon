# MiniApp renderer

The application-facing renderer input is `Val[Node]`. Lower-level event
registries, normalization, tree diff, and page runtime are implementation
details behind the root package.

## Render transaction

1. A single event or fully predecoded event batch begins a graph transaction.
2. State slots, keyed branches, handlers, and subscriptions are staged.
3. Reading the root `Val[Node]` materializes controls and private retained
   identities.
4. One checked traversal validates and normalizes changed subtrees.
5. The renderer derives at most one revisioned command.
6. Success commits every staged owner; failure restores the previous graph and
   emits `invalid_view`.

## Normalized tree and diff

Renderer protocol v7 nodes contain kind, identity, text, typed props/events,
and children. The diff can emit scalar `set`, array `splice`, keyed `move`, or
an atomic `ReplaceViewTree`. Private retained identities are stripped before
the protocol boundary.

Patch selection is size- and cost-bounded. The host validates every operation
against its shadow before writing. Set-only patches use one `setData` call.
Structural patches use one `groupUpdates` transaction plus a commit-sentinel
`setData`. Full replacements and snapshot recovery use one full-tree
`setData`. The host advances its authoritative revision only in the callback.

## Controls and shared WXML

The recursive control template lives once in
`dist/minimoon.templates.wxml`. Page WXML imports it and binds the page-owned
tree. Input, textarea, switch, checkbox/radio, picker, swiper, and scroll
decoders validate `detail` shape before any state changes.

WXML event attributes and JavaScript Page handlers are generated as one pair.
Cross-layer tests require exact tap/input/change/confirm/focus/blur/scroll/
upper/lower handler parity.

Event decoders fail closed. All six scroll geometry fields are required JSON
numbers and remain `Double`, including fractional values and signed deltas.
Focus height, textarea cursor, picker index, swiper
current, request status, and media integer fields accept only exact values in
`0..2147483647`; numeric strings, fractional values, negatives, overflow, and
wrong JSON types are rejected rather than coerced. Official extra object fields
remain forward-compatible. A malformed entry changes neither model, commands,
nor snapshot; predecoding keeps a malformed batch atomic.

## Ownership and cleanup

Every mounted page owns one graph, runtime instance, host shadow, and scheduler.
Keyed and dynamic branches own nested scopes. Page disposal invalidates emitters,
stops intervals/effects, clears queued host entries and acknowledgement timers,
and rejects stale callbacks through a new generation token.
