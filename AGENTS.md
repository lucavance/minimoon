# Project Agents.md Guide

This is a [MoonBit](https://docs.moonbitlang.com) project.

You can browse and install extra skills here:
<https://github.com/moonbitlang/skills>

## Project Structure

- MoonBit packages are organized per directory; each directory contains a
  `moon.pkg` file listing its dependencies. Each package has its files and
  blackbox test files (ending in `_test.mbt`) and whitebox test files (ending in
  `_wbtest.mbt`).

- In the toplevel directory, there is a `moon.mod` file listing module
  metadata.

## Coding convention

- MoonBit code is organized in block style, each block is separated by `///|`,
  the order of each block is irrelevant. In some refactorings, you can process
  block by block independently.

- Try to keep deprecated blocks in file called `deprecated.mbt` in each
  directory.

## Tooling

- `moon fmt` is used to format your code properly.

- `moon ide` provides project navigation helpers like `peek-def`, `outline`, and
  `find-references`. See $moonbit-agent-guide for details.

- `moon info` is used to update the generated interface of the package, each
  package has a generated interface file `.mbti`, it is a brief formal
  description of the package. If nothing in `.mbti` changes, this means your
  change does not bring the visible changes to the external package users, it is
  typically a safe refactoring.

- In the last step, run `moon info && moon fmt` to update the interface and
  format the code. Check the diffs of `.mbti` file to see if the changes are
  expected.

- Run `moon test` to check tests pass. MoonBit supports snapshot testing; when
  changes affect outputs, run `moon test --update` to refresh snapshots.

- Prefer `assert_eq` or `assert_true(pattern is Pattern(...))` for results that
  are stable or very unlikely to change. For snapshot tests that record
  structured debugging output, derive `Debug` and use `debug_inspect`, rather
  than deriving `Show` for debugging. For solid, well-defined results (e.g.
  scientific computations), prefer assertion tests. You can use
  `moon coverage analyze > uncovered.log` to see which parts of your code are
  not covered by tests.

## Minimoon Project Context

Minimoon is MoonBit for WeChat MiniApp Skyline. Application business logic uses
Elm-style state machines, pages and local components compose through `Val`, and
a page-owned transactional incremental graph drives normalized MiniApp tree
diffs and generated host artifacts.

```text
Elm-style Model / Msg / update / Cmd / Sub
  -> Val-based Page and local component composition
  -> page-owned transactional incremental graph
  -> normalized MiniApp tree diff
  -> generated Skyline artifacts and declared wx.* adapters
```

- `src/` is the root application-facing `lampclaw/minimoon` package.
- `src/val_runtime` and `src/internal_duplix` own incremental composition,
  transactions, keyed scopes, and disposal.
- `src/renderer_miniapp` owns normalized tree diff and MiniApp renderer
  commands.
- `src/runtime_core` owns the resident runtime; root `authoring_*` files own
  every application-facing MiniApp type and command facade.
- `src/internal_versions` owns Contract, ABI, protocol, and mirrored product
  version facts; `src/internal_host_js` owns published build/verify host
  JavaScript templates, while `src/internal_host_validation` owns repository-only
  host, documentation, and performance validation sources.
- `src/tooling_miniapp` owns the current App Contract v7 host-artifact
  generator.
- `src/tooling_minimoon_build`, `src/tooling_minimoon_verify`, and
  `src/cmd/minimoon` own generation, verification, and the CLI.
- `examples/miniapp_conformance_app` is the single maintained four-page
  release fixture. `templates/starter` is the separate two-page source embedded
  by `minimoon init`.
- `scripts/bridge/weapp_tailwindcss_adapter.mjs` is the only standalone
  maintained JavaScript source adapter; embedded host JavaScript is MoonBit
  owned, and all committed example JavaScript is generated.

Applications import only `lampclaw/minimoon`. The public API does not expose a
mutable `Signal[T]`, direct patches, `setData`, or JavaScript bridge authoring.
CommonJS remains the verified MiniApp host boundary.

## Repository Workflow

This repository is the canonical Minimoon source. `main` is the primary branch,
and the canonical remote is `https://github.com/lucavance/minimoon`.

Before starting a task:

1. Read this file completely.
2. Read `README.mbt.md`, `docs/positioning.md`, `docs/mvp.md`,
   `docs/architecture.md`, and `docs/roadmap.md` when recovering project
   context.
3. Inspect `git status --short --branch`, `git log -1 --oneline`, and
   `git remote -v`; never assume the worktree is clean or discard existing
   changes.
4. Inspect the relevant source, tests, generated artifacts, and documentation
   before proposing or implementing a change.

For a fresh checkout, prepare the pinned environment with:

```bash
bun install --frozen-lockfile
moon update
node --version
bun --version
moon version --all
```

Do not import implementation or historical documentation from another
repository without an explicit request and a license/provenance review. Do not
push commits, create tags, publish packages, or record real-host evidence unless
the user explicitly authorizes that action.

## Project Tooling Notes

- This project uses the current TOML-style `moon.mod` and `moon.pkg` files; do
  not add or restore legacy `moon.mod.json` or `moon.pkg.json` files.

- Use `bun run ...` for repository task aliases. They dispatch native `minimoon`
  commands and do not own framework implementation.

- Generated MoonBit source files must be stable under MoonBit's formatter. Any
  MoonBit command that writes generated `.mbt` files, especially
  `*.generated.mbt`, must format the written file before stability checks
  compare it.

- Drift and parity checks for generated `.mbt` files must use the same
  formatted generation path as the committed artifact. Temporary generated
  `.mbt` files should live inside the relevant MoonBit package, or otherwise
  use the same package context as the real output, so `moon fmt <file>` behaves
  consistently.

- Source snippet checks for MoonBit files should be formatter-tolerant for
  whitespace and trailing commas when the exact formatting is not the behavior
  under test.

- The validated stable toolchain baseline is `moon 0.1.20260827` with
  `moonc v0.10.11+6ff76a5f9`, reconfirmed on 2026-09-04. JavaScript tooling
  supports Node `>=24.11.0`; CI validates the 24.11.0 lower boundary and the
  26.8.1 primary environment, while Bun is pinned to `1.4.0`. No `.node-version`
  is committed or generated. CI intentionally follows the latest MoonBit
  toolchain at or above this floor so upstream generated byte drift fails
  review instead of being accepted silently.
  Empty `{}` expressions are ambiguous: use `Map([])` for empty maps,
  `Json::empty_object()` for empty JSON objects, and `{ () }` for empty blocks.
  The aggregate gate requires `moon check` to be warning-free.

- Avoid committing broad formatting drift from a global `moon fmt`. If you run
  `moon fmt` or `moon info`, inspect the diff and keep only changes that belong
  to the current task, including expected `.mbti` updates.

- GitHub Linguist may mark true committed MiniApp build output as generated:
  `examples/*/dist/**` and `examples/*/generated/**`. Do not mark maintained
  files as generated to inflate MoonBit language statistics.
  JavaScript is limited to the bounded Tailwind adapter and generated MiniApp
  or MoonBit runtime output.

## Automated Validation

Before review, commit, or candidate handoff, run in this order:

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

After `moon info`, review every `.mbti` change. When no source change should
affect the public package surface, `git diff --name-only -- '*.mbti'` must be
empty. In a clean verification checkout, `git diff --exit-code` must also pass.

The final repository review must confirm:

- every tracked `verify_report.json` has `status: "passed"` and
  `release: false`;
- every tracked release summary keeps Developer Tools status `pending`;
- `dist/`, `generated/`, `.mbti`, and embedded templates have no unexpected
  drift;
- no maintained JavaScript or TypeScript has appeared outside the bounded
  adapter and generated-artifact allowlist;
- no developer-local AppID, private configuration, real-host evidence,
  credential, log, cache, or environment file is staged.

After real-host validation, run `bun run check:all` followed by
`bun run check:mvp` locally. Both release gates require the ignored,
fingerprint-bound Developer Tools evidence. After publication or release
handoff, rerun `bun run check:candidate` before staging so tracked reports
return to the public candidate state.

## WeChat Developer Tools Validation

Automated gates do not replace real-host validation when a change affects
generated WXML/WXSS/JavaScript, event routing, lifecycle, controls, navigation,
Skyline behavior, or the MiniApp bridge. Follow
`docs/operations/miniapp_devtools_validation.md` for every affected fixture.

- Build release artifacts and import the affected fixture's unchanged `dist/`
  directory.
- Keep ES6-to-ES5 transformation, enhanced compilation, and code minification
  enabled (`setting.es6=true`, `setting.enhance=true`,
  `setting.minified=true`).
- Use Skyline and configure an online minimum base library of 3.17.0 or newer.
- Test the interactions affected by the change and require a clean console.
- Evidence is valid only for its exact artifact fingerprint. Never copy
  evidence between applications or edit evidence JSON manually.
- If a fingerprint is unchanged, its existing passed evidence remains valid.
  If generated bytes change, revalidate every affected fixture before claiming
  a real-host pass.
- `generated/devtools.evidence.json` is developer-local and Git-ignored. Never
  commit or push its timestamp, tool version, notes, or pass/fail result.

After an actual host pass, record the exact tool version and timestamp, then run
release verification:

```bash
minimoon devtools record <app-dir> \
  --status passed \
  --recorded-at <actual-timestamp> \
  --tool-version "<actual-version>" \
  --notes "exact release checklist passed"
minimoon verify <app-dir> --release
```
