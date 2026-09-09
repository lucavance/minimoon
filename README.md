# Minimoon

[中文文档](README.zh-CN.md) · [Documentation](docs/README.md) · [Bilingual code analysis](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/README.md)

Minimoon is MoonBit for WeChat MiniApp Skyline. Version `0.2.0` combines an
Rabbita-style component composition and Elm-style state machines with App Contract v11, runtime ABI v13, renderer protocol
v8, and a CommonJS MiniApp host boundary.

```text
Model / Msg / update / Cmd / Sub
  -> Page and local component composition through Val
  -> page-owned transactional incremental graph
  -> normalized MiniApp tree and revisioned diff
  -> ordered host scheduler and acknowledged Skyline render
```

Applications import `lampclaw/minimoon` and may opt into the independent
`lampclaw/minimoon_ui` module. Authors do not write `setData`,
JavaScript bridges, mutable signals, projection fields, or renderer patches.
Local components may still own state machines inside keyed or dynamic `Val`
branches.

## Install and create an app

For a published version, install the matching registry CLI and create a
standalone application:

```bash
moon install lampclaw/minimoon/cmd/minimoon@0.2.0
minimoon init /tmp/my-app
cd /tmp/my-app
bun install
minimoon build .
minimoon verify .
```

Registry mode keeps `lampclaw/minimoon@0.2.0` in `moon.mod` and emits no
`moon.work`. Current publication availability is recorded in the repository's
[project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).
For local framework development, run `moon install --path src/cmd/minimoon`
from a Minimoon checkout, then `minimoon init /tmp/my-app --minimoon-root "$PWD"`.
That explicit option creates a workspace binding to the checkout.

The CLI embeds one production-oriented two-page `starter` and supports
incremental development and typed scaffolding:

```bash
minimoon dev .
minimoon add page activity_log --after home --title "Activity Log"
minimoon add component status_badge --page home
```

## Authoring model

