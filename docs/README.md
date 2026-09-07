# Minimoon documentation

This directory contains the active maintainer documentation for Minimoon.
The canonical source is the current `lucavance/minimoon` repository.

## Sources of truth

| Fact | Canonical source |
| --- | --- |
| Core and UI versions | root `moon.mod` (mirrored in `internal_versions`) and independent `ui/moon.mod` |
| App Contract, runtime ABI, renderer protocol | `internal_versions` |
| JavaScript dependencies | root `package.json` |
| Generated artifact fingerprint and automated status | Each core/UI fixture's `generated/verify_report.json` |
| DevTools version, timestamp, and real-host result | Each fixture's separate local, Git-ignored `generated/devtools.evidence.json` |
| Product direction | [`roadmap.md`](https://github.com/lucavance/minimoon/blob/main/docs/roadmap.md) |

Handwritten documents explain behavior and workflow. They do not copy artifact
fingerprints, DevTools timestamps, or local validation outcomes.

The current engineering checkpoint, constraints, and next-phase priorities are
maintained in
[`project_status.md`](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).

## Product and architecture

- [`project_status.md`](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md) — current checkpoint and next-phase priorities
- [`positioning.md`](positioning.md) — product boundary and success criterion
- [`mvp.md`](mvp.md) — core 0.2 and UI 0.1 product capability baseline
- [`architecture.md`](architecture.md) — runtime ownership and transaction path
- [`roadmap.md`](https://github.com/lucavance/minimoon/blob/main/docs/roadmap.md) — active and deferred work

## Bilingual code analysis

Chinese and English paragraphs are interleaved in one document so architecture,
source excerpts, and diagrams stay reviewable as a single artifact. This
maintainer suite and its high-resolution assets are source-repository material;
they are intentionally excluded from the core registry archive, whose reviewed
hard ceiling is 280 KiB with an 8 KiB reserve. UI has a separate 250 KiB hard
ceiling and 16 KiB reserve.

- [`code-analysis/README.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/README.md) — current-source reading map and provenance
- [`code-analysis/01-SYSTEM-ARCHITECTURE.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/01-SYSTEM-ARCHITECTURE.md) — layers, ownership, and event path
- [`code-analysis/02-AUTHORING-MODEL.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/02-AUTHORING-MODEL.md) — Model/Msg, `Cmd`, `Val`, components, and subscriptions
- [`code-analysis/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md) — candidate state, rollback, scopes, and keyed caches
- [`code-analysis/04-RENDERER-AND-DIFF.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/04-RENDERER-AND-DIFF.md) — normalization, retained subtrees, diff, and revisions
- [`code-analysis/05-RUNTIME-AND-HOST-SCHEDULER.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/05-RUNTIME-AND-HOST-SCHEDULER.md) — runtime lifecycle, queues, acknowledgement, and protocol
- [`code-analysis/06-BUILD-VERIFY-AND-RELEASE.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/06-BUILD-VERIFY-AND-RELEASE.md) — contracts, generated artifacts, gates, and evidence
- [`code-analysis/07-SYMBOL-INDEX.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/07-SYMBOL-INDEX.md) — source-reading and symbol index
- [`code-analysis/08-RISKS-TESTING-AND-PERFORMANCE.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/08-RISKS-TESTING-AND-PERFORMANCE.md) — coverage, stress, budgets, and open risks
- [`code-analysis/assets/diagrams/README.md`](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/assets/diagrams/README.md) — 21 reproducible SVG, 3× PNG, and Mermaid sources

## Guides

- [`guides/shared_state.md`](guides/shared_state.md) — optional App ownership, typed projections and acceptance / 应用级共享状态
- [`guides/miniapp_quickstart.md`](guides/miniapp_quickstart.md)
- [`guides/miniapp_authoring_example.md`](guides/miniapp_authoring_example.md)
- [`guides/api_ergonomics.md`](guides/api_ergonomics.md)
- [`guides/resource_state_design.md`](guides/resource_state_design.md)
- [`guides/subscription_scope.md`](guides/subscription_scope.md)
- [`guides/testing_and_components.md`](guides/testing_and_components.md)
- [`guides/keyed_children_diff.md`](guides/keyed_children_diff.md)

## Reference

- [`reference/compile_model.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/compile_model.md)
- [`reference/miniapp_renderer.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/miniapp_renderer.md)
- [`reference/renderer_protocol.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/renderer_protocol.md)
- [`reference/miniapp_host_capabilities.md`](reference/miniapp_host_capabilities.md)
- [`reference/miniapp_fixture_matrix.md`](reference/miniapp_fixture_matrix.md)
- [`reference/moonbit_ownership.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/moonbit_ownership.md)
- [`reference/performance_baseline.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/performance_baseline.md)
- [`reference/compatibility_and_upgrades.md`](reference/compatibility_and_upgrades.md)
- [`reference/rabbita_and_rui_audit.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/rabbita_and_rui_audit.md) — historical pre-migration comparison of all 64 RUI entries
- [UI guide](https://github.com/lucavance/minimoon/blob/main/ui/README.mbt.md), [changelog](https://github.com/lucavance/minimoon/blob/main/ui/CHANGELOG.md), [migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md), and [six-page showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md)

## Operations

- [`operations/miniapp_devtools_validation.md`](operations/miniapp_devtools_validation.md)
- [`operations/miniapp_javascript_compatibility.md`](operations/miniapp_javascript_compatibility.md)
- [`operations/release_candidate_handoff.md`](operations/release_candidate_handoff.md)
- [`operations/dogfood.md`](operations/dogfood.md)

Durable third-party attribution remains in `THIRD_PARTY_NOTICES.md` and the
adapted source files.
