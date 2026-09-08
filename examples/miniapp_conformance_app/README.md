# MiniApp conformance application

This is the core framework's maintained real-host fixture for `0.2.0`.
The independent UI module has its own
[six-page showcase](../../ui/examples/showcase/README.md). One core release build
and one artifact fingerprint cover four page routes:

- `src/pages/showcase`: bilingual Minimoon Studio narrative, local state,
  lifecycle feedback, and navigation into every technical validation route.
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
- `src/pages/details`: independent page state, query decoding, lifecycle, and
  stack-aware back-or-redirect behavior.

The optional `src/app` package owns shared count and HTTP state. Home and
Details bind the same App values while keeping their local models; all four
page factories accept its `Deps`. Starter and UI showcase retain the separate
no-application entry path.

Build a release-mode candidate and verify it from the repository root:

```bash
bun run minimoon verify examples/miniapp_conformance_app --candidate
```

Import the unchanged `dist/` directory into WeChat Developer Tools for the
release checklist. In Home, select each HTTP scenario and tap Request. The
default public API is `https://httpbingo.org`: GET query, JSON/form POST, text
PUT, DELETE, HEAD, OPTIONS, HTTP 400/500 and timeout. Inspect the status code
and selected echo fields; non-2xx is a loaded result, timeout is failed.
Leave Home during the delayed request to check disposal. No private server is
needed. From the repository root, `bun run check:http-live` exercises the same
generated Home with a fetch transport shim; it is not a real WeChat pass.
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
