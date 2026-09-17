# Project status

Minimoon core `0.2.1` was published to Mooncakes on **2026-09-15**. The independent
`lampclaw/minimoon_ui 0.1.0` remains the package published on **2026-09-09**.
See the [current checkpoint](#core-021-publication) and the
[0.2.0 publication history](#publication-checkpoint) for source commits and archives.
The 0.1 API consumer remains
a frozen historical record; current API gates compile the 0.2 consumer.
Public generated reports intentionally retain reproducible candidate state.

## Core 0.2.1 publication

Core `0.2.1` was published on **2026-09-15** from
[`bc098bec14be66bcb06c2090ae725c30d72538d3`](https://github.com/lucavance/minimoon/commit/bc098bec14be66bcb06c2090ae725c30d72538d3).
Both [primary and Node 24 CI jobs](https://github.com/lucavance/minimoon/actions/runs/34937245727)
passed for that commit before publication.
The [downloaded core archive](https://download.mooncakes.io/user/lampclaw/minimoon/0.2.1.zip)
is **308,075 bytes / 168 files** and matches the frozen archive byte-for-byte:
SHA-256 `b4de4a5db713ab8959c123b6a77d67ea9a722b57ea6d7a3cbbbe8274c6e37403`.
UI `0.1.0` was not republished; its 75 archived files remain unchanged and its
manifest still declares core `0.2.0`.

Fresh consumers outside all Moon workspaces resolved their dependencies from
the registry and passed:

- Registry CLI `0.2.1` and a new Starter: warning-free JS checks, both JS tests,
  build and candidate verification.
- A Starter created with registry CLI `0.2.0`, upgraded to registry CLI/core
  `0.2.1`: the same JS checks, two tests, build and candidate verification.
  Only the direct core dependency changed; business source, configuration,
  styles, JavaScript package manifest and lockfile stayed byte-identical.
- Core `0.2.1` with existing UI `0.1.0`: warning-free Native/JS root, headless
  and theme tests, native build-resource tests, build and candidate verification.

The Starter's application packages support JS only. The independent UI consumer
covers both Native and JS targets.

On `moon 0.1.20260904`, `moon publish --frozen` stopped before upload because
the freshly extracted self-check needed dependency installation. With the
reviewed dependency versions unchanged, ordinary `moon publish` completed the
full self-check and returned HTTP `200 OK`. The downloaded archive comparison
confirmed the published contents.

An initial auxiliary UI consumer passed functional tests, build and candidate
verification but reported a mismatch in its build-to-verification byte comparison.
The first build bytes were not retained, so the changed file and cause remain
unknown. Two fresh reproductions with the original configuration passed. The
final fresh consumer restricted Tailwind scanning with `source(none)` and an
explicit `src/` source, excluded outputs, and passed its first byte comparison.
That external fixture change does not establish the initial mismatch's cause;
no published package was changed in response.

## Unpublished repository changes

The repository contains four compatibility fixes for `moon 0.1.20260915` /
`moonc v0.10.13+cbb11c36f` that are absent from published core `0.2.1`:

- Remove unused `moonbitlang/core/json` imports from the documentation command,
  component behavior tests and build-tool package manifests.
- Generate the App-aware contract helper with explicit `@minimoon.App::preview`
  and `@minimoon.Page::contract` calls, retaining the root import required by the
  older compiler while making its use explicit for the newer compiler.

The new compiler reports those unused imports as warning `0029`; builds using
`--deny-warn` reject them. Registry CLI `0.2.1` can still build and verify the
ordinary Starter on this compiler. Apps with `application` configured need the
[current source CLI](guides/miniapp_quickstart.md#create-from-the-current-source)
for the helper fix. Its version output remains `0.2.1`, so the version number
alone does not identify the fixed source build.

Core `0.2.1`, UI `0.1.0`, the public API and Contract `11` / ABI `13` /
renderer protocol `8` remain unchanged. Both CI jobs now pin the new toolchain
listed below. Regenerated JavaScript can have different bytes and fingerprints;
the publication checkpoint above does not establish CI or real-host acceptance
for these repository changes. Changed fingerprints require fresh host validation.
The published archive and its recorded SHA-256 remain unchanged.

## Current implementation

For application authors, the README and [quickstart](guides/miniapp_quickstart.md)
start with `moon install lampclaw/minimoon/cmd/minimoon` and
`minimoon init my-app`. This installs the latest registry CLI and creates an
independent application; create it outside existing Moon workspaces. The
quickstart also covers source installation for framework development and
unpublished changes. The detailed [Roadmap](roadmap.md) separates implemented
capabilities from deferred directions.

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
Form's typed echo. Changes to either fixture fingerprint require new host
acceptance; public echo remains a testing service, not cloud persistence.
Core's product version is `0.2.1`; Contract `11`,
runtime ABI `13` and renderer protocol `8` do not change. The original `0.2.0`
publication checkpoint below remains an immutable historical release.

Core `0.2.1` includes the shared-host input fix: value edits
do not replay unchanged native focus/selection properties. The draft title input
has a taller layout intended to avoid clipping. Upgrade both the CLI and the
application's core dependency to `0.2.1`, then regenerate all artifacts; the
`0.2.0` CLI does not include this fix. Changed artifact fingerprints require
fresh real-host acceptance. Automated host-write checks do not establish native
cursor or IME correctness.

The builder also stages output before replacing the previous files.
Ordinary build failures retain the previous `dist/`, build metadata and configured
stylesheet while allowing current diagnostics to update. Private project settings
are preserved. A subsequent verification failure keeps the new output and failed
report for diagnosis; this does not promise crash or power-loss recovery.

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
prebuilt release `0.10.13+cbb11c36f` (`moon 0.1.20260915`), not latest, without
Rust. The supported minimum is unchanged; existing local `moon 0.1.20260907`
tools remain valid and do not require downgrading.
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
