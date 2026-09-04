# Minimoon 0.1.0 product baseline

The baseline is a complete MoonBit-to-Skyline path through the root
`lampclaw/minimoon` API. Business logic uses Elm-style state machines, UI and
local ownership compose through `Val`, and the page-owned incremental graph
remains an internal implementation detail.

## Included

- root-owned opaque `Cmd`, read-only `Val`, `Sub`, `PageRuntime`, routes, host
  result types, controls, and navigation types, plus callable `Emit[Msg]`
- `elmish_page` and the six `create_*` helpers, with model-first callbacks,
  `(Val[Model], Emit[Msg])` ownership, and explicit `(Model, Cmd)` results
- one-shot `create_resource` with visible `Val[Status[T]]` state and
  scope-owned late-completion rejection
- `Val::map2`/`view2` through `map9`/`view9`, keyed `assoc`/`assoc_by`,
  `switch`, `enumerate`, and bounded transactional LRU enumeration
- candidate rollback across state, branch ownership, handlers, subscriptions,
  normalized caches, and the rendered tree
- graph-owned generational state dispatch and physically reclaimable ordered
  subscription storage across scope removal, rollback, eviction, and disposal
- commit-gated dynamic branch initialization drained outside graph pulls
- typed controls, including native focus/blur/confirm payloads, and
  deterministic or explicit event keys
- protocol-level `Semantics` for role, label, expanded, selected, disabled,
  hidden, checked, modal, orientation, popup, controls, labelled-by, and
  described-by relationships
- optional normalized-tree testing plus optional headless/styled Disclosure,
  single/multiple Accordion, Tabs, Dialog, Sheet, and Dropdown packages
- re-resolving semantic test scopes and input-driven slots for every component
  with an arbitrary `Node` slot while retaining all static component APIs
- exact `minimal-v1` compatibility plus opt-in, manifest-described
  `minimal-v2` component CSS
- retained-subtree normalization and indexed set/splice/move/full-tree diff
- application-wide runtime plus an ordered, acknowledgement-aware host
  scheduler
- atomic predecoded event batches with a hard 2048-entry bound
- lifecycle, page-owned local async work with ordered host wake/drain, typed
  MiniApp capabilities, and navigation
- native init/build/dev/add/verify/devtools/metrics workflows
- deterministic release generation, host simulation, coverage, size, and
  performance gates
- lossless discrete-event scheduling plus bounded latest-only adjacent scroll
  coalescing and acknowledgement/queue metrics
- archive-validated registry initialization and Linux candidate handoff

## Maintained fixture and starter

| Source | Purpose |
| --- | --- |
| Conformance / Showcase | bilingual product narrative, state, lifecycle, routing |
| Conformance / Home | page input, controlled input, capabilities, navigation |
| Conformance / Lab | set/splice/move/replacement, controlled native reconciliation, reactive slots, scrolling, local components, focus events, overlays, menu semantics, isolation |
| Conformance / Details | independent input/lifecycle and stack-aware fallback |
| `templates/starter` | production-oriented Home + Details initializer source |

## Not included

- an already executed public registry publication, tag, or hosted release
- another renderer target or ESM migration of the verified host boundary
- direct WeChat Developer Tools or physical-device CI automation
- an application backend or real payment workflow

Automated validation must pass before handoff. A release claim additionally
requires fingerprint-matching real-host evidence for the exact App Contract v7,
runtime ABI v10, renderer protocol v7 Conformance bytes. That evidence is a
local release input and is never part of repository or CI state.
