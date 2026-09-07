# Release candidate handoff

This workflow separates deterministic Linux validation, real Skyline acceptance
and explicit local registry publication. The current compatibility target is
core `lampclaw/minimoon@0.2.0` and UI `lampclaw/minimoon_ui@0.1.0`; the version
pair alone does not imply registry availability or a real-host pass.

## Freeze documentation and produce candidates

Complete both READMEs, changelogs, compatibility/migration guidance and this
runbook before freezing the release commit. Keep current availability in the
repository-only [project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md);
do not invent publication dates or real-host outcomes in package contents.

```bash
moon info
moon fmt --check
moon test --target native
moon test --target js
bun run check:coverage
bun run check:candidate
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

After review, commit and push the complete candidate, then require both the
primary CI job and Node 24 lower-bound job to pass for that exact commit. Freeze
the source SHA, toolchain versions, package contents and both artifact
fingerprints. A newer commit is a new candidate, not an implicit continuation
of the same acceptance.

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
| `minimoon-devtools-<commit>` | `examples/miniapp_conformance_app` (four pages) | `miniapp_conformance_app-dist.zip` |
| `minimoon-ui-devtools-<commit>` | `ui/examples/showcase` (six pages) | `minimoon_ui_showcase-dist.zip` |

Each bundle contains its own:

- exact `dist/`, generated manifest, verify report, release summary and smoke
  checklist;
- `HANDOFF.json` with commit, application directory, artifact fingerprint,
  core/UI and Contract/ABI/protocol versions, toolchain and required settings;
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
minimoon verify examples/miniapp_conformance_app --release
minimoon verify ui/examples/showcase --release
bun run check:all
bun run check:mvp
```

These commands rebuild. Require both local reports to pass release verification
and both fingerprints to remain the accepted ones. Changed generated bytes,
manifest or checklist require renewed host acceptance, even if public API
snapshots are unchanged.

Before publication, restore public reports:

```bash
bun run check:candidate
git diff --exit-code
git status --porcelain --untracked-files=all
```

The status output must be empty. Confirm the frozen HEAD, toolchain, module
contents and both fingerprints still match; the ignored evidence remains local
and must still match. The clean-worktree check alone does not prove that ignored
inputs or generated bytes match. Recheck candidate state before staging later
repository-only changes as well.

## Ordered local registry publication

Publication is an explicit operator action, not a CI step. Authenticate locally
as the module owner; do not add CI credentials or create version tags.

1. Recheck registry availability and confirm the frozen core/UI versions are
   not already occupied. An occupied version must not be overwritten.
2. From the clean validation checkout, publish core first:

```bash
moon publish --frozen
```

3. Wait until Mooncakes resolves core `0.2.0`. In a newly created temporary
   directory outside this repository and every ancestor `moon.work`, install
   the registry CLI into a temporary binary directory:

```bash
moon install --bin <temporary-bin> lampclaw/minimoon/cmd/minimoon@0.2.0
<temporary-bin>/minimoon init <temporary-app>
```

   Do not pass `--minimoon-root`. Confirm no local workspace override exists,
   run `moon update`, inspect the resolved core version, install the generated
   JavaScript dependencies, and run native/JS checks and tests, build and
   `verify --candidate`. Compare the downloaded module contents with the
   prechecked archive. This proves registry core/CLI/starter usability, not a
   new application's real-host pass.
4. Unpack the already reviewed UI archive outside the repository. Resolve its
   dependency through registry core `0.2.0`, without binding local core, and
   rerun native/JS and build-resource consumer checks. Do not repack edited
   source under the frozen version.
5. Only after those checks pass, publish the unchanged UI module from the
   original clean validation checkout:

```bash
moon -C ui publish --frozen
```

6. Wait for UI `0.1.0` resolution. Create another registry-only consumer of
   both modules: import root, headless and theme for native/JS behavior checks,
   and exercise resources through the native build-provider path. Do not
   import build resources into application JavaScript. Run resource generation
   and candidate verification, then confirm resolved versions and downloaded
   module contents.
   No local core/UI workspace binding may satisfy these checks.

If core publication succeeds and UI publication or consumer checks fail, stop
and report a partial release. Do not automatically yank core, alter a published
version or claim both modules are released. If a publish result is ambiguous,
query the registry before retrying. Fixes to published package contents require
a new version and the relevant validation cycle.

Only after both versions resolve and their fresh consumers pass, record the
actual source SHA, publication date and registry links in repository-only
`docs/project_status.md`. Do not rewrite an already published README/changelog
under the same version. Real-host timestamps, tool versions, notes and outcomes
remain local; no evidence file belongs in a commit or CI attachment.

## Source-only drift

MoonBit release minification can change when blocks move between source files.
Equal interfaces and passing tests establish source/API equivalence, not
identical generated bytes. Every changed artifact fingerprint requires its own
real-host acceptance; never restore old generated bytes merely to retain
evidence.
