# Project status

Minimoon core `0.2.0` and the independent `lampclaw/minimoon_ui 0.1.0` were
published to Mooncakes on **2026-09-09**. See the [publication checkpoint](#publication-checkpoint)
for the exact source commit and registry archives. The 0.1 API consumer remains
a frozen historical record; current API gates compile the 0.2 consumer.
Public generated reports intentionally retain reproducible candidate state.

## Current implementation

For application authors, the README and quickstart retain source-based Starter
creation; their separate registry installation path is now available for these
published versions. Near-term work focuses on onboarding consistency; the detailed
[Roadmap](roadmap.md) separates implemented capabilities from deferred directions.

The maintained core example is now **Minimoon Draft Workbench**:
`examples/miniapp_draft_workbench`, module `lampclaw/miniapp_draft_workbench`.
The former engineering name `miniapp_conformance_app` is historical; it is not
a second fixture. Four business Tabs (工作台 / 草稿 / 联机 / 更多), a Draft Editor
and four capability laboratories provide nine routes.

The example adds manual local CRUD, restart restoration, typed public HTTP echo
and an App-owned unsaved buffer. App sends survive editor unload; page trials
cancel on unload. Storage failure never confirms a save. Echo never writes back
to persisted records. There is no backend, account or cloud synchronization.

Platform retains ten public HTTP cases; the lifecycle laboratory retains shared
counter and delayed-request regressions. `bun run check:http-live` is opt-in and
not real-host evidence. Both examples now default to public Apifox Echo; the live
probe covers Platform's ten cases, App draft echo after editor unload and the UI
Form's typed echo. The service switch changes both fingerprints and requires new
host acceptance; public echo remains a testing service, not cloud persistence.
Product versions, Contract `11`, runtime ABI `13` and
renderer protocol `8` do not change. New workbench bytes need fresh host acceptance;
the publication checkpoint below remains the earlier immutable release.

The workspace also contains an unpublished shared-host input fix: value edits
do not replay unchanged native focus/selection properties. The draft title input
has a taller layout intended to avoid clipping. Use the repository CLI or its generated artifacts;
the published Registry CLI does not include this fix. Both core and UI artifact
fingerprints change and need fresh real-host acceptance. Automated host-write
checks do not establish native cursor or IME correctness.

The current authoring revision makes ordinary `page` builders, typed state
constructors and `Val` composition the primary style, retaining `elmish_page`
for simple pages. Required route inputs are decoded before graph creation;
explicit previews run no commands, and initial commands wait for Ready/mount.
An App-aware testing harness drives shared ready work with bounded quiescence.
Further API and host changes require fresh exact-fingerprint host acceptance.

Application code imports `lampclaw/minimoon`, plus `lampclaw/minimoon_ui`
when opting into native UI components. Elm-style state machines
compose pages and local components through `Val`; a page-owned transactional
incremental graph drives normalized MiniApp tree diffs and generated CommonJS
Skyline artifacts. App Contract v11, runtime ABI v13, and renderer protocol v8
remain independent technical compatibility numbers.

The maintained release surface consists of one two-page starter and one
nine-route Draft Workbench application covering authoring, native controls,
components, capabilities, navigation, lifecycle, incremental rendering,
ordered host scheduling, and disposal.

The independent UI module has a six-page showcase covering all 64 pinned RUI
families, Form and Theme. Its native resource provider, API snapshots, archive
consumer and generated-host checks are separate from core's starter contract.

## Toolchain validation

The supported toolchain floor is `moon 0.1.20260904` with `moonc v0.10.12`;
Bun is pinned to `1.4.2`. Both CI jobs directly use the official installer for
prebuilt release `0.10.12+1634b282e`, not latest, without Rust. Existing local
`moon 0.1.20260907` tools remain valid and do not require downgrading.
JavaScript tooling supports Node
`>=24.20.0`; CI validates the Node 24.20.0 lower boundary and the Node 26.8.1
primary environment, and installs the JavaScript dependency graph from the
committed lockfile.

## RUI native migration

The approved full migration uses Rabbita 0.15.6 / RUI 0.1.1 at `b1291945`.
The [symbol-level migration map](../ui/docs/migration.md) covers all 517 upstream
public symbols, distinguishing native equivalents, consolidation and explicit
browser-host substitutions. Native/JS tests establish behavior; exact-artifact
Skyline validation remains a separate, fingerprint-bound release prerequisite.

## Evidence state

The public repository deliberately records only reproducible candidate state.
Core tracked status is owned by the Draft Workbench fixture's
[`verify_report.json`](../examples/miniapp_draft_workbench/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_draft_workbench/generated/release_summary.json).
Fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_draft_workbench/generated/devtools.evidence.json)
is local and Git-ignored. UI status is independently owned by its
[`verify_report.json`](../ui/examples/showcase/generated/verify_report.json),
[`release_summary.json`](../ui/examples/showcase/generated/release_summary.json)
and local and Git-ignored
[`devtools.evidence.json`](../ui/examples/showcase/generated/devtools.evidence.json).
Matching evidence may authorize a local release without publishing
the validation timestamp, tool version, notes, or outcome in source history.

## Verification policy

`bun run check:coverage` and `bun run check:candidate` together check coverage,
formatting, interfaces, native and JavaScript behavior, generation stability,
host simulation, performance and registry archive compatibility. Coverage is
an explicit separate gate, not a substep of `check:candidate`.
`bun run check:all` followed by
`bun run check:mvp` is a local release decision requiring evidence recorded
from the exact release bytes in WeChat Developer Tools. Running
`check:candidate` before publication restores the tracked reports to candidate
state; require unchanged source, archive contents and both artifact fingerprints.

Registry publication remains an explicit operator action. The release
process does not create version tags or GitHub releases, and real-host evidence
remains local. See [Roadmap](https://github.com/lucavance/minimoon/blob/main/docs/roadmap.md),
[Architecture](architecture.md), and the
[release handoff](operations/release_candidate_handoff.md).

## Publication checkpoint

Both modules were published on **2026-09-09** from
[`65d0eab50ff6be26d51cd5af3f93757cc906f883`](https://github.com/lucavance/minimoon/commit/65d0eab50ff6be26d51cd5af3f93757cc906f883).
The source commit's [primary and Node 24 CI jobs](https://github.com/lucavance/minimoon/actions/runs/34337794114)
both passed before publication.

| Module | Version | Registry archive |
| --- | --- | --- |
| `lampclaw/minimoon` | `0.2.0` | [Download core](https://download.mooncakes.io/user/lampclaw/minimoon/0.2.0.zip) |
| `lampclaw/minimoon_ui` | `0.1.0` | [Download UI](https://download.mooncakes.io/user/lampclaw/minimoon_ui/0.1.0.zip) |

Core was published first, followed by a fresh registry CLI/Starter and a
Native/JS core counter consumer. UI was then published from its independently
extracted, checked archive. A fresh consumer of both registry modules passed
Native/JS behavior checks, native resource generation, build and candidate
verification without local workspace overrides. The downloaded archives and
all 166 core / 75 UI files matched the reviewed package contents.

Publication used `moon publish` with the reviewed dependency versions unchanged.
On local `moon 0.1.20260907`, `moon publish --frozen` stopped before upload because
its newly extracted self-check directory needed dependency installation.
The ordinary command completed that self-check; it did not upgrade dependencies
or bypass archive validation. The UI archive self-check reported an unused
test-only import because repository tests are excluded from packages; the actual
registry consumers passed with `--deny-warn`.

This repository-only status update does not alter the frozen published package
contents. Real-host records remain local and Git-ignored; do not rewrite or
republish an occupied module version.
