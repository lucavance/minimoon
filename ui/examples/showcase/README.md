# Minimoon UI Showcase

[中文](README.zh-CN.md)

This six-page example and verification application exercises `lampclaw/minimoon_ui 0.2.0`
with core `lampclaw/minimoon 0.3.2`. It covers all 64 pinned RUI families plus
Form, Theme and optional Markdown, with native substitutions described in the
[migration map](../../docs/migration.md).

## Import and try

<!-- minimoon:preview:start -->
Download or clone this repository and import **`ui/examples/showcase/dist/`**
directly into WeChat Developer Tools. Import the output directory, not the source.
The committed output needs no MoonBit, Node or build step to open.
<!-- minimoon:preview:end -->

Use Skyline, base library **3.17.0** or newer, and `setting.es6=true`,
`setting.enhance=true`, `setting.minified=true`. Configure your AppID only in the
ignored private file using the [host settings](../../../docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools).
Alternatively, download the matching commit's CI `minimoon-ui-devtools-<commit>`
bundle. It is independent of core's `minimoon-devtools-<commit>` artifact; verify
both file and ZIP checksums before importing its unchanged `dist/`.

## Pages and interactions

Switch Nova/Vega on each page without resetting state. Foundation includes
native Markdown; Forms includes the four-phase property-reset probe; Overlays
includes four-sided open-Drawer edge gestures.

The Forms page sends only a non-sensitive title to public
`https://echo.apifox.com/post`, with a ten-second timeout. Typed echo is not
persistent storage. `vp run check:http-live` includes this form alongside the
core example's HTTP scenarios; it uses a transport shim rather than WeChat host
execution. Changing the endpoint requires acceptance of the new artifact fingerprint.

## Modify and rebuild

Prepare the [development environment](../../../docs/guides/miniapp_quickstart.md#prerequisites),
edit the example's source, then run from the repository root:

<!-- minimoon:rebuild:start -->
```bash
vp run minimoon verify ui/examples/showcase --candidate
```
<!-- minimoon:rebuild:end -->

This builds release-mode output before automated candidate verification.
Reimport or recompile the same directory afterwards; keep `dist/` as generated output.

## Maintainer validation and boundaries

The generated `smoke_checklist.json` includes every application-specific check
in `miniapp.minimoon.json`. Validate all six pages in the Skyline simulator,
physical-device preview and device debugging, using the host settings above.
Follow the [validation runbook](../../../docs/operations/miniapp_devtools_validation.md)
and [release handoff](../../../docs/operations/release_candidate_handoff.md).

Candidate reports leave real-host validation pending. UI Showcase owns its own
ignored, fingerprint-bound evidence; never substitute Draft Workbench's evidence.
Verification rebuilds artifacts. Reuse evidence only when the fingerprint is
unchanged, and repeat host acceptance for every affected fixture when it changes.
