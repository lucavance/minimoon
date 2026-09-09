# MiniApp conformance application

This is the core framework's maintained real-host fixture for `0.2.0`.
The independent UI module has its own
[six-page showcase](../../ui/examples/showcase/README.md). One core release build
and one artifact fingerprint cover seven routes: four native bottom Tabs and
three independent stack probes. App Contract `11` / runtime ABI `13` retain
renderer protocol `8`.

| Native Tab | Source | Purpose |
| --- | --- | --- |
| 首页 | `src/pages/showcase` | introduction, live state, Tab shortcuts and stack-probe entry points |
| 交互 | `src/pages/interaction` | the ordinary Lab scene with concise presentation and expandable runtime probes |
| 能力 | `src/pages/capabilities` | the ordinary Home scene with its own page-local state and effects |
| 应用 | `src/pages/application` | shared application domains and the draft-detail entry point |

The three non-Tab pages remain real navigation-stack probes:

- `src/pages/home`: query input, controlled input, Elm-style state, lifecycle,
  declared `wx.*` capabilities, and command-driven navigation.
- `src/pages/lab`: dynamic set/splice/move/replacement diffs, vertical scrolling,
  a controlled keyed-input probe that preserves focus, cursor, selection, and
  value while moving only another keyed identity, a same-identity controlled
  value reset probe, `Val.assoc_by` local
  components, disposable subscriptions, explicit delay/perform/attempt probes,
  native controls and focus events, swiper, Disclosure/single/multiple
  Accordion/Tabs, Dialog/Sheet/Dropdown semantics, the `minimal-v2` theme, and
  same-route instance isolation.
- `src/pages/details`: required nonempty `from` query, independent lifecycle and
  draft state, typed JSON echo, and stack-aware Back with a Home Tab fallback.

The optional `src/app` package owns shared count and HTTP state. Home and
Details and the relevant Tabs bind the same App values while keeping their local
models; all seven factories accept its `Deps`. Reused scene functions create
new local state in each builder, not shared page instances. Starter and UI showcase retain the separate
no-application entry path.

The fixture-local `shared/shell` reads `PageContext.layout()` in logical pixels.
Its fixed deep-blue navigation band reserves the real capsule rectangle; the
hero and cards scroll beneath it. Missing metrics use the reviewed 88px band
and 96px right reservation. Bottom safe padding is the intersection with the
actual window, so the native Tab bar is not counted twice. Every page requests
white navigation text. The build-only resource provider owns the dark `page`
boot background and eight 72px PNG Tab icons derived offline from this fixture's
original `assets/icons/*.svg`; none is fetched externally or imported into the
application JavaScript.

Build a release-mode candidate and verify it from the repository root:

```bash
bun run minimoon verify examples/miniapp_conformance_app --candidate
```

Import the unchanged `dist/` directory into WeChat Developer Tools for the
release checklist. Check 首页/交互/能力/应用 order, selected icons and restoration
of each Tab's local state; Tab changes must use `switchTab` without query and
must not grow the navigation stack. Check initial/resize capsule clearance,
scrolling hero, white status text on dark blue, keyboard and bottom safe area
on all seven routes. Tab switching hides a page; it is not unload evidence.

Use 首页's 能力探针/交互探针/编辑详情 buttons to enter the retained stack routes.
Home → Details → Back must retain Home's instance and state. Home Redirect →
Details must unload Home. Lab's native navigator opens a second same-route
instance with independent state. Direct valid Details entry returns to the
Home Tab on Back; missing/empty `from` must fail closed without a live instance
or preview flash. The configured `smokeInput` is synthetic test input, not a
runtime default.

In the non-Tab Home probe, select each HTTP scenario and tap Request. The
default public API is `https://httpbingo.org`: GET query, JSON/form POST, text
PUT, DELETE, HEAD, OPTIONS, HTTP 400/500 and timeout. Inspect the status code
and selected echo fields; non-2xx is a loaded result, timeout is failed.
Leave Home during the delayed request to check disposal. No private server is
needed. From the repository root, `bun run check:http-live` exercises the same
generated Home with a fetch transport shim; it is not a real WeChat pass.
Details rejects an empty draft without HTTP; a valid title/note is sent to the
public POST echo endpoint and only the typed echo is shared with Home and 应用.
It is not persistent storage. Editing or unloading rejects old responses.
Also increment the shared count on Home and Details, then start the separate
shared public API request and unload its page: another page must receive the
App-owned result. Start again and Clear before completion; the obsolete response
must not replace idle. Page-owned HTTP still aborts on unload. See the
[shared-state guide](../../docs/guides/shared_state.md) for the ownership distinction.
See the [host checklist](../../docs/operations/miniapp_devtools_validation.md)
for simulator/device modes and public-domain restrictions.

In Lab, exercise these probes explicitly:

1. Enter a unique value in the keyed input. Tap `Arm focused reorder (10s)`,
   refocus the input, place the cursor or select a range, and then do not touch
   the page for 10 seconds. Item C must be the only moved identity; the same
   input must retain focus, cursor/selection, and the controlled value. The
   renderer-stat delta for the timed reorder must be exactly one move and two
   host writes, with no set, splice, replacement, or fallback.
2. Tap `Start delay probe` and make no further input. Its running state must
   become completed after the 600 ms host timeout. Tap `Start async probes` and
   again make no further input; the 250 ms perform must succeed and the 400 ms
   attempt must report its planned failure.
3. Repeat each start action and immediately unload the Lab page. No delayed
   render, state update, warning, or error may appear after disposal.
4. Enter a non-default keyed-input value, then tap `Reset controlled input`.
   The same focused native input identity must remain mounted while its value
   and greeting return to `Minimoon`; renderer stats must show scalar sets only.

Also include rapid repeated taps, focus/blur/confirm, overlay and menu
dismissal/selection, shared-template rendering, and a clean
scheduler/retry/timeout counter check. Automated status lives in
`generated/verify_report.json`; real-host evidence is valid only for the exact
artifact fingerprint recorded in the local, Git-ignored
`generated/devtools.evidence.json`. Never commit or push that file.

CI publishes this candidate as `minimoon-devtools-<commit>`; the UI bundle is
`minimoon-ui-devtools-<commit>`. Both need their own Skyline acceptance before
the paired release. Follow the
[handoff runbook](../../docs/operations/release_candidate_handoff.md).
