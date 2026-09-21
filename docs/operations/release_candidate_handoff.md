# Release candidate handoff

This workflow keeps deterministic Linux validation, real Skyline acceptance
and explicit local registry publication distinct. The current source pair is
core `lampclaw/minimoon@0.2.3` and UI `lampclaw/minimoon_ui@0.1.1`;
UI declares core `0.2.2`. Actual published versions and historical checkpoints
are recorded in [project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).
Never overwrite an occupied registry version or treat an old host result as
acceptance of changed artifacts.

## Scoped publication exception

For the published core `0.2.2` / UI `0.1.1` pair and the requested core `0.2.3`
vp migration, the user explicitly authorizes this sequence:
complete local candidate checks, push the frozen candidate to `main`, wait for
both CI jobs on that exact commit, notify the user of their success, then
publish the authorized package versions without waiting for new WeChat host
validation. This iteration publishes core `0.2.3` only; UI remains the existing
`0.1.1`, including its core `0.2.2` declaration.
The notification does not require another approval before the already
authorized publication.

This exception changes the timing of this registry publication, not its
validation results. Tracked reports retain `status: "passed"`, `release: false`
and Developer Tools `pending`. No host evidence may be invented, copied from
another fingerprint or recorded without an actual pass. `verify --release`,
`check:all` and `check:mvp` keep their real-evidence requirements. Package
contents, consumers, source cleanliness and both CI jobs remain required.
The general host acceptance procedure below still applies before claiming
Skyline acceptance; future publications need their own authorization.

## Freeze documentation and produce candidates

Complete the core English/Chinese READMEs, changelog, compatibility guidance and
this runbook before freezing the release commit. Keep current availability in the
repository-only [project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md);
do not invent publication dates or real-host outcomes in package contents.

```bash
moon info
moon fmt --check
moon test --target native
moon test --target js
vp run --no-cache check:coverage
vp run --no-cache check:candidate
git diff --check
git status --short --branch
```

Review every generated interface and artifact change. On success,
`check:candidate` covers both fixtures and writes `status: "passed"`,
`release: false` and a
pending Developer Tools summary with no evidence reference. Candidate mode
ignores local evidence, so committed reports are reproducible. It does not
publish packages, create tags or manufacture host evidence.

For an external application, `minimoon verify <app> --candidate` is the
equivalent candidate verification command; it builds release bytes.
`--release` is the separate local evidence gate.

The archive gate checks the actual packaged files, documentation links, module
allowlists and native/JS consumers. It is not a registry-resolution test: local
workspace bindings cannot prove that a version is available in Mooncakes.
Record the reviewed archive content checksums before publication; ZIP timestamps
or compression metadata alone are not a source-content change.

As observed with `moon 0.1.20260907`, packaging a nested module can
inherit its ancestor repository's `.moonignore`. In this repository the root
`/ui/` exclusion can make a direct UI package/publish operation produce an
empty 22-byte ZIP. Do not run `moon publish` from the checkout's `ui/` directory
or use `moon -C ui publish`.

The UI archive gate instead copies source into a temporary independent Git
root, runs the real `moon package`, checks the archive allowlist and required
files, and compiles consumers from the extracted package. Its reviewed output
is `_build/publish/lampclaw-minimoon_ui-0.1.1.zip`. The core candidate archive is
`_build/publish/lampclaw-minimoon-0.2.3.zip`. UI publication must use that checked
archive extracted outside all Git and Moon workspace ancestors, after registry
core is available and consumers pass. A successful archive gate does not itself
publish either module. UI `0.1.1` is occupied; the current source archive is
only a source-validation fixture, not an archive to republish.

After review, commit and push the complete candidate to `main`, then require
both the primary `Test` job and `Node 24 LTS compatibility` job to pass for that
exact commit. Freeze the source SHA, toolchain versions, package contents and
both artifact fingerprints. A newer source commit requires its own CI result.
Notify the user with the successful CI link before following the ordered
publication procedure; the scoped exception permits continuing immediately.
Do not create version tags or a GitHub Release as part of this workflow.

## Repository validation reference

These are framework-maintainer gates, separate from a user's application build.
`check:docs` validates links, mirrored READMEs, current facts, onboarding examples
and generated reports; `check:api` locks the core 0.2 root/HTTP/resources surface and
compiles the current consumer. Optional core components/styles/testing and the
independent UI root/headless/theme/resources packages have additive snapshots.
The frozen 0.1 consumer is historical, not a source-compatibility promise.

`check:coverage` is independent of `check:candidate`. The latter also checks
warning-free compilation, generated stability, host simulation, performance and
package consumers. All these automated checks are distinct from `check:all` and
`check:mvp`, which additionally require the two fixtures' local host evidence.

