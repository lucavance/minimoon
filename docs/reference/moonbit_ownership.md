# MoonBit Ownership

Framework, CLI, generator, verification, and test implementation is
MoonBit-owned, apart from the bounded standalone adapter below. Ownership is
not a claim that every character in a `.mbt` file is MoonBit: host and validation
JavaScript is also maintained inside MoonBit string literals.

## Maintained Boundary

The only maintained standalone JavaScript file is:

```text
scripts/bridge/weapp_tailwindcss_adapter.mjs
```

It is limited to the JS-only `weapp-tailwindcss/postcss` and class escaping
APIs. The native build package embeds an exact copy and the static suite checks
parity and the 100-line ceiling. Published build and verification host sources
are maintained as MoonBit-owned strings in `internal_host_js`; repository-only
host, documentation, and performance harnesses live in
`internal_host_validation`. They are measured separately and written only as
generated or temporary scripts.

All other tracked JavaScript must be generated output below:

```text
examples/miniapp_conformance_app/dist/
ui/examples/showcase/dist/
```

The static suite rejects new JavaScript/TypeScript elsewhere. Generated output
is syntax and host-smoke checked rather than counted as maintained source.
The performance suite may create an ignored
`_build/perf/bridge_benchmark.cjs` transient harness from MoonBit source to
measure an exact generated release bridge; it is neither tracked nor maintained
JavaScript.

## Native Tooling

MoonBit owns:

- CLI argument parsing and path discovery
- embedded starter templates and drift checks
- App Contract v9, runtime ABI v11, and renderer protocol v8 compilation
- MoonBit JS process orchestration
- MiniApp project writing
- Tailwind process orchestration and cleanup
- artifact fingerprints and DevTools evidence
- bilingual code-analysis diagram extraction, manifests, and drift checks
- repository validation suites and ownership metrics

There is no independently maintained shell or JavaScript task runner or fixture
implementation. Embedded validation scripts and generated fixture JavaScript
remain explicit parts of the repository. `package.json` declares external
JavaScript tooling dependencies and aliases native commands; CI also contains
shell orchestration, not a separate framework implementation.

## Metrics

```bash
minimoon metrics
minimoon metrics --json
minimoon metrics --include-untracked --json
bun run check:metrics
```

The repository-local command is also available through `bun run metrics`. It
does not invoke generators, write a report, or require an external line-counting
tool. JSON output uses `schemaVersion: 2`; the old flat line-count fields are
replaced, not retained as a second ambiguous baseline.

### File ledger

The default selection is Git-tracked paths, read from the **working tree**, not
from `HEAD` blobs. `--include-untracked` also selects non-ignored untracked files.
Paths are NUL-delimited, sorted and deduplicated. Missing paths are reported
separately; ignored caches and temporary files are not silently added to the
selection. Repeated runs over unchanged selected bytes produce the same output.

Every measured file belongs to exactly one owner and role. Owners distinguish
Core, UI, the two maintained fixtures, starter, and repository support; Core
also distinguishes framework, tooling and validation. Roles distinguish
maintained source, tests, benchmarks, generated artifacts, generated interfaces,
frozen API snapshots, documentation, configuration and assets. Generated
artifacts include both fixtures' `dist/` and `generated/` trees, generated WXSS,
and `*.generated.mbt`. Frozen API snapshots also include their pinned consumer
sources and manifests; they are not current implementation source. Generated
paths are restricted to the maintained output boundaries, not inferred merely
because an arbitrary source directory is named `dist` or `generated`.

The file ledger reports file counts, raw byte counts and physical text lines,
with summaries by owner, role and file language. A physical line includes
comments and blank lines; a terminal newline does not create an extra line.
Binary files have no physical-line count but retain their file and byte counts.
Non-regular paths fail explicitly rather than following symlinks outside the
selected repository files.
Identical content at two separate paths is counted twice because it occupies
two repository files. MoonBit manifests are configuration, not AMPL programs.

These are file-language statistics, not a semantic language census. In
particular, `.mbt` totals include string literals, and compressed generated JS
is better assessed by bytes than by its very small physical-line count.

### Embedded-script ledger

`embeddedScripts` is a separate inventory of script literals within selected
MoonBit files, excluding generated artifacts and frozen API snapshots. Entries
identify their source file, declaration and category: `production`, `validation`,
`test`, `example`, or `excluded`. Synthetic fixture data belongs to `excluded`,
with a reason, rather than to a maintained-script total. The registry uses declaration names and stable literal or
binding selectors, never source line numbers as selectors.

The scanner measures physical source lines and the UTF-8 byte ranges of selected
literal payloads. It excludes surrounding quotes and multiline-string markers,
preserves source escapes such as `\n`, and does not expand dynamic model data,
paths or parameters into generated script size. Selected interpolated literals,
including `$|` strings, fail explicitly and require decomposition into static
script fragments; the tool does not subtract arbitrary embedded expressions.
Multiple literals on one
line count that source line once. A shared helper is counted at its maintained
definition, not again for every call or App/non-App assembly. Separately
maintained identical literals count at both locations. The embedded adapter
mirror is excluded because the standalone `.mjs` file is already maintained and
measured independently. Generated starter copies are excluded as well.

**Do not add embedded-script counts to the file ledger:** their source already
exists inside the `.mbt` files. This additional view explains ownership; it is
not another disjoint language bucket, and it does not measure executed or
release-minified JavaScript bytes. Fixture data and exclusions are not added to
the maintained embedded-script subtotal.

The metrics gate tests synthetic examples with exact expected counts, checks
repository classifications and aggregate sums, and rejects missing or ambiguous
inventory entries, overlapping selections, unclassified multiline literals and
JS FFI, and newly detected script-producing strings. The scanner is not a
MoonBit data-flow analyzer: arbitrary dynamically constructed scripts still need
review and explicit registration. New script-encoding forms must extend its
tests and discovery rules rather than claiming universal semantic detection.

`.gitattributes` presentation does not affect either ledger. The ownership gate
does not require padding MoonBit lines, hiding maintained files as generated, or
optimizing a language ratio. Live repository totals are intentionally not copied
into this document, where they would immediately become stale.

## Generated MoonBit

`templates.generated.mbt` and `.mbti` interfaces remain generated artifacts.
Template generation runs `moon fmt` before drift comparison. `moon info` must
leave committed public interfaces unchanged.

## Current documentation versus history

The documentation gate checks current Contract, ABI, protocol and MiniApp
configuration examples against `internal_versions`. `CHANGELOG.md` is historical.
Within an active guide, a necessary historical or legacy-compatibility example
must use a bounded pair of HTML comment markers named
`minimoon:historical:start` and `minimoon:historical:end`, each on its own line.
State the historical
purpose in the enclosed prose. The markers exempt only the enclosed version
claims and configuration examples, not the rest of the guide or other checks;
nested, unmatched or unclosed markers are rejected. Do not use them to hide
stale current instructions.
