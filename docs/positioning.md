# Positioning

Minimoon is **MoonBit for WeChat MiniApp Skyline**.

It is not a web framework, DOM compatibility layer, or generic cross-platform
renderer. The product concentrates on one path:

```text
Elm-style Model / Msg / update / Cmd / Sub
  -> Val-based Page and local component composition
  -> page-owned transactional incremental graph
  -> normalized MiniApp tree and revisioned diff
  -> generated Skyline artifacts and declared wx.* adapters
```

Minimoon is Elm-style without forcing one global application model. A local
component can own a state machine inside a keyed or dynamic `Val` branch. `Val`
is a read-only incremental value; mutable signals are not public.

## Product surface in 0.2.0

- module: `lampclaw/minimoon`
- state: opaque `Cmd`, callable `Emit[Msg]`, and model-first tuple updates;
  `create_pure_state`, `create_state`, `create_state_with_init`,
  `create_state_with_input`, `create_variable`, and one-shot `create_resource`
- ownership: private graph/state generations resolve emitters without retaining
  obsolete handlers; state and subscription registry entries are reclaimed
  with their scopes
- transitions: `no_cmd`, `with_cmd`, and `with_cmds` construct explicit
  `(Model, Cmd)` results; there is no public mutable state handle
- composition: opaque read-only `Val`, `Val::map2` through `map9`,
  `Val::view2` through `view9`, keyed ownership, and dynamic branch operators
- page definition: ordinary `page` / `page_with_input` builders are primary;
  `elmish_page` remains a convenience for simple one-model pages. Required input
  is decoded before graph creation; preview seeds are explicit and effect-free
- optional application ownership: `App[Deps]` and multiple typed domain
  machines, with `Shared[T]` bound/selected into page-local `Val` projections
- subscriptions: opaque `Sub` and separately owned App/page lifecycle and
  interval helpers
- host work: typed root functions, `Capability`, `HostError`, and `Route`
- async ownership: ordered no-touch completion, generation-bound delivery, and
  physically cancelable framework delays
- semantics: root `Semantics` values carried through the normalized tree
- optional packages: normalized-tree testing, headless interactive components,
  additive input-driven content slots, and versioned `minimal-v1` /
  `minimal-v2` styles
- host target: WeChat MiniApp Skyline and App Contract v11
- generated module format: CommonJS

The author-facing `(Val, Emit)` shape is influenced by Rabbita, but Minimoon
owns a distinct host, lifecycle, transaction, renderer, and deployment
boundary. Neither framework exposes a mutable `Signal`; Minimoon applications
also cannot manipulate graph cells, host patches, or raw `wx.*` callbacks.
Original source provenance is recorded in
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md); the
[Rabbita/RUI audit](https://github.com/lucavance/minimoon/blob/main/docs/reference/rabbita_and_rui_audit.md) records the pinned
historical capability comparison; the independent UI
[migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md)
records the implemented native adaptations.

## Success criterion

Minimoon succeeds when a MoonBit application can express stateful, keyed,
lifecycle-aware MiniApp pages without handwritten JavaScript, while generated
release bytes remain deterministic, bounded, and independently verifiable in
WeChat Developer Tools.

## Optional native component library

Core `0.2.0` supports the separately packaged `lampclaw/minimoon_ui 0.1.0`
library. Its native
RUI adaptation follows the same Val/page ownership model; it does not introduce
HTML, DOM, SSR, browser events or handwritten bridge authoring. UI is opt-in,
independently versioned and excluded from the core registry archive.
