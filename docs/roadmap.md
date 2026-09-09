# Roadmap

## Near-term priorities

Keep the source-based Starter onboarding and English/Chinese documentation
consistent, finish the exact-artifact release prerequisites, and validate fresh
registry consumers when publication is authorized. Implemented capabilities are
described below; release readiness is separate from implementation completion.
Deferred directions are not dated feature commitments.

## Native navigation and Conformance presentation

The unpublished core `0.2.0` / UI `0.1.0` iteration adds native bottom tabs,
typed tab navigation, read-only window/safe-area/capsule layout and PNG build
resources. Conformance presents 首页 / 交互 / 平台 / 应用, with Request Lifecycle,
Runtime Lab and Draft Editor as task-specific secondary routes. Platform owns
HTTP/wx capabilities, Interaction owns the core component catalogue, and
Application is the only complete shared-state controller. Shared scene functions
replace page-to-page implementation reuse; the header has a shallow curved hero
edge without changing fixed navigation geometry. It remains one core fixture, not seven independent applications.
See [native navigation and layout](guides/native_navigation.md).

The earlier shared-host changes require exact-fingerprint acceptance for both
core and UI. The presentation consolidation changes only the core fixture: it
requires a fresh core pass; unchanged UI/Starter bytes are not a new UI migration. Custom TabBar, badges, dynamic navigation colors and new public UI
components are outside this iteration. Product versions remain unpublished;
Contract 11 and runtime ABI 13 do not change renderer protocol 8.

## HTTP and application state

The current ergonomics revision keeps Rabbita-style ordinary component
functions and `create_*` / `Val` composition as the main path; `elmish_page`
remains a one-model convenience. Real page input is decoded before runtime
construction, explicit compile previews execute no commands, and the first
Load renders revision 1 before later host work. App-aware tests cover shared
queues and independent page disposal. See [API ergonomics](guides/api_ergonomics.md)
and [typed HTTP](guides/http.md). The current technical boundaries are Contract
`11`, runtime ABI `13`, and renderer protocol `8`; source schemas from previous
iterations require migration rather than compatibility fallbacks.

The current HTTP iteration adds typed methods, query/header/body encoding,
timeouts, deterministic host tests and public-API Platform acceptance scenarios.
It introduces no UI components or privately deployed acceptance server.
The current 0.2 source implements an optional `App[Deps]` root containing
multiple typed domain state machines. `Shared[T]` values bind to page-local
`Val` projections; pages keep their own models and transactional rendering.
Application effects survive page unload, foreground subscriptions pause on
Hide, and explicit disposal invalidates stale delivery. See
[shared state](guides/shared_state.md) for ownership, migration and acceptance.
Dynamic account/workspace scopes remain deferred; business request epochs
invalidate responses after logout or reset. Generated-byte changes require a
separate byte-budget review and exact-artifact Skyline validation before release.

## 0.1.0 first non-prerelease release

The original `0.1.0` public baseline established:

- Elm-style state machines, callable `Emit`, transactional `Val` composition,
  and page-owned effects and subscriptions;
- contract and renderer version `7`, CommonJS output, and
  Skyline Page Definition API registration;
- normalized tree testing plus optional headless and styled component
  packages;
- one two-page starter and one maintained four-page Conformance fixture;
- deterministic coverage, API, generator, host, performance, archive, and CI
  gates.

The public repository keeps only reproducible candidate state in
[`verify_report.json`](../examples/miniapp_conformance_app/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_conformance_app/generated/release_summary.json),
while fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_conformance_app/generated/devtools.evidence.json)
is local and Git-ignored. Local release verification does not publish its
timestamp, tool version, notes, or outcome in the repository.

## 0.1.1 starter maintenance

The `0.1.1` patch keeps the 0.1 public API and generated host protocols
unchanged while making a fresh `minimoon init` formatter-stable under the
supported MoonBit toolchain. It also expresses JavaScript runtime compatibility
as Node `>=24.11.0` rather than an exact local-version file. Generator and CI
gates enforce both properties.

## 0.1.x maintenance

1. Treat the exact gate-passing 0.1.0 archive as the immutable registry baseline.
2. Drive API additions from sustained application dogfooding rather than
   expanding the public surface speculatively.
3. Extend the Conformance fixture before adding another release fixture.
4. Revalidate generated-byte changes in the real WeChat host.

## Historical RUI subset assessment (superseded)

The dependency refresh and
[Rabbita 0.15.6 / RUI 0.1.1 audit](reference/rabbita_and_rui_audit.md) establish
the earlier proposed component iteration. That assessment only scheduled work;
the approved full migration below supersedes it. The audit mapped all 64 RUI
showcase entries; six had
existing optional-component counterparts, while other entries include native
substitutes, style recipes, reusable behavior gaps, and browser-only designs.

It proposed Field/Alert Dialog first, then native Slider/searchable selection,
then Message Scroller and notifications. That scheduling is no longer an
outstanding component backlog: the approved full-native implementation below
covers those families and the subsequent data/date/navigation candidates.
Browser-only APIs remain intentionally replaced by native contracts, not
promised as future DOM compatibility.

## Core 0.2 and independent UI 0.1

The approved full-native migration supersedes the earlier demand-driven subset.
Its fixed source is Rabbita 0.15.6 / RUI 0.1.1 at `b1291945`; it covers all 64
showcase components plus Form/Theme and public auxiliary capabilities.
The implementation includes core foundations, 20 presentation components,
13 overlays/disclosures, 14 form controls, 8 data/date components, 6 layout/navigation
components and 3 feedback components.

The independent `lampclaw/minimoon_ui` module has default, headless, theme and
build-resource packages. Core 0.2 provides missing native controls and measurement.
The current App Contract v11, runtime ABI v13 and renderer protocol v8 include
application ownership while preserving the CommonJS host boundary.
Old components and minimal themes remain compatible; the starter does not gain
an implicit UI dependency.

The [UI migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md)
distinguishes actual implemented capabilities, native substitutions and outstanding
work. API names or 64 showcase headings alone are not evidence of full parity.
Both applications require exact-fingerprint Skyline validation before release.

The UI fixture's
[`verify_report.json`](../ui/examples/showcase/generated/verify_report.json)
and [`release_summary.json`](../ui/examples/showcase/generated/release_summary.json)
are independent public candidate records. Its
[`devtools.evidence.json`](../ui/examples/showcase/generated/devtools.evidence.json)
is local and Git-ignored, just like the core fixture's evidence above.

## Release preparation

Freeze the synchronized documentation, core/UI archives, source commit and
two CI handoff bundles before manual acceptance. Follow the
[release runbook](operations/release_candidate_handoff.md): both fixtures need
real Skyline acceptance, then local release gates, candidate report restoration,
and unchanged fingerprints before core-first/UI-second registry publication.
Fresh consumers outside all workspaces verify actual registry resolution.
Current publication availability belongs in
[project status](project_status.md), not in immutable package contents.

## Deferred

- ESM output; CommonJS remains the verified host boundary.
- Additional render targets.
- Backend-owned payment completion.
- Broad example expansion without independent verification value.
