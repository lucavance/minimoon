# Project status

Minimoon `0.1.0` is the first non-prerelease baseline. The current source and
generated reports define the product.

## Current implementation

Application code imports only `lampclaw/minimoon`. Elm-style state machines
compose pages and local components through `Val`; a page-owned transactional
incremental graph drives normalized MiniApp tree diffs and generated CommonJS
Skyline artifacts. App Contract v7, runtime ABI v10, and renderer protocol v7
remain independent technical compatibility numbers.

The maintained release surface consists of one two-page starter and one
four-page Conformance application covering authoring, native controls,
components, capabilities, navigation, lifecycle, incremental rendering,
ordered host scheduling, and disposal.

## Toolchain validation

The repository baseline was revalidated on 2026-09-04 with `moon 0.1.20260827`,
`moonc v0.10.11`, Node `26.8.1`, and Bun `1.4.0`. CI accepts no
older Moon or moonc version and installs the JavaScript dependency graph from
the committed lockfile.

## Evidence state

The public repository deliberately records only reproducible candidate state.
Its tracked status is owned by the Conformance fixture's
[`verify_report.json`](../examples/miniapp_conformance_app/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_conformance_app/generated/release_summary.json).
Fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_conformance_app/generated/devtools.evidence.json)
is local and Git-ignored. It may authorize a local release without publishing
the validation timestamp, tool version, notes, or outcome in source history.

## Verification policy

`bun run check:candidate` proves formatting, interfaces, native and JavaScript
behavior, coverage, generation stability, host simulation, performance, and
registry archive compatibility. `bun run check:all` followed by
`bun run check:mvp` is a local release decision requiring evidence recorded
from the exact release bytes in WeChat Developer Tools. Running
`check:candidate` afterward restores the tracked reports to candidate state.

Registry publication remains an explicit operator action. The 0.1 release
process does not create version tags or GitHub releases, and real-host evidence
remains local. See [Roadmap](roadmap.md),
[Architecture](architecture.md), and the
[release handoff](operations/release_candidate_handoff.md).
