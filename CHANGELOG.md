# Changelog

Changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The product version is defined by `moon.mod`; Minimoon versions do not use Git
tags.

## [0.2.2] - Unreleased

### Changed

- Require `moon 0.1.20260920` / `moonc v0.10.14` and pin both CI jobs to the
  official `0.10.14+7d59c7ec9` prebuilt release. Update `moonbitlang/async` to
  `0.22.1` and `moonbitlang/x` to `0.5.5`.
- Use explicit package qualifiers in blackbox tests and explicit public trait
  extensions to preserve existing derived methods under the new compiler.
  Retain the checked public API and Contract `11` / ABI `13` / protocol `8`.
- Advance the primary CI Node version to `26.9.0`, retaining the `>=24.20.0`
  support floor and lower-bound CI job. Bun remains `1.4.2`.
- Update weapp-tailwindcss to `5.5.7` in the repository and generated Starter,
  refreshing the lockfile while retaining Tailwind `4.3.3` and PostCSS `8.5.28`.
- Refresh the documentation diagram renderer to Mermaid CLI `11.17.0` and
  regenerate its checked visual artifacts.
- Pair core with UI `0.1.1`, whose declared core dependency is `0.2.2`.
  Pin README onboarding to CLI `0.2.2` and document migration of existing
  module dependencies, npm manifests and explicit MoonBit references.

### Fixed

- Keep build commit/rollback consistent when async operations are cancelled,
  preserve recovery backups if restoration fails, and finish temporary-file
  cleanup without cancellation interrupting it.
- Restore configuration and generated source files when `add page` or
  `add component` formatting fails or is cancelled, while preserving the
  original failure for diagnosis.
- Run the JavaScript-only stylesheet adapter with the supported Node runtime;
  weapp-tailwindcss now requires `node:module.findPackageJSON`, which is absent
  from the pinned Bun runtime. Bun remains the package manager and task runner.
- Include the App-aware helper's explicit `App::preview` / `Page::contract`
  calls and unused-import cleanups that were absent from the `0.2.1` archive.
  Upgrade the CLI as well as the application library to receive this fix.

### Validation and publication

- Regenerate both fixtures and review their complete artifacts and fingerprints
  with the new compiler and stylesheet dependencies.
- This core/UI pair has explicit authorization for registry publication after
  complete local candidate validation and both CI jobs pass for the frozen
  commit, without waiting for new WeChat host validation. Public reports remain
  `release: false` with Developer Tools `pending`; the actual release evidence
  gates are unchanged. Registry availability is recorded in project status.

## [0.2.1] - 2026-09-15

### Fixed

- Narrow generated input/textarea property writes so typing does not replay
  unchanged native focus or selection fields. Rebuild applications with the
  `0.2.1` CLI; upgrading only the MoonBit dependency does not update the host.
- Stage build output before replacement and restore the previous distributable,
  generated build metadata and configured stylesheet on ordinary build failure.
  Preserve private project configuration byte-for-byte. Failure diagnostics may
  update; a later verification failure keeps the newly built output for diagnosis.

### Changed

- Default English/Chinese onboarding to unversioned registry CLI installation
  and place the WeChat Developer Tools `dist/` import immediately after candidate
  verification. Document CLI upgrades and core-only patch publication.
- Keep the checked core 0.2 API, App Contract `11`, runtime ABI `13` and renderer
  protocol `8`. Optional UI remains the separately published `0.1.0`; this patch
  does not republish it. Both affected fixture fingerprints require host acceptance.

### Example maintenance

- Switch both maintained examples to public Apifox Echo, including draft and UI
  form POSTs, Platform scenarios and delayed lifecycle requests.
- Extend the opt-in public HTTP probe to the UI form (12 cases in total), retain
  strict request/echo checks across scalar and array-valued service formats, and
  test malformed echoes offline. Revalidate both changed fixture fingerprints.
- Rename the core example to Minimoon Draft Workbench (`miniapp_draft_workbench`),
  with four business Tabs, a Draft Editor and four capability laboratories.
- Add acknowledged local draft CRUD, restart restoration, an App-owned editing
  buffer, typed public echo, and explicit page/App request lifetime checks.
- Increase the draft title input's height and remove its vertical padding to
  avoid clipped text.
