# Maintained verification examples

The repository keeps separate core and UI real-host fixtures:

| Example | Pages | Native Tabs | Coverage |
| --- | ---: | ---: | --- |
| [`miniapp_draft_workbench`](miniapp_draft_workbench/README.md) | 9 | 4 | 工作台 / 草稿 / 联机 / 更多; local draft CRUD, typed echo, App/Page lifetime and four capability laboratories |
| [UI showcase](../ui/examples/showcase/README.md) | 6 | 0 | all 64 RUI families plus Form/Theme, native controls, layers, touch measurement, resources and ownership |

Each fixture has its own Developer Tools import and artifact fingerprint.
Shared host changes require both to be revalidated. `swiper` remains a control
under test; real page navigation is the primary application structure, and Runtime Lab
page uses a vertical `scroll-view` for long-form interaction testing.

The production-oriented source embedded by `minimoon init` is separate and
lives in [`templates/starter`](../templates/starter/). Start your own application
with the [quickstart](../docs/guides/miniapp_quickstart.md); use Draft Workbench and
UI Showcase to explore framework behavior rather than copying their full contents.

Build and verify from the repository root:

```bash
bun run check:candidate
```

`generated/verify_report.json` is the tracked automated candidate source.
`generated/devtools.evidence.json`, when present, is a local, Git-ignored,
fingerprint-bound real-host record. Documentation never copies artifact
fingerprints or local validation outcomes.
