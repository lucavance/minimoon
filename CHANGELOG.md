# Changelog

Changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The product version is defined by `moon.mod`; Minimoon versions do not use Git
tags.

## [0.2.0] - Unreleased

### Added

- Real route input is decoded before page graph/model creation; preview input
  is separate and cannot start effects. Creation returns a typed result.
- App-aware `testing.launch`, page mounting with input and bounded `quiesce`.
- Optional `lampclaw/minimoon/http` request builders with typed JSON responses,
  transport/status errors and unchanged root raw-request escape hatch.

- Optional `App[Deps]` with independent typed domain state machines, `Shared[T]`,
  scoped page bindings/selectors, application lifecycle and owned async effects.
- Commit-only page outboxes, cross-page shared-state acceptance in Home/Details,
  pure contract previews and application-aware `minimoon add page`.

- Typed HTTP methods, ordered queries, headers, JSON/form/text request bodies
  and per-request timeouts; invalid arguments resolve locally as `InvalidPayload`.
- Ten public-API Home scenarios and opt-in `bun run check:http-live`, with
  deterministic generated-page HTTP coverage in the offline host suite.
- Independent `lampclaw/minimoon_ui 0.1.0` module with Skyline-native RUI
  component adaptations, headless algorithms, typed themes and build resources.
- Typed native button content, form/label, image lifecycle, input options,
  slider/progress, touch events and revision-bound node measurement.
- Declarative page layers which preserve Val scope ownership while lifting
  host content outside scrolling containers.
- Six-page UI showcase and independent UI API, archive-consumer, resource,
  deterministic generation and candidate-verification gates.
- Separate core/UI CI handoff bundles, archive-documentation checks, and
  clean-worktree checks covering tracked and untracked files.
- Pinned Rabbita 0.15.6 / RUI 0.1.1 provenance and symbol-level native
  migration records. UI changes have their own
  [changelog](https://github.com/lucavance/minimoon/blob/main/ui/CHANGELOG.md).

### Compatibility

- App Contract advances to 10, runtime ABI to 12, and renderer protocol is 8.
  Schema 8/9 input is rejected. Pages boot empty and first Load renders the real tree.
  Rebuild all generated artifacts together and obtain new real-host evidence.
- Opted-in page factories take the application's `Deps`; `PageContext` is now
  opaque. See the [shared-state guide](docs/guides/shared_state.md).
- This unpublished candidate intentionally changes page/testing APIs. The current
  0.2 consumer and reviewed snapshots define the gate; 0.1 fixtures are historical.
- RUI remains a provenance reference, not a browser-runtime dependency.
  UI's MIT attribution is separate from core's existing Apache-2.0 notices.

### Changed

- Validated MoonBit floor is 0.1.20260904 / moonc v0.10.12, calibrated against
  the official prebuilt release `0.10.12+1634b282e` pinned in both CI jobs.
  Migrated package exclusions to `.moonignore` and removed newly redundant test imports.

- Reviewed authoring growth budgets: Conformance runtime/aggregate
  JavaScript ceilings are 400,000/453,000 bytes, with a 16,000-byte App-enabled
  host ceiling. The core archive hard ceiling is 300 KiB with an 8 KiB reserve.
  No-App host, starter, UI archive and other gates remain unchanged.
- CI handoff technical versions are derived from the validated manifest and
  checked against both fixture summaries and checklists.
- Moved repository-check temporary consumers onto the checkout's parent volume,
  with configurable storage, isolated runs and supervisor-owned failure cleanup.
- The preceding HTTP budget review retained a 250 KiB core archive hard ceiling
  with an 8 KiB reserve and 360,000/424,000-byte runtime/aggregate ceilings;
  subsequent application-state and authoring reviews supersede those core ceilings.
- Raised the repository and generated-starter Node floor to `>=24.20.0`, with
  CI coverage at 24.20.0 and 26.8.1; pinned Bun to `1.4.2`.
- Updated PostCSS to `8.5.28`, weapp-tailwindcss to `5.5.1`, and refreshed the
  transitive JavaScript dependency lockfile. Existing starter consumers should
  update their package manifests and lockfiles before rebuilding.
- Regenerated both fixtures with the versioned native host/resource changes.
  Changed fingerprints require separate WeChat Developer Tools validation;
  public repository reports remain candidate-only.

Publication availability is recorded separately in
[project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).

## [0.1.1] - 2026-09-04

### Changed

- Declared Node `>=24.11.0` support for repository and generated-starter
  JavaScript tooling, with CI coverage at Node 24.11.0 and 26.8.1. Generated
  starters use the compatibility range without a version-manager-specific pin;
  Bun remains pinned to `1.4.0`.

### Fixed

- Formatted the embedded starter sources for the current MoonBit toolchain so
  a fresh `minimoon init` passes `moon fmt --check` without local rewrites.
- Added generated-starter formatting to the generator gate so future formatter
  drift fails before publication.

## [0.1.0] - 2026-09-04

This is the first non-prerelease Minimoon release. Third-party source attribution
remains in `THIRD_PARTY_NOTICES.md` and the relevant source files.

### Added

- Elm-style `Model` / `Msg` authoring with `Cmd`, `Sub`, callable `Emit`,
  read-only `Val`, six `create_*` constructors, and `view2` through `view9`.
- A page-owned transactional incremental graph with keyed scopes, rollback,
  bounded caches, generational dispatch, subscriptions, and deterministic
  disposal.
- A normalized MiniApp renderer with retained subtrees, set/splice/move diff,
  acknowledged renders, snapshot recovery, and bounded event scheduling.
- Typed MiniApp controls, lifecycle, navigation, capabilities, semantic roles,
  testing helpers, and optional headless and styled components.
- App Contract v7, runtime ABI v10, renderer protocol v7, and generated
  CommonJS Skyline host artifacts.
- Native `minimoon` init/build/dev/add/verify/devtools/metrics workflows, a
  two-page starter, and one maintained four-page Conformance application.
- Deterministic native and JavaScript tests, coverage floors, generated-byte
  stability, API compatibility, archive-consumer, performance, and release
  gates.

### Toolchain

- Revalidated on 2026-09-04 with Moon `0.1.20260827`, moonc `0.10.11`, Node
  `26.8.1`, and Bun `1.4.0`.
- Retained the locked MoonBit and JavaScript dependency graph. Exact dependency
  versions remain authoritative in `moon.mod`, `package.json`, and `bun.lock`.

### Compatibility

- Applications import only `lampclaw/minimoon`; internal packages are not part
  of the public API.
- CommonJS remains the verified WeChat MiniApp boundary.
- A release claim requires fresh fingerprint-bound WeChat Developer Tools
  evidence for the exact generated bytes.