Archive checks use `moon package --frozen --list` and inspect the actual ZIPs.
Core has a 328 KiB hard ceiling with an 8 KiB reserve; UI has a separate 250 KiB
ceiling with a 16 KiB reserve. These are repository budgets, not registry limits.
Only `scripts/bridge/weapp_tailwindcss_adapter.mjs` is maintained standalone
JavaScript; host code is MoonBit-owned and committed MiniApp JavaScript is generated.

## Validation temporary storage

`minimoon check` supervises a separate worker. Each invocation exclusively
creates a random `run-*` directory below `../.minimoon-check-tmp/`, relative to
the repository root. This keeps large unpacked packages and consumer builds
on the checkout's parent volume instead of a quota-limited system `/tmp`.
The base is deliberately outside the repository: nested consumers must not
inherit its `moon.work`. The default works without machine-specific paths in CI.

`MINIMOON_CHECK_TMPDIR` overrides the base with an absolute path or a path
relative to the repository. Choose an existing writable volume outside all
Moon workspaces. The supervisor creates missing base directories and logs the
exact run path. The inherited system `TMPDIR` does not override this default;
the worker and child tools receive the run path as `TMPDIR`, `TMP` and `TEMP`.
All repository-check fixtures use that owned run instead of async/fs's Linux
system-temp implementation. Standalone tooling unit tests still use their
small, individually cleaned system-temp fixtures.

The parent removes only its freshly created run after normal completion,
nonzero exit, worker crash or launch failure. API consumers also release their
directories immediately after success. Concurrent runs own separate paths;
cleanup does not follow fixture symlinks into shared dependencies. Existing
parent contents, older runs and legacy `/tmp/minimoon-*` files are never swept.
If the supervisor itself is forcibly killed or the machine stops, its run may
remain: confirm that no process uses the exact logged directory before manual
cleanup. This is not a general system-temp cleaner or a quota configuration.

Reports and performance samples remain in the repository's ignored `_build/`;
temporary-storage changes do not waive any gate or create real-host evidence.

## Independent CI bundles

| Artifact | Application | ZIP |
| --- | --- | --- |
| `minimoon-devtools-<commit>` | `examples/miniapp_draft_workbench` (nine routes / four native tabs) | `miniapp_draft_workbench-dist.zip` |
| `minimoon-ui-devtools-<commit>` | `ui/examples/showcase` (six pages) | `minimoon_ui_showcase-dist.zip` |

Each bundle contains its own:

- exact `dist/`, generated manifest, verify report, release summary and smoke
  checklist;
- `HANDOFF.json` with commit, application directory, artifact fingerprint,
  core/UI and Contract/ABI/protocol versions, toolchain (including global
  `vp` and its managed Bun backend) and required settings;
- `VALIDATION.md`, `SHA256SUMS`, the convenience ZIP and `ARCHIVE_SHA256`.

Run these commands in each downloaded bundle:

```bash
sha256sum --check --strict SHA256SUMS
sha256sum --check --strict ARCHIVE_SHA256
```

`SHA256SUMS` covers distributables, manifest, checklist, both reports and the
handoff/runbook files. `ARCHIVE_SHA256` covers the ZIP. Keep the bundle's
metadata beside its extracted `dist/`; the ZIP itself contains only `dist/`.

`HANDOFF.json` has `evidenceStatus: "pending-manual-devtools-validation"`.
The bundle contains no private project configuration or real-host evidence.
CI never reads, copies or uploads a Developer Tools evidence file.

The framework's v2 fingerprint is a separate raw-byte boundary: complete
distributables except `project.private.config.json`, plus the exact manifest
and smoke checklist. It includes WXSS, shared WXML, resources and ordered
application-specific `devtoolsChecks`.

## Real-host acceptance and local release gates

This procedure establishes actual host acceptance. The scoped exception above
permits the current registry publication to proceed while this remains pending;
skipping it never produces a release-verification pass.

1. Download both bundles from the frozen commit, verify hashes, versions and
   fingerprints, and import each unchanged `dist/`.
2. Complete every check in
   [Developer Tools validation](miniapp_devtools_validation.md) and each
   generated checklist in the Skyline simulator, physical-device preview and
   device debugging. Require a clean console.
3. Use the checkout for that commit and toolchain as the validation checkout.
   Its application artifacts must match the accepted bundle fingerprint before
   recording evidence; a local rebuild is acceptable only if those fingerprints
   remain identical. If they differ, test the new bytes before proceeding.
4. After each actual application pass, run `minimoon devtools record` for that
   application with the actual timestamp and tool version. Never copy or edit
   evidence JSON. Core evidence cannot authorize the UI fixture or vice versa.
5. In that checkout, run the two release verifications and aggregate gates:

