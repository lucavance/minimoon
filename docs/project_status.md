# Project status

Core `0.2.4` and UI `0.1.2` were published to Mooncakes on **2026-09-23
(Asia/Shanghai)**. UI declares core `0.2.4`. Both packages and fresh registry
consumers passed the authorized automated publication checks. WeChat Developer
Tools acceptance remains pending on another machine; tracked reports retain
`release: false` and Developer Tools `pending`.

## Current development: vp 1.0.0-rc.0

The repository and CI adopt global `vp 1.0.0-rc.0` (prerelease), retaining
primary Node `26.10.0`, supported-floor Node `24.20.0`, managed Bun `1.4.2`
and the pinned MoonBit toolchain. The prior
[compatibility CI](https://github.com/lucavance/minimoon/actions/runs/35806762655)
passed both Node environments. Each adoption commit must pass the same two CI
jobs. This update changes current source guidance and diagnostics without
changing product versions or publishing new registry packages. The publication
records below describe the immutable published archives.

## Core 0.2.4 and UI 0.1.2 publication

The frozen source is
[`25281b3b901f3c424c6e2fdcc9af8954753860b4`](https://github.com/lucavance/minimoon/commit/25281b3b901f3c424c6e2fdcc9af8954753860b4).
Both the primary Node `26.10.0` and Node `24.20.0` compatibility jobs
[passed for that exact commit](https://github.com/lucavance/minimoon/actions/runs/35763266472)
before publication. Local native **486** and JavaScript **381** tests, coverage,
the complete candidate gate and its publication-time rerun passed. Source,
package contents and both fixture fingerprints remained unchanged, with a clean
worktree before upload. No version tag or GitHub Release was created.

This patch fixes keyed list insertions and moves, nested visibility propagation,
lifecycle decoder rollback and retry, App timer cleanup during verification,
custom configuration/output verification, and Slider pointer cancellation.
Public application APIs and Contract `11` / ABI `13` / renderer protocol `8`
remain unchanged. The dependency refresh is recorded below.

The actual downloaded archives match every reviewed file path, size, SHA-256
and content byte:

| Package | Download | Bytes / files | Download SHA-256 |
| --- | --- | --- | --- |
| Core `0.2.4` | [Mooncakes ZIP](https://download.mooncakes.io/user/lampclaw/minimoon/0.2.4.zip) | 326,680 / 184 | `477fc64f4bdb2f8e8b1e885cd22f97d693bd49bcce9e25782d3f4932cd672f15` |
| UI `0.1.2` | [Mooncakes ZIP](https://download.mooncakes.io/user/lampclaw/minimoon_ui/0.1.2.zip) | 119,438 / 78 | `dc54835f6cdd2bb0dc38a18ddffed10ceb31b923628916f3bb0db2a9715c0744` |

Core's ZIP is byte-identical to its frozen review archive. UI's reviewed ZIP
hash was `6c4f969a374a3783e4cbeecf04ca50c3a17f37aa0268822d3d14a255b4aab624`;
independent extraction and repackaging changed only ZIP container metadata.
All 78 extracted files remained byte-identical. UI was published outside all
Git and Moon workspace ancestors after **54** prepublication checks, with core
resolved from the registry. Both `--frozen` publication attempts stopped before
upload because extracted self-checks needed dependency installation. After
rechecking availability, dependency versions and reviewed contents, normal
`moon publish` completed its self-check and returned HTTP `200 OK` for each.
UI's archive self-check reports an unused test import because test files are
excluded; native/JS production checks with `--deny-warn` passed.

Independent registry consumers passed frozen API and explicit-method native/JS
checks and runtime interactions, a new Starter, the published README example
and first edit, and a real `0.2.3` Starter upgrade preserving ten original source,
style, configuration and private files. An App with foreground subscriptions
passed native/JS behavior checks and repeated build/verify using a configuration
filename and nested output directory containing spaces; fingerprints were stable.

The published core/UI pair then passed **95** consumer and upgrade checks:
registry-only dependency resolution, UI's exact core declaration, native/JS
root/headless/theme behavior, native resources, candidate verification,
deterministic rebuilding and unknown-resource failure atomicity. Upgrading a
separate `0.2.3` / `0.1.1` consumer preserved business source, styles, application
configuration, `package.json`, `bun.lock` and private project configuration.

The unchanged CI handoffs for real-host validation are:

- [Core workbench bundle](https://github.com/lucavance/minimoon/actions/runs/35763266472/artifacts/10711805773).
- [UI showcase bundle](https://github.com/lucavance/minimoon/actions/runs/35763266472/artifacts/10711249197).

Read each bundle's exact artifact fingerprint from its `HANDOFF.json` and
`verify_report.json`. Import its unchanged `dist/`, following `VALIDATION.md` and
[Developer Tools checklist](operations/miniapp_devtools_validation.md).
Automated publication does not establish a real-host pass; evidence remains
local and fingerprint-bound.

## Dependency review for 0.2.4 / 0.1.2

The 2026-09-23 review selected `weapp-tailwindcss 5.5.8`, primary Node
`26.10.0` and the SHA-pinned `setup-vp 1.21.1` action. The stylesheet update
includes the PostCSS parser-instance fix for theme colors and opacity utilities
in independent installations; the new Starter receives the same dependency
and runtime pins. See the upstream [weapp changelog](https://github.com/sonofmagic/weapp-tailwindcss/blob/main/packages/weapp-tailwindcss/CHANGELOG.md),
[PostCSS adapter changelog](https://github.com/sonofmagic/weapp-tailwindcss/blob/main/packages/postcss/CHANGELOG.md),
[Node 26 changelog](https://github.com/nodejs/node/blob/main/doc/changelogs/CHANGELOG_V26.md)
and [setup-vp release](https://github.com/voidzero-dev/setup-vp/releases/tag/v1.21.1).

The refreshed Mooncakes index confirms `moonbitlang/async 0.22.1` and
`moonbitlang/x 0.5.5` are already the latest non-yanked versions. The direct
JavaScript dependencies Tailwind/CLI `4.3.3`, PostCSS `8.5.28`, Acorn `8.18.0`
and `eslint-scope 9.1.2` are also current. MoonBit `0.10.14`, global `vp 0.3.3`
and managed Bun `1.4.2` remain pinned. CI retains Node `24.20.0` as the supported
lower-bound test; its purpose is compatibility coverage rather than selection
of the newest Node 24 release. Advisory scans of the original and refreshed
lockfiles and an independently installed new Starter returned no findings.
Frozen installation preserved the updated lockfile bytes. Historical API
consumers and publication records retain their original versions.

## Previously published pair

Minimoon core `0.2.3` was published to Mooncakes on **2026-09-21**.
For that core-only release, the independent UI remained `0.1.1` and was
**not republished**; its immutable manifest declares core `0.2.2`.
Applications selecting this patch declare core `0.2.3` directly.

See the [0.2.3 publication checkpoint](#core-023-publication),
[core 0.2.2 / UI 0.1.1 history](#core-022-and-ui-011-publication),
[core 0.2.1 history](#core-021-publication) and
[0.2.0 publication history](#publication-checkpoint) for completed releases.
The 0.1 API consumer remains a frozen historical record; current API gates
compile the 0.2 consumer. Public generated reports retain candidate state.

## Core 0.2.3 publication

Core was published from the frozen source commit
[`16e4879516be85c76c13943fc502171c6482758e`](https://github.com/lucavance/minimoon/commit/16e4879516be85c76c13943fc502171c6482758e).
The [primary and Node 24 CI jobs](https://github.com/lucavance/minimoon/actions/runs/35578967839)
both passed for that exact commit before publication. The complete local
candidate gate was rerun, confirming unchanged package contents, artifact
fingerprints and a clean worktree.

The [downloaded core archive](https://download.mooncakes.io/user/lampclaw/minimoon/0.2.3.zip)
is **323,732 bytes / 183 files** and is byte-identical to the frozen reviewed ZIP:
SHA-256 `68beff0823797e43daff972bc6af825f43af98ad5250f6d2d7fc948f5a6df607`.
Every file path and file-content hash matched. UI's original published archive
retained its recorded SHA-256
`cc8561bad224d315bad3d7236228b73f09719128bdb7f8d65547331091e0de46`;
its file contents also matched the original reviewed UI archive.

`moon publish --frozen` stopped before upload because its newly extracted
self-check needed dependency installation. After verifying the version was
still unoccupied and the source, dependency graph and archive contents were
unchanged, ordinary `moon publish` completed the full self-check and returned
HTTP `200 OK`. No check was skipped and no occupied version was overwritten.

This patch makes global `vp 0.3.3` the entry point for JavaScript package
management, repository tasks, internal tooling, CI and Starter guidance.
Bun `1.4.2` remains the managed backend and `bun.lock` stays authoritative.
`devEngines.runtime` selects Node `26.9.0`, retaining Node `>=24.20.0` support
and explicit lower-bound CI coverage. No separate Bun installation or local
`vite-plus`, Vite or Vitest dependency is needed. The patch also fixes child
process cleanup on cancellation and the Starter's next-step directory guidance.
Upgrade the CLI as well as the application dependency; the immutable `0.2.2`
CLI keeps its original direct Bun launches.

The checked application API and Contract `11` / runtime ABI `13` / renderer
protocol `8` are unchanged. All **110 tracked generated files** are byte-identical
to the pre-migration artifacts. Local native **464** and JavaScript **363** tests,
coverage, the complete candidate gate and all **21 documentation diagrams** passed.
The core archive budget review retains an 8 KiB reserve within a 328 KiB hard
ceiling; UI and generated-runtime budgets are unchanged.

Fresh registry consumers outside every framework workspace passed:

- All **48 steps** for exact CLI/core `0.2.3` installation, frozen native/JS API
  consumers, a new Starter, the README first edit, application-enabled helpers,
  and the existing UI `0.1.1` pair. UI checks covered native/JS root, theme and
  headless behavior, native resources, candidate verification, deterministic
  rebuilding and transactional rejection of an unknown resource feature.
  Dependency graphs confirmed registry sources without local core/UI overrides.
- A **14-step** upgrade of a Starter generated by the actual registry `0.2.2`
  CLI. Only the core dependency and Node runtime selection were updated; all
  six original business-source files, the stylesheet and application configuration
  stayed byte-identical. Existing private configuration survived both the first
  migration build and repeated build, with stable artifact fingerprints.
- A separate **7-step** cold environment probe used a new `VP_HOME`, a path
  containing spaces and a PATH without standalone Bun. It installed and ran
  Node `26.9.0` and Bun `1.4.2` through vp, including the production
  `VP_BUN_VERSION=1.4.2` / `vp env exec bun` path without inherited shim markers.

These are automated publication and consumer results. The user explicitly
authorized this core-only publication after local candidate checks and both CI
jobs passed, without waiting for new WeChat host validation. The
[scoped exception](operations/release_candidate_handoff.md#scoped-publication-exception)
does not establish a real-host pass or weaken the evidence gates. Developer
Tools status remains `pending`, and tracked reports retain `release: false`.
This repository-only record does not alter the frozen core archive or existing
UI package.

## Core 0.2.2 and UI 0.1.1 publication

Both modules were published on **2026-09-21** from the frozen source commit
[`66cfd048ac92dcefdf5f4d20d0e0c86cc3961d69`](https://github.com/lucavance/minimoon/commit/66cfd048ac92dcefdf5f4d20d0e0c86cc3961d69).
The [primary and Node 24 CI jobs](https://github.com/lucavance/minimoon/actions/runs/35569453785)
both passed for that exact commit before publication. Core was published first;
UI was published from its independently extracted reviewed archive after core
registry consumers and the extracted UI consumer passed.

| Module | Version | Downloaded archive | Files |
| --- | --- | --- | ---: |
| `lampclaw/minimoon` | `0.2.2` | [319,333 bytes](https://download.mooncakes.io/user/lampclaw/minimoon/0.2.2.zip) | 181 |
| `lampclaw/minimoon_ui` | `0.1.1` | [118,982 bytes](https://download.mooncakes.io/user/lampclaw/minimoon_ui/0.1.1.zip) | 78 |

The core registry ZIP is byte-identical to the frozen reviewed archive:
SHA-256 `61fc2fe0604ee6d8476c6a3d1ec9a2a15051fa750f36db3754e22fe07f210e95`.
The UI registry ZIP has SHA-256
`cc8561bad224d315bad3d7236228b73f09719128bdb7f8d65547331091e0de46`.
Its ZIP metadata differs from the reviewed ZIP, but every archived file path
and file-content SHA-256 matches. The UI manifest declares core `0.2.2`.
No source content changed during publication.

Fresh consumers outside the framework workspace completed these checks:

- Core registry validation passed all 33 steps: exact CLI installation,
  frozen API consumers on native and JS, a fresh Starter, the README's first
  edit, and an application-enabled consumer exercising the typed contract helper.
- An app generated by the actual registry `0.2.1` CLI passed a 17-step upgrade
  to CLI/core `0.2.2`. Only six original files needed dependency or compiler-syntax
  migration; application configuration, styles and business-logic tokens were
  unchanged. Repeated builds and candidate verification retained the same
  artifact fingerprint.
- Before UI publication, its extracted reviewed archive passed 14 steps with
  registry core and consumers. It did not resolve core from the framework checkout.
- After publication, the true registry `0.2.2` / `0.1.1` pair passed 17 steps:
  native/JS root, theme and headless behavior; native resource-provider checks;
  build and candidate verification; rejection of an unknown resource feature
  without changing the prior artifacts; and deterministic rebuilding after
  restoring the valid configuration. The downloaded module contents matched
  the reviewed archives without local core/UI overrides.

For each module, `moon publish --frozen` stopped before upload because its
freshly extracted self-check needed dependency installation. After confirming
the version was still unoccupied and source, dependency versions and reviewed
archive contents were unchanged, ordinary `moon publish` completed the full
self-check and returned HTTP `200 OK`. No source check was skipped. The registry
archive comparisons and subsequent consumers established the uploaded contents.

These are automated publication and consumer results. No new Skyline host pass
is claimed: public Developer Tools state remains `pending` and tracked
verification reports keep `release: false`.
This repository-only checkpoint does not alter either published package.

### Release compatibility and migration

These releases require `moon 0.1.20260920` / `moonc v0.10.14`; both source CI
jobs pin the official `0.10.14+7d59c7ec9` release. Dependencies are async
`0.22.1`, x `0.5.5` and weapp-tailwindcss `5.5.7`; the primary Node environment
is `26.9.0`. Node `>=24.20.0` support and Bun `1.4.2` remain unchanged.
Vite+ global CLI `0.3.3` is optional and is not a framework dependency.

Core `0.2.2` includes the earlier import cleanups and App-aware helper calls to
`@minimoon.App::preview` and `@minimoon.Page::contract`, plus explicit
cross-package qualifiers and public trait extensions for the new compiler.
Upgrade the CLI together with the core library to receive the generated-helper
fixes. The old `0.2.1` CLI can fail `--deny-warn` for App-aware builds on
`moonc v0.10.13`; its archive remains unchanged.

UI `0.1.1` declares core `0.2.2` and versions its native resource bundle at
`0.1.1`. The published UI `0.1.0` and its core `0.2.0` declaration remain
immutable. The checked public API and Contract `11` / ABI `13` / renderer
protocol `8` remain the compatibility boundaries. New generated bytes and
fingerprints require their own host validation before a host-acceptance claim.

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

## Current implementation

For application authors, the README and [quickstart](guides/miniapp_quickstart.md)
start with `moon install lampclaw/minimoon/cmd/minimoon@0.2.4` and
`minimoon init my-app` after confirming registry availability here. This selects
the documented CLI and creates an independent application; create it outside
existing Moon workspaces. The
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
counter and delayed-request regressions. `vp run check:http-live` is opt-in and
not real-host evidence. Both examples now default to public Apifox Echo; the live
probe covers Platform's ten cases, App draft echo after editor unload and the UI
Form's typed echo. Changes to either fixture fingerprint require new host
acceptance; public echo remains a testing service, not cloud persistence.
Core's source product version is `0.2.4`; Contract `11`,
runtime ABI `13` and renderer protocol `8` do not change. The original `0.2.0`
publication checkpoint below remains an immutable historical release.

Core `0.2.1` includes the shared-host input fix: value edits
do not replay unchanged native focus/selection properties. The draft title input
has a taller layout intended to avoid clipping. Upgrade both the CLI and the
application's core dependency to the current source `0.2.4` after registry availability
is recorded, then regenerate all artifacts; the
`0.2.0` CLI does not include this fix. Changed artifact fingerprints require
fresh real-host acceptance. Automated host-write checks do not establish native
cursor or IME correctness.

The builder also stages output before replacing the previous files.
Ordinary build failures retain the previous `dist/`, build metadata and configured
stylesheet while allowing current diagnostics to update. Cancellation keeps
commit/rollback consistent, and recovery backups remain available if restoration
fails. Temporary cleanup is protected from cancellation. `add page` and
`add component` restore configuration and generated source if formatting fails
or is cancelled, retaining the original error. Private project settings are
preserved. A subsequent verification failure keeps the new output and failed
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

The supported toolchain floor is `moon 0.1.20260920` with `moonc v0.10.14`;
global `vp 1.0.0-rc.0` (prerelease) manages Bun `1.4.2` and the Node runtime.
Both CI jobs use the official installer for prebuilt release `0.10.14+7d59c7ec9`
(`moon 0.1.20260920`), not latest, without Rust.
Older MoonBit installations must be upgraded for these releases.
JavaScript tooling supports Node `>=24.20.0`; CI validates the Node 24.20.0
lower boundary and Node 26.10.0 primary environment, installing the committed
JavaScript lockfile. The repository and Starters generated from current source
select Node `26.10.0` through `devEngines.runtime`; CI explicitly overrides the
lower-bound job.
Acceptance tasks use `vp run --no-cache`. Toolchain configuration is not itself
a passing CI result;
the release checkpoint must identify the successful run for the frozen SHA.

## RUI native migration

The approved full migration uses Rabbita 0.15.6 / RUI 0.1.1 at `b1291945`.
The [symbol-level migration map](../ui/docs/migration.md) covers all 517 upstream
public symbols, distinguishing native equivalents, consolidation and explicit
browser-host substitutions. Native/JS tests establish behavior; exact-artifact
Skyline validation remains separate and fingerprint-bound. The current package
pair has the scoped publication exception above; it does not establish host acceptance.

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

`vp run --no-cache check:coverage` and `vp run --no-cache check:candidate` together check coverage,
formatting, interfaces, native and JavaScript behavior, generation stability,
host simulation, performance and registry archive compatibility. Coverage is
an explicit separate gate, not a substep of `check:candidate`.
`vp run --no-cache check:all` followed by
`vp run --no-cache check:mvp` is a local release decision requiring evidence recorded
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
