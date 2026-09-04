# Maintained example

The repository keeps one release-bound real-host fixture:

| Example | Pages | Coverage |
| --- | ---: | --- |
| [`miniapp_conformance_app`](miniapp_conformance_app/README.md) | 4 | bilingual showcase, state, query input, lifecycle, capabilities, navigation, incremental diff, local components, subscriptions, scrolling, native controls, semantic content navigation, optional theme, and page-instance isolation |

This consolidation makes every generated-byte change require one Developer
Tools import and one artifact fingerprint. `swiper` remains a control under
test; real page navigation is the primary application structure, and the Lab
page uses a vertical `scroll-view` for long-form interaction testing.

The production-oriented source embedded by `minimoon init` is separate and
lives in [`templates/starter`](../templates/starter/). It intentionally avoids
the conformance application's kitchen-sink UI.

Build and verify from the repository root:

```bash
bun run check:candidate
```

`generated/verify_report.json` is the tracked automated candidate source.
`generated/devtools.evidence.json`, when present, is a local, Git-ignored,
fingerprint-bound real-host record. Documentation never copies artifact
fingerprints or local validation outcomes.
