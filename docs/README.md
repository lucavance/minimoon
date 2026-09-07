# Minimoon documentation

This directory contains the active maintainer documentation for Minimoon.
The canonical source is the current `lucavance/minimoon` repository.

## Sources of truth

| Fact | Canonical source |
| --- | --- |
| Product version | root `moon.mod`, mirrored and checked in `internal_versions` |
| App Contract, runtime ABI, renderer protocol | `internal_versions` |
| JavaScript dependencies | root `package.json` |
| Generated artifact fingerprint and automated status | Conformance fixture `generated/verify_report.json` |
| DevTools version, timestamp, and real-host result | Local, Git-ignored Conformance fixture `generated/devtools.evidence.json` |
| Product direction | [`roadmap.md`](roadmap.md) |

Handwritten documents explain behavior and workflow. They do not copy artifact
fingerprints, DevTools timestamps, or local validation outcomes.

The current engineering checkpoint, constraints, and next-phase priorities are
maintained in
[`project_status.md`](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).

## Product and architecture

- [`project_status.md`](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md) — current checkpoint and next-phase priorities
- [`positioning.md`](positioning.md) — product boundary and success criterion
- [`mvp.md`](mvp.md) — 0.1.0 product capability baseline
- [`architecture.md`](architecture.md) — runtime ownership and transaction path
- [`roadmap.md`](roadmap.md) — active and deferred work

## Bilingual code analysis

Chinese and English paragraphs are interleaved in one document so architecture,
source excerpts, and diagrams stay reviewable as a single artifact. This
maintainer suite and its high-resolution assets are source-repository material;
they are intentionally excluded from the 250 KiB registry archive.

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

- [`guides/miniapp_quickstart.md`](guides/miniapp_quickstart.md)
- [`guides/miniapp_authoring_example.md`](guides/miniapp_authoring_example.md)
- [`guides/api_ergonomics.md`](guides/api_ergonomics.md)
- [`guides/resource_state_design.md`](guides/resource_state_design.md)
- [`guides/subscription_scope.md`](guides/subscription_scope.md)
- [`guides/testing_and_components.md`](guides/testing_and_components.md)
- [`guides/keyed_children_diff.md`](guides/keyed_children_diff.md)

## Reference

- [`reference/compile_model.md`](reference/compile_model.md)
- [`reference/miniapp_renderer.md`](reference/miniapp_renderer.md)
- [`reference/renderer_protocol.md`](reference/renderer_protocol.md)
- [`reference/miniapp_host_capabilities.md`](reference/miniapp_host_capabilities.md)
- [`reference/miniapp_fixture_matrix.md`](reference/miniapp_fixture_matrix.md)
- [`reference/moonbit_ownership.md`](reference/moonbit_ownership.md)
- [`reference/performance_baseline.md`](https://github.com/lucavance/minimoon/blob/main/docs/reference/performance_baseline.md)
- [`reference/compatibility_and_upgrades.md`](reference/compatibility_and_upgrades.md)
- [`reference/rabbita_and_rui_audit.md`](reference/rabbita_and_rui_audit.md) — pinned reference comparison, all 64 RUI entries, and next-iteration candidates

## Operations

- [`operations/miniapp_devtools_validation.md`](operations/miniapp_devtools_validation.md)
- [`operations/miniapp_javascript_compatibility.md`](operations/miniapp_javascript_compatibility.md)
- [`operations/release_candidate_handoff.md`](operations/release_candidate_handoff.md)
- [`operations/dogfood.md`](operations/dogfood.md)

Durable third-party attribution remains in `THIRD_PARTY_NOTICES.md` and the
adapted source files.
