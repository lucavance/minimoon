# Maintained verification examples

[中文](README.zh-CN.md)

The repository keeps separate core and UI examples and real-host fixtures.

## Try the examples

<!-- minimoon:preview:start -->
Download or clone this repository and import either directory below directly into
WeChat Developer Tools. Existing output needs no MoonBit, Node or build step.

| Example | Pages | Native Tabs | Coverage | Import directory, relative to the repository root |
| --- | ---: | ---: | --- | --- |
| [`miniapp_draft_workbench`](miniapp_draft_workbench/README.md) | 9 | 4 | 工作台 / 草稿 / 联机 / 更多; local draft CRUD, typed echo, App/Page lifetime and four capability laboratories | `examples/miniapp_draft_workbench/dist/` |
| [UI Showcase](../ui/examples/showcase/README.md) | 6 | 0 | all 64 RUI families plus Form/Theme, native controls, layers, touch measurement, resources and ownership | `ui/examples/showcase/dist/` |
<!-- minimoon:preview:end -->

Use Skyline and base library **3.17.0** or newer, with ES6 transformation,
enhanced compilation and minification enabled. Configure your AppID in the local
private file following the [host settings](../docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools).

Each fixture has its own Developer Tools import and artifact fingerprint.
Shared host changes require both to be revalidated. `swiper` remains a control
under test; real page navigation is the primary application structure, and Runtime Lab
page uses a vertical `scroll-view` for long-form interaction testing.

The production-oriented source embedded by `minimoon init` is separate and
lives in [`templates/starter`](../templates/starter/). Start your own application
with the [quickstart](../docs/guides/miniapp_quickstart.md); use Draft Workbench and
UI Showcase to explore framework behavior rather than copying their full contents.

## Modify and rebuild

Prepare the [development environment](../docs/guides/miniapp_quickstart.md#prerequisites),
edit the chosen example's source, then follow its README to rebuild. The two-page
Starter is created by `minimoon init`; it must be built before importing its output.

## Maintainer validation

For the complete repository candidate gate, run from the repository root:

```bash
vp run --no-cache check:candidate
```

`generated/verify_report.json` is the tracked automated candidate source.
`generated/devtools.evidence.json`, when present, is a local, Git-ignored,
fingerprint-bound real-host record. Documentation never copies artifact
fingerprints or local validation outcomes.
