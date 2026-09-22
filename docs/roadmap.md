# Roadmap

## Near-term priorities

Keep registry-based Starter onboarding and English/Chinese documentation
consistent. Once availability is recorded in project status, application
authors use `moon install lampclaw/minimoon/cmd/minimoon@0.2.4` and
`minimoon init my-app`. Source installation remains available for framework
development and unpublished candidates. The current source pair is core
`0.2.4` / UI `0.1.2`, with UI declaring core `0.2.4`.

Implemented capabilities are described below. CI, registry availability and
real-host acceptance remain distinct results. Deferred directions are not
dated feature commitments.

## Core 0.2.4 / UI 0.1.2 corrections

- Fix keyed batch growth and nested branch visibility during cache restoration
  and rollback, preserving the existing public API and diff budgets.
- Surface lifecycle decoder failures without committing candidate state or
  effects; failed Load decoding remains retryable.
- Dispose App resources after verification, bound child execution and honor
  custom configuration/output paths throughout verification and evidence.
- Preserve Slider gestures when unrelated pointers are canceled.
- Publish core first, then the independently reviewed UI archive; validate new
  registry consumers and upgrades from core `0.2.3` / UI `0.1.1`.

The user authorizes both patch publications after complete local candidate checks
and both CI jobs on the frozen commit, without waiting for new host validation.
Notify the user of CI success and continue publication. Both CI handoff bundles
remain pending for the user's validation on another machine; evidence gates
are unchanged. See the [scoped release exception](operations/release_candidate_handoff.md#scoped-publication-exception).

## Core 0.2.3 vp migration (completed)

- Use global `vp 0.3.3` for JavaScript package management, repository tasks,
  internal tool launches, CI, documentation and generated Starter guidance.
  Bun `1.4.2` remains the managed package-manager/runtime backend.
- Select Node `26.10.0` through `devEngines.runtime` and retain Node `>=24.20.0`
  support with an explicit lower-bound CI environment. No `.node-version`
  or local `vite-plus`, Vite or Vitest dependency is introduced.
- Retain the MoonBit `0.10.14+7d59c7ec9` toolchain, reviewed dependencies,
  public API and Contract `11` / ABI `13` / protocol `8`.
- Publish only core `0.2.3`; UI stays at the already published `0.1.1`.
  Validate new and upgraded Starters plus the combined registry consumer.

The completed core-only publication and its independent consumer results are
recorded in [project status](project_status.md). It did not establish a host pass.

## Draft Workbench demonstration

The current source preserves the checked core 0.2 and UI 0.1 API baselines.
The former Conformance engineering name is
migrated to `miniapp_draft_workbench`, keeping its core verification responsibility.

Four business Tabs — 工作台 / 草稿 / 联机 / 更多 — connect local CRUD with
typed public HTTP echo and App/Page lifetime. Draft Editor and four secondary
laboratories keep the total at nine routes. Unsaved input is App-owned for this
run; successful storage is required before reporting saved records.

The shallow curved hero and fixed safe navigation geometry are retained.
No backend, account, cloud sync, autosave or UI component expansion is planned.
Both changed fixture artifacts need new validation before claiming host
acceptance. The package publication exception does not establish that result.
Prioritize regression, device validation and a reproducible three-minute demonstration.
See the [workbench guide](../examples/miniapp_draft_workbench/README.md).

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
separate byte-budget review and exact-artifact Skyline validation before a host
acceptance claim.

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
[`verify_report.json`](../examples/miniapp_draft_workbench/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_draft_workbench/generated/release_summary.json),
while fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_draft_workbench/generated/devtools.evidence.json)
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
Both applications require exact-fingerprint Skyline validation for a host
acceptance claim; the current publication exception leaves that result pending.

The UI fixture's
[`verify_report.json`](../ui/examples/showcase/generated/verify_report.json)
and [`release_summary.json`](../ui/examples/showcase/generated/release_summary.json)
are independent public candidate records. Its
[`devtools.evidence.json`](../ui/examples/showcase/generated/devtools.evidence.json)
is local and Git-ignored, just like the core fixture's evidence above.

## Release preparation

Freeze synchronized documentation, reviewed package contents, the source commit
and both CI handoff bundles. Follow the
[release runbook](operations/release_candidate_handoff.md): publish core `0.2.4`,
verify fresh registry CLI/core consumers, then publish UI `0.1.2` and validate
the pair outside all workspaces. Preserve actual-evidence gates
and candidate report restoration even though this scoped publication does not
wait for host acceptance. Record dates, source SHA and registry checks only
after they happen. Current availability belongs in [project status](project_status.md),
not in immutable package contents.

## Deferred

- ESM output; CommonJS remains the verified host boundary.
- Additional render targets.
- Backend-owned payment completion.
- Broad example expansion without independent verification value.
