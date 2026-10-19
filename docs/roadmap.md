# Roadmap

## Near-term priorities

### Current iteration: maintenance and performance observations (Unreleased)

The source CLI now follows the selected configuration, custom Tailwind input and
app-local CSS/WXSS, refreshes validated output exclusions after configuration
changes, and retains edits arriving during builds. A real subprocess regression
checks recovery and prevents generated-output rebuild loops. These fixes are
source-only; the immutable registry CLI `0.3.0` does not include them.

`check:perf` adds actual Page/Val updates, App message bursts, and deterministic
core/basic-UI/Markdown consumer size comparisons. CI retains the reports for
review. New measurements are observations with no added timing or UI runtime
ceiling; all existing budgets remain enforced. See the
[measurement guide](reference/performance_baseline.md#maintenance-observation-reports).
Use repeated results to prioritize queue or serialization work in the next
iteration; make a runtime change only with a reproduced bottleneck and a
separate compatibility and host-validation review.

### Completed baseline

Keep registry-based Starter onboarding and English/Chinese documentation
consistent. Once availability is recorded in project status, application
authors use `moon install lampclaw/minimoon/cmd/minimoon@0.3.0` and
`minimoon init my-app`. Source installation remains available for framework
development and unpublished candidates. The current source and published pair
is core `0.3.0` / UI `0.2.0`, with UI declaring core `0.3.0`.

Implemented capabilities are described below. CI, registry availability and
real-host acceptance remain distinct results. Deferred directions are not
dated feature commitments.

## RUI 0.3.6 follow-up: core 0.3.0 / UI 0.2.0 released

The five planned follow-ups now have source implementations: the full pinned
root/Markdown inventory and offline gate, dedicated property-reset host probes,
native Nova/Vega presets, optional CommonMark rendering, and open-Drawer exterior
edge gestures. Markdown uses the new typed native inline flow in core, so
renderer protocol advances to 9 while Contract 11 and ABI 13 remain.

Existing 0.2 core consumers and the historical 517-symbol RUI map are retained.
Nova is a native adaptation: browser-only DOM, selectors, popover IDs and
hover/keyboard mechanics stay outside the runtime. Markdown does not include
math/Mermaid engines or clipboard controls. Edge gestures are off by default
and do not open a closed Drawer.

The authorized publication completed on 2026-10-16 from frozen commit
`7d54538` after local candidate/release gates, both main CI jobs, matching
local host evidence, archive review and fresh registry consumer checks.
See [project status](project_status.md) for registry links and content hashes.
Future optional transition APIs remain a separate product decision.

<!-- minimoon:historical:start -->
## Published release: core 0.2.7 / UI 0.1.5

Raise the MoonBit floor to `moon 0.1.20261012` / `moonc 0.10.15` and pin both
CI jobs to official prebuilt release `0.10.15+943464bfa`. Migrate deprecated
built-in JSON conversion and iterator counting and format source and generated
templates with the same toolchain. Preserve the checked public API boundaries
and Contract 11 / ABI 13 / protocol 8.

Refresh managed Bun to `1.4.3`, PostCSS and its override to `8.5.30`,
weapp-tailwindcss to `5.6.1` and SHA-pinned setup-vp to `1.21.2`. Keep global
vp `1.1.0`, primary Node `26.11.1`, the Node `24.20.0` lower-bound check,
async `0.22.4`, x `0.5.5`, Tailwind/CLI `4.3.3`, Acorn `8.19.0`, eslint-scope
`9.1.2` and source-map-js override `1.2.2`. Use weapp's default JavaScript kernel.

The separately authorized publication completed on 2026-10-15 from frozen
commit `a74eb76`, after local candidate and release gates, archive review,
both CI jobs and fingerprint-matched local evidence. Core was published first;
fresh registry consumers passed before UI publication, and the final pair
passed new and upgraded consumer checks. Registry CLI `0.2.7` now delivers the
refreshed Starter. See [project status](project_status.md) for archive hashes
and availability. Retain only the exact
braces `3.0.3` advisory exception until `2026-11-23T00:00:00Z`; keep complete
scanning, strict matching and expiry enforcement. Changed fixture fingerprints
require renewed real-host validation before a host pass or future release.

## Rabbita/RUI maintenance follow-up (implemented)

The [2026-10-14 source review](reference/rabbita_and_rui_audit.md#2026-10-14-follow-up)
covers upstream `0a5836a3..7d5940f`. The completed follow-up preserves page-owned
transactions, the public API and the existing fixture artifacts. Normalization,
public control and executed-host tests now cover property removal,
empty/false/zero values, re-enabling controls and keyed updates, alongside the
existing lifecycle checks. No production repair was needed. The 517-symbol UI
map remains pinned to RUI 0.1.1, not the reviewed RUI 0.3.6 source.

The [host handoff](operations/miniapp_devtools_validation.md#property-reset-follow-up)
distinguishes existing manual interactions from additional automated coverage.
Only a reproduced implementation defect justifies changed generated bytes;
such a repair requires validation of the new affected fingerprints.


<!-- minimoon:historical:end -->
## Package size governance (implemented)

Repository release and dogfood runbooks stay outside the core archive; retain
the required application guides and installed CLI consumer checks. The
generator gate now emits deterministic core/UI archive reports with per-package
payload sizes, ZIP metadata overhead, largest files, SHA-256 and budget
headroom. It enforces exact agreement between actual ZIP members and the package
listing while preserving the reviewed hard ceilings and reserves. The primary
CI job retains available reports even when an archive exceeds its budget. See the
[release runbook](operations/release_candidate_handoff.md) for report semantics.

Delivery passed CI for the final integrated commit; local
candidate checks, prior-commit CI and host evidence remain distinct inputs.
Fingerprint-matching host evidence remains developer-local. Further native
interaction fixtures and a complete newer-RUI API map are optional follow-ups,
not unfinished work in this maintenance scope. New host interactions require
updated checklists and renewed validation of every changed fingerprint.

<!-- minimoon:historical:start -->
## Core 0.2.6 / UI 0.1.4 tooling refresh (completed)

Refresh Acorn to `8.19.0`, PostCSS and its override to `8.5.29`,
weapp-tailwindcss to `5.5.12`, primary Node to `26.11.1`, global `vp` to
`1.1.0` and SHA-pinned `actions/upload-artifact` to `7.0.2`. Synchronize the
repository, source-generated Starter, CI and environment guidance. Retain
MoonBit `0.10.14`, async `0.22.4`, x `0.5.5`, Tailwind/CLI `4.3.3`, managed
Bun `1.4.2`, Node `>=24.20.0` support and the public MoonBit API boundaries.

That released pair is core `0.2.6` / UI `0.1.4`; UI declares core `0.2.6`.
Previous registry CLI `0.2.5` retains its original pins. Their immutable
archives remain historical; current availability is recorded above. Run complete
candidate checks and independent Starter installation/build checks. Changed
fixture fingerprints need renewed real-host validation before claiming a pass.
The historical authorization allowed push after those local checks and publication after both
CI jobs for the frozen commit and exact-fingerprint host validation pass. Publish core
first, verify fresh registry consumers, then publish the reviewed UI archive.
No tags or GitHub Release are included.

## Core 0.2.5 / UI 0.1.3 stable Vite+ refresh (completed)

Use global `vp 1.0.0` for repository tasks, package installation, internal
tool launches and CI. Refresh `moonbitlang/async` to `0.22.4` and
`weapp-tailwindcss` to `5.5.11` in the repository and generated Starter.
MoonBit remains pinned to the current `0.10.14` release; `moonbitlang/x 0.5.5`,
Node `26.10.0` / `>=24.20.0`, and managed Bun `1.4.2` remain unchanged. The
release pair was core `0.2.5` / UI `0.1.3`; previously published
archives remain immutable. The public MoonBit APIs are unchanged.

## Core 0.2.4 / UI 0.1.2 corrections (completed)

- Fix keyed batch growth and nested branch visibility during cache restoration
  and rollback, preserving the existing public API and diff budgets.
- Surface lifecycle decoder failures without committing candidate state or
  effects; failed Load decoding remains retryable.
- Dispose App resources after verification, bound child execution and honor
  custom configuration/output paths throughout verification and evidence.
- Preserve Slider gestures when unrelated pointers are canceled.
- Publish core first, then the independently reviewed UI archive; validate new
  registry consumers and upgrades from core `0.2.3` / UI `0.1.1`.

The historical authorization allowed both patch publications after complete local candidate checks
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

<!-- minimoon:historical:end -->
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
acceptance. Historical publication exceptions do not establish that result.
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
`11`, runtime ABI `13`, and renderer protocol `9`; source schemas from previous
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
The current App Contract v11, runtime ABI v13 and renderer protocol v9 include
application ownership while preserving the CommonJS host boundary.
Old components and minimal themes remain compatible; the starter does not gain
an implicit UI dependency.

The [UI migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md)
distinguishes actual implemented capabilities, native substitutions and outstanding
work. API names or 64 showcase headings alone are not evidence of full parity.
Both applications require exact-fingerprint Skyline validation for a host
acceptance claim; publication requires matching evidence for both fixtures.

The UI fixture's
[`verify_report.json`](../ui/examples/showcase/generated/verify_report.json)
and [`release_summary.json`](../ui/examples/showcase/generated/release_summary.json)
are independent public candidate records. Its
[`devtools.evidence.json`](../ui/examples/showcase/generated/devtools.evidence.json)
is local and Git-ignored, just like the core fixture's evidence above.

## Release process

Freeze synchronized documentation, reviewed package contents, the source commit
and both CI handoff bundles before any separately authorized release. Follow
the [release runbook](operations/release_candidate_handoff.md), validating core
registry consumers before publishing its matching UI archive. The current core
`0.3.0` / UI `0.2.0` publication completed on 2026-10-16; occupied versions and
archives are immutable. The maintenance iteration above is unpublished.
Future publications need separate authorization, both CI jobs for the
final frozen commit and fingerprint-matched host validation. Preserve
actual-evidence gates and candidate report restoration. Record dates, source
SHA and registry checks only after they happen. Current availability belongs
in [project status](project_status.md), not in immutable package contents.

## Deferred

- Optional transition APIs, Markdown math/Mermaid engines and clipboard
  controls, and gestures that open a closed Drawer require separate product
  requirements and native host validation.
- ESM output; CommonJS remains the verified host boundary.
- Additional render targets.
- Backend-owned payment completion.
- Broad example expansion without independent verification value.