```bash
minimoon verify examples/miniapp_draft_workbench --release
minimoon verify ui/examples/showcase --release
vp run --no-cache check:all
vp run --no-cache check:mvp
```

These commands rebuild. Require both local reports to pass release verification
and both fingerprints to remain the accepted ones. Changed generated bytes,
manifest or checklist require renewed host acceptance, even if public API
snapshots are unchanged.

After a real-host validation run, restore public reports before staging or
publication:

```bash
vp run --no-cache check:candidate
git diff --exit-code
git status --porcelain --untracked-files=all
```

The status output must be empty. Confirm the frozen HEAD, toolchain, module
contents and both fingerprints still match; the ignored evidence remains local
and must still match. The clean-worktree check alone does not prove that ignored
inputs or generated bytes match. Recheck candidate state before staging later
repository-only changes as well.

## Ordered local registry publication

Publication is an explicitly authorized local operator action, not a CI step.
Authenticate as the module owner; do not add registry credentials to CI.
Keep core `0.2.3` and the already published UI `0.1.1` fixed throughout these
checks. The user-approved exception above permits both host results to remain
pending. Do not publish or modify the occupied UI version.

1. Confirm core `0.2.3` is unoccupied immediately before publication. Recheck
   the frozen commit, successful CI jobs, reviewed core archive contents,
   toolchain versions and both fingerprints. Run `vp run --no-cache check:candidate`,
   then `git diff --exit-code` and `git status --porcelain --untracked-files=all`;
   require a clean worktree and unchanged package contents. A source change
   requires a new candidate and CI run. Notify the user when both jobs pass.
2. Publish core from the clean validation checkout:

```bash
moon publish --frozen
```

   This command has previously stopped before upload because its freshly
   extracted self-check needed dependency installation. If the current toolchain
   reports that exact failure, confirm no upload occurred and the reviewed
   source/package contents and dependency versions are unchanged. Ordinary
   `moon publish` from the same checkout may then complete the normal self-check.
   Never use this fallback for a source-check failure or dependency drift.
   If an upload result is ambiguous, query the registry before retrying.
3. Wait until Mooncakes resolves core `0.2.3`. In a fresh temporary directory
   outside this repository and every ancestor `moon.work`, install the registry
   CLI into a temporary binary directory:

```bash
moon install --bin <temporary-bin> lampclaw/minimoon/cmd/minimoon@0.2.3
<temporary-bin>/minimoon --version
<temporary-bin>/minimoon init <temporary-app>
```

   Do not pass `--minimoon-root`. Confirm the exact CLI version and absence of
   local overrides. Run `moon update`, inspect the resolved graph, execute
   `vp install`, and check/test the JS-only Starter. Build and run
   `verify --candidate`, exercise the README first edit, and validate an
   application-enabled consumer and an independent native/JS core consumer.
   Test with vp-managed tools and no independently installed Bun. Compare the
   downloaded core inventory and file hashes against the reviewed archive;
   ZIP metadata alone is not a source-content difference.
4. Upgrade a Starter created by registry CLI `0.2.2` to CLI/core `0.2.3`.
   Update its runtime declaration and commands as documented in the upgrade
   guide. Preserve application logic, configuration, styles and private settings.
   Check/test, build, verify and repeat the build to establish deterministic
   output. Old CLI archives remain unchanged.
5. Create a registry-only consumer declaring core `0.2.3` and UI `0.1.1`.
   Confirm those resolved versions and UI's unchanged core `0.2.2` declaration.
   Import root, headless and theme for native/JS behavior checks; exercise
   resources through the native build provider, not application JavaScript.
   Build and verify a candidate, reject unknown resources without corrupting
   prior artifacts, and test deterministic rebuilding. Compare downloaded core
   contents to the reviewed core ZIP and validate the existing published UI
   archive against its publication checkpoint. Do not compare immutable UI
   contents to the newly edited repository documentation or republish it.
6. Only after core and all fresh consumers pass, record the actual source SHA,
   publication date, CI result, registry links and package content checks in
   repository-only `docs/project_status.md`. Keep host acceptance pending and
   explicitly record that UI was not republished. Commit and push the status
   update and require its CI to pass. Do not modify already published contents.

If core publication succeeds but a consumer check fails, report that exact
partial state. Do not automatically yank core, overwrite its version, or
publish UI as a repair. Fixes to published contents require a new version and
validation cycle. Real-host timestamps, tool versions, notes and outcomes remain
local; no evidence file belongs in a commit or CI attachment.

## Source-only drift

MoonBit release minification can change when blocks move between source files.
Equal interfaces and passing tests establish source/API equivalence, not
identical generated bytes. Every changed artifact fingerprint requires its own
real-host acceptance; never restore old generated bytes merely to retain
evidence.
