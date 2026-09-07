# Roadmap

## HTTP and application state

The current HTTP iteration adds typed methods, query/header/body encoding,
timeouts, deterministic host tests and public-API Home acceptance scenarios.
It introduces no UI components or privately deployed acceptance server.
After HTTP acceptance, design application-level, typed shared state with an
explicit lifecycle from real application needs; do not expose an unowned global
mutable signal as a shortcut.

## 0.1.0 first non-prerelease release

The original `0.1.0` public baseline established:

- Elm-style state machines, callable `Emit`, transactional `Val` composition,
  and page-owned effects and subscriptions;
- contract and renderer version `7`, runtime ABI v10, CommonJS output, and
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
build-resource packages. Core 0.2 provides missing native controls and measurement;
Contract 8 / renderer 8 advance together while ABI 10 and CommonJS remain.
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