- Apply the reviewed example-only runtime/aggregate JavaScript ceilings of
  440,000/480,000 bytes; framework, Starter, UI and other performance gates stay unchanged.
- Keep the independently versioned UI package unchanged. Example updates remain
  repository fixtures; registry availability is recorded in project status.

## [0.2.0] - 2026-09-09

### Added

- Native bottom TabBar configuration and typed `switch_tab`, with tab-aware
  back fallback and capability checks. Conformance has four primary tabs and
  retains Request Lifecycle, Runtime Lab and Draft Editor as secondary acceptance routes.
- Read-only `PageContext.layout()` with synchronous first-business-tree host
  metrics, transactional resize/Show updates and test layout injection.
- Typed text/binary build resources, validated PNG Tab icons, and static
  navigation text color for custom Skyline headers.

- Real route input is decoded before page graph/model creation; preview input
  is separate and cannot start effects. Creation returns a typed result.
- App-aware `testing.launch`, page mounting with input and bounded `quiesce`.
- Optional `lampclaw/minimoon/http` request builders with typed JSON responses,
  transport/status errors and unchanged root raw-request escape hatch.

- Optional `App[Deps]` with independent typed domain state machines, `Shared[T]`,
  scoped page bindings/selectors, application lifecycle and owned async effects.
- Commit-only page outboxes, cross-page shared-state acceptance in Application/Draft Editor,
  pure contract previews and application-aware `minimoon add page`.

- Typed HTTP methods, ordered queries, headers, JSON/form/text request bodies
  and per-request timeouts; invalid arguments resolve locally as `InvalidPayload`.
- Ten public-API Platform scenarios and opt-in `bun run check:http-live`, with
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

- App Contract advances to 11, runtime ABI to 13, and renderer protocol is 8.
  Older source schemas are rejected. Pages boot empty and first Load renders the real tree.
  Rebuild all generated artifacts together and obtain new real-host evidence.
- Opted-in page factories take the application's `Deps`; `PageContext` is now
  opaque. See the [shared-state guide](docs/guides/shared_state.md).
- This release intentionally changed page/testing APIs. The current
  0.2 consumer and reviewed snapshots define the gate; 0.1 fixtures are historical.
- RUI remains a provenance reference, not a browser-runtime dependency.
  UI's MIT attribution is separate from core's existing Apache-2.0 notices.

### Changed

- Consolidate Conformance into 首页 / 交互 / 平台 / 应用 plus Request Lifecycle,
  Runtime Lab and Draft Editor. Platform owns HTTP/host capabilities, Interaction
  owns the core component catalogue, and Application is the only full shared controller.
  Migrate the old `capabilities`, `capability_probe`, `lab` and `details` routes
  without aliases; Starter's `home` and `details` remain unchanged.
- Give the core scrolling blue hero a shallow curved bottom edge while preserving
  fixed navigation geometry, safe-area handling and existing artifact budgets.
- Reorganize English/Chinese READMEs around source-based Starter onboarding,
  first-edit verification and concise project status; correct UI schema migration
  guidance and add documentation fact and onboarding regression checks.
- Validated MoonBit floor is 0.1.20260904 / moonc v0.10.12, calibrated against
  the official prebuilt release `0.10.12+1634b282e` pinned in both CI jobs.
  Migrated package exclusions to `.moonignore` and removed newly redundant test imports.

- Reviewed native navigation/layout growth budgets: no-App/App shared host
  ceilings are 18,000/19,000 bytes. The core archive hard ceiling is 320 KiB
  with an 8 KiB reserve. Conformance runtime/aggregate JavaScript retain the
  authoring review's 400,000/453,000-byte ceilings. An independent starter
  follow-up sets 230,000/258,000-byte runtime/aggregate ceilings after removing
  956 bytes of unnecessary layout-state overhead. UI archive and other gates
  remain unchanged.
- CI handoff technical versions are derived from the validated manifest and
  checked against both fixture summaries and checklists.
- Moved repository-check temporary consumers onto the checkout's parent volume,
  with configurable storage, isolated runs and supervisor-owned failure cleanup.
- The preceding HTTP budget review retained a 250 KiB core archive hard ceiling
  with an 8 KiB reserve and 360,000/424,000-byte runtime/aggregate ceilings;
  subsequent application-state, authoring and native navigation reviews supersede
  those core ceilings.
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
