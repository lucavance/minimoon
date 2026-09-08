# Minimoon UI changelog

This independently versioned module is `lampclaw/minimoon_ui`. Its version is
defined by `moon.mod`; it does not use Git version tags. Registry availability
is recorded in the repository's
[project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).

## [0.1.0] - Unreleased

### Added

- Pure controlled `input`/`textarea`, explicit `input_stateful`/
  `textarea_stateful` convenience, and reactive application-owned `text_field`.
  The former overlapping `*_controlled` functions are removed in this candidate.

- Native, touch-first adaptations of all 64 RUI component families plus Form
  and Theme, using public Minimoon `Node`, `Val`, `Cmd` and page ownership.
- Default components, headless algorithms, typed Light/Dark and Ltr/Rtl themes,
  and build-only Vega WXSS/SVG resource packages.
- Controlled state, self-owned convenience builders, reactive content slots,
  page-owned layers, notifications and disposal-safe delayed interactions.
- Independent six-page showcase, native/JS behavior tests, API snapshots,
  coverage, resource, archive-consumer and dual-fixture CI handoff checks.

### Compatibility and provenance

- Declares `lampclaw/minimoon@0.2.0`; App Contract v10, runtime ABI v12 and
  renderer protocol v8 artifacts must be rebuilt as one set.
- References RUI 0.1.1 / Rabbita 0.15.6 at commit
  `b1291945fd0201a0b5b39513b88585d6122db7bc`; MIT and visual-recipe notices are
  retained. Rabbita's browser runtime is not a dependency.
- Controlled input authoring also references RUI 0.1.2 at
  `eccae7507360aec8465469bafb7fb4da5b260a2a`; this does not replace the scoped
  0.1.1 migration inventory or imply upstream publication.
- The [migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md)
  covers 428 functions and 89 types, distinguishing adaptation, consolidation
  and native substitution. It does not promise browser API or pixel parity.
- Carousel uses fixed native swiper slides; keyboard hints are display-only;
  MessageScroller uses keyed height-delta anchoring and explicit content
  revisions. Form validation and custom-widget values remain application-owned.
- Resources are selected by shared groups, not per-component CSS tree shaking.
  Existing core optional components and minimal themes remain independent.
- A release requires separate, exact-fingerprint Skyline acceptance for the
  core fixture and UI showcase. Automated candidate checks are not host evidence.