Typed `request` supports HTTP methods, ordered queries, headers, JSON/form/text
bodies and timeouts. Use the optional [typed HTTP package](docs/guides/http.md)
for status policy and typed response decoding; raw `request` retains transport
semantics. See the [HTTP contract](docs/reference/miniapp_host_capabilities.md#http-requests).
Run `bun run check:http-live` from this checkout for opt-in public-API testing
of the generated Platform page; it does not replace WeChat host acceptance.

Without `application` configuration, each page package exports
`program() -> Page`, as below. With `application`, pages instead export
`program(deps : @application.Deps) -> Page`; see
[shared-state setup](docs/guides/shared_state.md).

```moonbit
pub fn program() -> @minimoon.Page {
  @minimoon.page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    build=_ => {
      let (count, update_count) = @minimoon.create_variable(0)
      count.view(value => @minimoon.div([
        @minimoon.h1(value.to_string()),
        @minimoon.button(
          on_tap=update_count(current => current + 1),
          event_key="increment",
          "+1",
        ),
      ]))
    },
  )
}
```

Ordinary `page` builders and component functions returning `Val[Node]` are the
primary style. `elmish_page` remains a convenience for simple one-model pages.
Local and input-driven components use `@minimoon.create_state`, `create_state_with_init`, or
`create_state_with_input`; every constructor returns `(Val[Model], Emit[Msg])`.
Updates return `(Model, Cmd)` through `@minimoon.no_cmd`, `with_cmd`, or `with_cmds`.
`create_pure_state` covers pure updates, while `create_variable` covers
function-valued updates. `create_resource` starts one committed load and returns
`Val[Status[T]]`; its first committed terminal completion wins, while retry and
refresh remain explicit application state.

`Cmd` is opaque and non-generic at the public boundary. Compose `none`, `batch`,
`delay`, `effect`, `perform`, and `attempt`, or use typed root functions such as
`login`, `get_storage`, `request`, and `navigate_to`. Message and host-result
sinks use callable `Emit[T]`; `Emit::map` adapts child payloads without exposing
mutable state.

A page-local `Emit` carries a private graph/state address. The matching dispatcher
lives in a graph-owned generational registry, so a command executed in another
page graph, after its scope is reclaimed, or after page disposal is a
deterministic no-op. Subscription entries use the same reclaimable ownership
rule; hidden retained scopes pause them, while removed or evicted scopes free
their registry slots.

An application-owned `Emit` instead addresses its App's domain machine. A page
may use it across the page/App boundary; delivery leaves the page outbox only
after the page transaction commits. Page unload does not invalidate that App
address, while App disposal does.

`Val` is an incremental value inside one page graph, not a mutable signal.
`Val::map2` through `map9` combine arbitrary independent values, while
`Val::view2` through `view9` specialize Node-producing composition. `assoc`/`assoc_by`
preserve keyed local ownership. `switch` replaces a branch on tag changes;
`enumerate` caches a finite tag domain; `enumerate_bounded_by` adds a
transactional LRU limit for an unbounded domain.

Dynamic branch initialization is published only after its candidate projection
commits. Rejected branches never run initialization commands, while committed
initialization drains outside the graph pull and may safely create another
dynamic branch.

State, event routes, subscriptions, branch caches, normalized subtrees, and the
rendered tree commit together. A rejected candidate restores the complete
previous transaction.

For required route input, use `page_with_input(preview_input=..., decode_input=...,
build=...)`. Definition is inert, previews use only the explicit preview seed,
and actual input is decoded before any page graph is built. The builder receives
plain input, so local state starts with the real route value. Runtime creation
returns `Result[PageRuntime, DecodeError]`; first Load sends a full revision-1
tree, and initial commands run once at Ready/mount. See
[input and lifecycle ergonomics](docs/guides/api_ergonomics.md#page-input-and-first-render).

Optional packages keep production imports explicit. `lampclaw/minimoon/testing`
queries and drives the actual normalized MiniApp tree through re-resolving
semantic scopes and native-shaped interactions.
`testing.launch` adds an App-aware owner, `app.mount` creates its pages, and
bounded `quiesce` drains ready shared/local work without waiting for future
timers or unresolved HTTP. Page disposal does not dispose App. The headless
`lampclaw/minimoon/components` package supplies controlled and self-owned
Disclosure, single/multiple Accordion, Tabs, Dialog, Sheet, and Dropdown;
`lampclaw/minimoon/components/styles` binds those structures to the opt-in
`minimal-v2` theme. Every component with an arbitrary `Node` slot also has an
additive `_with_input` form for a reactive child slot without changing existing
static APIs. Root `Semantics` values carry dialog/menu roles, checked and
modal state, orientation, popup ownership, labels, and descriptions through the
checked renderer protocol. Native `input` and `textarea` focus, blur, and
confirm payloads remain typed at the authoring boundary.

## Optional Minimoon UI

The independently versioned `lampclaw/minimoon_ui 0.1.0` module targets core
`0.2.0`. Import it as `@ui` alongside the root framework. It adapts RUI
0.1.1 to typed MiniApp nodes, page-owned state, touch interaction and opt-in
Vega WXSS. Existing optional components and minimal themes remain compatible.
See the [UI guide and source](https://github.com/lucavance/minimoon/tree/main/ui)
for installation, the component capability map and the six-page showcase.

Core 0.2 adds typed native controls, touch events, layout measurement and
declarative `layer`/`layer_root` composition. Build-only resource providers
supply WXSS and SVG assets without linking UI resources into application JS.
These new bytes require fresh Skyline validation; candidate status does not
imply a published package or a real-host pass.

## Application-owned shared state

Opt into `App[Deps]` when pages share session, preferences or request state.
The App builder creates independent typed domain machines; pages bind `Shared[T]`
with `PageContext.bind/select` and retain their own local models. Shared requests
survive page unload, foreground intervals pause on Hide, and explicit App
disposal cancels tasks and rejects late delivery. There is no required global Model.
Effect ownership follows the runtime executing the `Cmd`, not the result
emitter: to keep a request alive across page unload, send a business message to
App and return the request from its update.
See [shared-state setup and acceptance](docs/guides/shared_state.md).

## MiniApp boundary

Configuration uses App Contract v11. `componentTheme` is optional; omitting it
adds no built-in component CSS:

```json
{
  "schemaVersion": 11,
  "name": "my_app",
  "componentTheme": "minimal-v2",
  "pages": [
    { "package": "src/pages/home" },
    { "package": "src/pages/details" }
  ]
}
```

`devtoolsChecks` may optionally declare ordered, application-specific manual
checks. They are appended to `generated/smoke_checklist.json` and travel with
the CI Developer Tools handoff.

Optional native bottom `tabBar` configuration references listed page packages;
`switch_tab(Route)` requires `SwitchTab` and a query-free tab route.
`PageContext.layout()` provides read-only window, safe-area and capsule metrics
before the first business tree. Build resources support text and PNG bytes.
See [native tabs and layout](docs/guides/native_navigation.md). Conformance uses
four tabs (首页 / 交互 / 平台 / 应用) and retains three secondary acceptance routes.

Generated applications contain one `minimoon.runtime.js`, one
`minimoon.host.js`, one `minimoon.protocol.js`, one compact
`minimoon.initial.js`, one shared `minimoon.templates.wxml`, and one global
`app.wxss`. Each page keeps only a small indexed registration bridge, a template
import, JSON, and an empty page WXSS file.
Opting into `application` also generates `minimoon.app.js` for the App-owned
scheduler and lifecycle; the no-application path retains `App({})` registration.

The host scheduler starts the first entry immediately, allows only one render
in flight, and preserves entry order. Discrete events such as taps are always
lossless and ordered. Adjacent same-key, same-type scroll or changing events,
and same-key touchmove events with the same touch identity, may collapse while
waiting behind an acknowledgement; a tap is a coalescing barrier.
A whole event batch is decoded before any state changes. Render completion is
acknowledged through a commit sentinel and the `setData` callback. A three-second
timeout performs one authoritative snapshot retry; a second failure closes that
page scheduler instead of accepting uncertain state. Queue depth, coalescing,
acknowledgement latency, retry, timeout, and COW shadow-copy work are observable
through renderer stats.

Runtime ABI v13 also gives page-owned local async commands an ordered host wake
path. Suspended `perform` and `attempt` work can drain their resulting commands
without waiting for another tap or lifecycle entry. Disposal cancels owned
delivery, and framework `delay` timers are physically cleared by the host.

## Build and real-host validation

```bash
minimoon build . --mode dev
minimoon verify .
minimoon build . --mode release
```

Import the unchanged `dist/` directory into WeChat Developer Tools. Use Skyline,
keep ES6-to-ES5 transformation, enhanced compilation, and code minification
enabled (`setting.es6=true`, `setting.enhance=true`,
`setting.minified=true`), and configure an online minimum base library of
3.17.0 or newer.

Real-host evidence is valid only for the exact release bytes. After completing
the checklist, record the actual tool version and timestamp:

```bash
minimoon devtools record . \
  --status passed \
  --recorded-at <actual-timestamp> \
  --tool-version "<actual-version>" \
  --notes "Minimoon 0.2.0 checklist passed"
minimoon verify . --release
```

`generated/devtools.evidence.json` is local and Git-ignored. Its timestamp,
tool version, notes, and outcome are never committed or uploaded by CI.

## Repository validation

```bash
moon info
moon fmt --check
moon test --target native
moon test --target js
bun run check:coverage
bun run check:docs
bun run check:api
bun run check:candidate
git diff --check
```

`check:api` locks the core `0.2` root and resources interfaces exactly, compiles
the current 0.2 consumer, and permits only additive changes in the optional
components, styles and testing packages. UI `0.1` has separate additive
snapshots for its root, headless, theme and resources packages.
The frozen 0.1 consumer remains historical source, not a promise that old
application calls compile unchanged against the current candidate.
`check:candidate` is the Linux-safe automatic handoff gate; a successful run
leaves tracked reports in candidate state, even when local evidence exists.
Coverage is the separate `check:coverage` gate shown above. For a
local release decision, run `bun run check:all` followed by
`bun run check:mvp`; both require current fingerprint-bound Developer Tools
evidence for both the seven-route core fixture and six-page UI showcase. Rerun
`check:candidate` before publication and staging to restore public reports;
require unchanged fingerprints and a clean source checkout. The
[release runbook](docs/operations/release_candidate_handoff.md) defines the
ordered core/UI publication and registry-only consumer checks.
The repository archive gate uses `moon package --frozen --list`, then enforces
the registry archive allowlist and independently reviewed hard ceilings:
320 KiB for core with at least 8 KiB reserved, and 250 KiB for UI with at least
16 KiB reserved. These are repository budgets, not registry service limits.

Repository checks use fresh run directories in `../.minimoon-check-tmp/`, on
the checkout's parent volume and outside its Moon workspace. Override the base
with `MINIMOON_CHECK_TMPDIR` (relative to the checkout or absolute). The parent
process cleans its run after success, failure or worker crash; child tools
inherit that run's `TMPDIR`, `TMP` and `TEMP`. See the [temporary-storage
notes](docs/operations/release_candidate_handoff.md#validation-temporary-storage).

The supported floor is `moon 0.1.20260904` with `moonc v0.10.12`. Both CI jobs
use the official installer pinned to prebuilt release `0.10.12+1634b282e`,
not latest; no Rust is required. The local `moon 0.1.20260907` combination
revalidated on 2026-09-08 remains valid and does not need downgrading.
Repository and generated-starter tooling support Node
`>=24.20.0`; CI validates the Node 24.20.0 lower boundary and the Node 26.8.1
primary environment, while Bun is pinned to `1.4.2`. The only maintained
standalone JavaScript is `scripts/bridge/weapp_tailwindcss_adapter.mjs`;
production and validation host sources are MoonBit-owned templates, while
committed MiniApp JavaScript is generated.

```text
src/
  authoring_*.mbt         public root API
  val_runtime/            graph-owned values, commands, and subscriptions
  internal_any/           private erased payload boundary for graph registries
  internal_duplix/        incremental transactions and keyed scopes
  renderer_miniapp/       normalized tree, diff, and split page runtime
  runtime_core/           resident state-machine runtime
  internal_host_js/       published scheduler, protocol, and verify sources
  internal_host_validation/ repository-only host/docs/perf validation
  testing/                optional normalized-tree test runtime
  components/             optional headless and styled components
  tooling_miniapp/        App Contract v11 artifact generator
  tooling_minimoon_*      build and verification pipeline
  cmd/minimoon/           native CLI and embedded starter
examples/
  miniapp_conformance_app/ core seven-route/four-tab real-host fixture
ui/                       independent native component module
  examples/showcase/      UI six-page real-host fixture
```

Minimoon `0.2.0` remains pre-1.0. Product version is defined by `moon.mod` and
`CHANGELOG.md`; version Git tags are not used.
