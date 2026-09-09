# Compile model

Configuration lists MoonBit page packages and does not duplicate application
behavior as metadata.

## Input

```json
{
  "schemaVersion": 11,
  "name": "miniapp_conformance_app",
  "application": { "package": "src/app" },
  "componentTheme": "minimal-v2",
  "devtoolsChecks": ["Runtime Lab native input focus, blur, and confirm"],
  "pages": [
    { "package": "src/pages/showcase" },
    { "package": "src/pages/interaction" },
    { "package": "src/pages/platform" },
    { "package": "src/pages/application" },
    { "package": "src/pages/request_lifecycle" },
    { "package": "src/pages/runtime_lab" },
    { "package": "src/pages/draft_editor", "smokeInput": { "from": "smoke" } }
  ],
  "tabBar": {
    "list": [
      { "package": "src/pages/showcase", "text": "首页" },
      { "package": "src/pages/interaction", "text": "交互" },
      { "package": "src/pages/platform", "text": "平台" },
      { "package": "src/pages/application", "text": "应用" }
    ]
  }
}
```

The factory is named `program` by default; an optional `program` field can
select another function. Its parameters depend on the application mode below.

With `application`, the configured application package exports `Deps` and `program() -> App[Deps]`;
each page factory takes `deps : @application.Deps`. Without it, page factories
remain no-argument. Both paths require source schema `11`; older schemas
must be explicitly migrated before building.

A page entry may provide `smokeInput`, a string-to-string map used only as the
synthetic Load input for automated host verification. Required-input pages must
provide a valid sample there. The manifest records this verification input;
it is not injected as a real runtime default or into `dist` initial data.

Optional bottom `tabBar` entries reference listed page packages. Extraction
resolves them into native `pagePath` values shared by manifest, host and
`app.json`; invalid routes or icon resources fail before replacing `dist`.
Page entries may opt into `navigationBarTextStyle: "black" | "white"` while
retaining custom navigation. See [native tabs and layout](../guides/native_navigation.md).

## Contract extraction and runtime compilation

Native tooling:

1. resolves the application module from `moon.mod`;
2. creates an app-local temporary executable importing one page package;
3. evaluates `app.preview(deps => page.program(deps).contract())` when opted in,
   or `program().contract()` otherwise, using explicit `preview_input()` seeds
   without calling actual input decoders or executing initialization commands;
4. validates Contract schema `11`, runtime ABI `13`, and renderer protocol `8`;
5. removes temporary source and target directories on success or failure.

After every contract is valid, one formatted temporary MoonBit executable
imports all page packages. At the first host Load, its page-aware factory
normalizes and decodes the actual route input before creating a graph. The ABI
receives a separate synchronous layout snapshot before the builder runs; layout
never becomes a route parameter. The ABI
returns a JSON success-ID or input-error envelope, never a fabricated runtime
for invalid required input. MoonBit builds it once into application-wide
`minimoon.runtime.js`; release mode strips/minifies the runtime and separately
minifies the generated host bridge. The build runs in a fresh dedicated target
directory and recursively locates exactly one output with the requested bundle
basename. It neither depends on MoonBit's internal directory layout nor reads
`packages.json`; zero or ambiguous matches fail with sorted candidate paths.

## App emission

```text
dist/
  app.js, app.json, app.wxss, project.config.json, sitemap.json
  minimoon.host.js, minimoon.protocol.js, minimoon.initial.js,
  minimoon.runtime.js, minimoon.templates.wxml
  minimoon.app.js                             only with application ownership
  project.private.config.example.json
  project.private.config.json                 optional ignored local override
  pages/.../<page>.json
  pages/.../<page>.js                          indexed registration bridge
  pages/.../<page>.wxml                        shared-template import + root
  pages/.../<page>.wxss                        empty
generated/
  manifest.json, diagnostics.json, expected_set_data.json
  smoke_checklist.json, release_summary.json, verify_report.json
```

Page order is preserved. Every bridge requires the shared host, protocol,
initial-tree, and runtime modules through app-relative paths; no page-local
runtime or embedded tree is emitted. The initial module contains only safe
empty boot trees; compile-preview state is not presented as actual page state.
The first successful Load sends a complete tree at revision 1, and its render
must be acknowledged before later entries run. Every page uses Skyline and custom
navigation. The contract title remains manifest metadata, not an ignored system
navigation field.

Public `project.config.json` sets `setting.es6=true`, `setting.enhance=true`,
and `setting.minified=true`. Generated CommonJS still passes the direct syntax
and host-global audit before entering this verified Developer Tools compilation
boundary. AppID and base-library selection remain in the ignored local private
config. Diagnostics use stable `MMN` codes, preserve the previous valid `dist`
on configuration failure, and never include a developer-local AppID in the
artifact fingerprint.

Optional `devtoolsChecks` entries are trimmed, required to be unique and
non-empty, and appended in declaration order to the generated smoke checklist.
They describe manual fixture behavior and do not enter the runtime contract.

Evidence fingerprint v2 covers the raw bytes of every regular file below
`dist/`, excluding only the local `project.private.config.json`, plus
`generated/manifest.json` and `generated/smoke_checklist.json`. App-relative
paths use `/`, are sorted, and are length-framed with their content before the
FNV-1a update. Changing, adding, or removing WXSS, WXML, JavaScript, config,
static assets, the manifest, or the checklist therefore invalidates evidence.

## Styles and determinism

MoonBit invokes app-owned Tailwind/weapp-tailwindcss dependencies through the
single maintained adapter. It writes transformed styles once to `dist/app.wxss`
and keeps page WXSS empty. Recursive control templates are emitted once to
`minimoon.templates.wxml`.

The code-generation gate creates release output twice and compares byte
snapshots. Temporary generated MoonBit sources use the same formatted package
context as committed generated sources. Static quality also rejects deprecated
`StringBuilder::new` construction and JS extern signatures containing mutable
`Array[T]`/`ReadOnlyArray[T]`; a true JavaScript array boundary uses
`FixedArray[T]`, while live host collections require an opaque snapshot wrapper.

## Development and scaffolding

`minimoon dev` watches MoonBit sources/manifests, Minimoon config, Tailwind
input, package manifests, and lockfiles while ignoring generated output and
dependencies. Builds are serialized and debounced; failure keeps the last
valid distribution.

`minimoon add page` and `minimoon add component` create formatted root-API
source and update configuration/imports atomically. Failure rolls back both the
new directory and edited manifest.
