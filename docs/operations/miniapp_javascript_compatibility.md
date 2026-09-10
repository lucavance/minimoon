# MiniApp JavaScript compatibility troubleshooting

This runbook covers a generated distribution that fails before a page can
register or mount in WeChat. The 0.1.0 release baseline uses the direct
CommonJS boundary with Developer Tools ES6-to-ES5 transformation, enhanced
compilation, and code minification enabled.

## Recognize the first failing stage

| Stage | Typical first error | Interpretation |
| --- | --- | --- |
| Parse | `invalid file: minimoon.host.js` / `Unexpected token` | unsupported syntax escaped generation |
| Package | Developer Tools asks whether to compile ES6+ to ES5 | confirm the generated project still has all three verified compilation flags enabled |
| Module initialization | blank page and a missing global such as `TextEncoder` | syntax loaded, but linked runtime code assumed a browser API absent in MiniProgram |
| Registration/render | Page exists but remains blank or times out | inspect the first scheduler, runtime, or WXML error and renderer stats |

Always diagnose the first console error. Later lifecycle and blank-screen
symptoms usually follow from it.

## Parser compatibility

The maintained parser-compatibility case covers optional chaining in both the
host template and linked MoonBit core output. Its handling has two owners:

- host templates use explicit compatible guards;
- the runtime postprocessor normalizes the known linked crypto expression.

Release generation also minifies the host through Bun before compatibility
rewrites. Every generated JavaScript file is parsed at the maintained syntax
boundary and audited for unresolved globals. Optional chaining, nullish
coalescing, and direct unsupported constructs are rejected.

Do not patch `dist/minimoon.host.js`. Edit the MoonBit-owned source in
[`internal_host_js`](../../src/internal_host_js/) or the bounded compiler-output
normalizer in
[`tooling_miniapp/compilation.mbt`](../../src/tooling_miniapp/compilation.mbt),
then add a regression.

## Developer Tools compilation settings

Generated `project.config.json` must contain:

```json
{
  "setting": {
    "es6": true,
    "enhance": true,
    "minified": true
  }
}
```

If preview or device debugging asks to enable compilation, accept the checked-in
configuration and confirm Developer Tools did not replace it with a local
override. The generated CommonJS must still pass Minimoon's direct syntax and
host-global audit before this tool-version-dependent deployment transform runs.
Capture the first unsupported expression if compilation still fails.

## Missing `TextEncoder`

MoonBit's linked UTF-8 path may construct `TextEncoder` during module
initialization, while some MiniProgram devices do not expose that Web API. The
runtime postprocessor therefore:

- adds a private UTF-8 encoder only when compiler output references the
  constructor;
- accepts compiler output with or without constructor parentheses;
- uses native `globalThis.TextEncoder` when available and otherwise writes
  UTF-8 bytes through `Uint8Array`;
- handles surrogate pairs and unmatched surrogates correctly;
- does not create or mutate a host-global `TextEncoder`.

Do not add speculative browser polyfills. A new missing global needs an exact
linked-runtime reproduction, a bounded compatibility transform, host-global
audit changes, and real-host validation.

## Scheduler and blank-page diagnosis

The host permits one render in flight and waits for a commit-sentinel
`setData` callback. A missing callback performs one snapshot retry after three
seconds, then fails closed. Inspect:

```javascript
getCurrentPages().at(-1).__minimoonRendererStats()
```

`renderRetries`, `renderTimeouts`, or `schedulerFailures` above zero indicate a
host/render problem. A growing `maxEventBatch` without failures can be normal
when rapid taps arrive behind a slow acknowledged render; all events must still
be reflected in order.

## Diagnosis workflow

1. Build release output and reproduce from the unchanged `dist/` directory.
2. Clear Developer Tools caches so logs and fingerprint refer to the same
   bytes.
3. Capture the first error, generated filename, require chain, tool version,
   and whether preview or device debugging failed.
4. Classify parse, package, missing-global, registration, or acknowledged-render
   failure.
5. Search generated output and its maintained owner:

   ```bash
   git grep -n -E '\?\.|\?\?' -- examples/miniapp_draft_workbench/dist src
   git grep -n -E 'TextEncoder|TextDecoder' -- examples/miniapp_draft_workbench/dist src
   ```

6. Fix the maintained owner, not only the generated fixture.
7. Add an executable negative control, rebuild twice, and check deterministic
   bytes and ceilings.

## Regression coverage

Current gates cover compatibility-transform idempotence, exact UTF-8 cases,
host execution with `globalThis.TextEncoder` absent, ECMAScript/global audits,
direct Page registration, ordered event batching, render acknowledgement and
timeout recovery, deterministic release generation, and a 424,000-byte
aggregate JavaScript ceiling.

Run the repository gates in the prescribed order, then follow
[`miniapp_devtools_validation.md`](miniapp_devtools_validation.md). Import the
exact release, keep ES6-to-ES5 transformation, enhanced compilation, and code
minification enabled, use Skyline and base library 3.17.0 or newer, test preview
and a physical device with a clean console, and record new evidence only for
the fingerprint that actually passed.
