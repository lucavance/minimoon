# Project status

Minimoon core `0.2.0` and the independent `lampclaw/minimoon_ui 0.1.0` are
the current unpublished candidates. The 0.1 API consumer remains a frozen
historical record; current API gates compile the 0.2 consumer. Source and
generated reports define candidate readiness.

## Current implementation

Conformance now has four native primary tabs (首页 / 交互 / 能力 / 应用) and
three secondary acceptance routes. Native tab commands, read-only page layout
and PNG build assets support the deep-blue custom header without handwritten
host JavaScript or a new UI dependency. These changes require fresh real-host
acceptance; automated candidates do not establish visual or device correctness.

The HTTP work adds methods, query/header/body encoding and timeouts. Home has ten public-API scenarios;
`bun run check:http-live` is opt-in and is not real-host evidence. Both fixtures
need matching Skyline revalidation after shared host bytes change.

The shared-state source iteration adds optional `App[Deps]`, typed domain
machines, page-local `Shared[T]` projections, and independent application
effects/lifecycle. Home and Details demonstrate shared count, request ownership
and epoch-based response invalidation. The UI showcase and starter retain the
no-application entry path. Contract `11` and runtime ABI `13` replace the earlier
technical boundaries; renderer protocol `8` and product versions are unchanged.
This source iteration is not a publication claim. See
[shared-state guide](guides/shared_state.md) for acceptance requirements.

The current authoring revision makes ordinary `page` builders, typed state
constructors and `Val` composition the primary style, retaining `elmish_page`
for simple pages. Required route inputs are decoded before graph creation;
explicit previews run no commands, and initial commands wait for Ready/mount.
An App-aware testing harness drives shared ready work with bounded quiescence.
These API and host changes still require fresh exact-fingerprint host acceptance.

Application code imports `lampclaw/minimoon`, plus `lampclaw/minimoon_ui`
when opting into native UI components. Elm-style state machines
compose pages and local components through `Val`; a page-owned transactional
incremental graph drives normalized MiniApp tree diffs and generated CommonJS
Skyline artifacts. App Contract v11, runtime ABI v13, and renderer protocol v8
remain independent technical compatibility numbers.

The maintained release surface consists of one two-page starter and one
seven-route Conformance application covering authoring, native controls,
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
Skyline validation remains a separate, pending release prerequisite.

## Evidence state

The public repository deliberately records only reproducible candidate state.
Core tracked status is owned by the Conformance fixture's
[`verify_report.json`](../examples/miniapp_conformance_app/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_conformance_app/generated/release_summary.json).
Fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_conformance_app/generated/devtools.evidence.json)
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

The intended order is core `0.2.0`, a fresh registry-only core consumer, UI
`0.1.0`, then a fresh consumer of both registry modules. Neither publication is
claimed here until the two-fixture host prerequisite and local release gates
are complete. After publication, record only the actual publication date,
source commit and registry links here; keep real-host records local and do not
rewrite the contents of an already published module version.
