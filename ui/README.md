# Minimoon UI

Native, touch-first Skyline components for Minimoon. Module
`lampclaw/minimoon_ui 0.1.0` depends on core `lampclaw/minimoon 0.2.0`.

The fixed reference is RUI 0.1.1 in Rabbita 0.15.6, commit
`b1291945fd0201a0b5b39513b88585d6122db7bc`. The library uses public Minimoon
nodes and Val composition, not Rabbita's browser runtime. The MIT notice and
upstream visual-recipe attribution are retained in [LICENSE](LICENSE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). See the module's
[changelog](CHANGELOG.md) for versioned changes.

## Install

Add both modules to the application's TOML-style `moon.mod`:

```moonbit
import {
  "lampclaw/minimoon@0.2.0",
  "lampclaw/minimoon_ui@0.1.0",
}
```

Import the component package in the page's `moon.pkg`:

```moonbit
import {
  "lampclaw/minimoon" @minimoon,
  "lampclaw/minimoon_ui" @ui,
}
```

Current registry availability is recorded in
[project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).
Run `moon update` after declaring published dependencies. In this repository,
`moon.work` resolves both modules locally; a development checkout can similarly
include the application and both module directories in its workspace. A
registry-only consumer must have no such local overrides.

Enable build resources in App Contract v9:

```json
{
  "schemaVersion": 9,
  "name": "ui_app",
  "resources": [
    {"package": "lampclaw/minimoon_ui/resources", "features": []}
  ],
  "pages": [{"package": "src/pages/home"}]
}
```

An empty feature list includes the full bundle. A nonempty list, such as
`["button", "dialog", "slider"]`, includes the requested components and their
resource dependencies. Unknown features fail the build. The native provider
exports WXSS and SVG assets; it is not imported into application JavaScript.
Core has no dependency on this UI module.
Existing schema `8` configurations remain accepted without `application`;
generated artifacts use the current Contract v9/runtime ABI v11. To combine UI
with shared state, opt into the core [App setup](https://github.com/lucavance/minimoon/blob/main/docs/guides/shared_state.md)
and make page factories take `Deps`; UI roots still belong to individual pages.

Feature selection currently chooses resource groups, not per-component CSS
tree shaking: base/foundation/compound styles and the six theme icons are shared;
form styles are included when required. The resolved feature inventory is
deterministic, but selecting one feature does not produce only its selectors.

## Page ownership

Create one UI root inside a page builder:

```moonbit
pub fn program() -> @minimoon.Page {
  @minimoon.page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="UI",
    capabilities=[@minimoon.MeasureNodes],
    build=page => @ui.root(page, context => {
      @ui.dialog(
        context,
        id="welcome",
        title="Welcome",
        trigger_label="Open",
        content=@minimoon.Val::constant(@minimoon.text("Hello Skyline")),
      )
    }),
  )
}
```

`UiContext` and its notifications belong to that page. Declare `MeasureNodes`
for anchored surfaces, custom touch controls and measured message scrolling.
Use unique, safe component IDs consisting of letters, digits, underscores or
hyphens. Components take typed callbacks and reactive content; create child
state outside Node-rendering callbacks.

Native events can arrive as one predecoded batch. Relative actions must read
state at dispatch time: use Elm messages or `emit(current => current + 1)`, not
a replacement computed from a render-captured value. UI controls follow the
same rule internally, including multi-selection and repeated toggles.

Interactive components expose controlled state, self-owned convenience forms
or explicit provider scopes. `Val[Node]` slots remain reactive when a surface
is open. `@ui.stack` combines independent component values. The root lifts
declarative layers outside scrolling/clipped content without retaining removed
Val scopes in a global registry.

Render either `toaster(context)` or `sonner(context)` once per page. Both
present the same queue; `toast(context, toast_notice(...))` creates a command.
Timers pause while the page is hidden and are reclaimed on disposal.

## Packages and customization

- Default package: component builders, controlled APIs and compound providers.
- `/headless`: date selection, placement, slider and resize algorithms.
- `/theme`: typed Light/Dark palettes, Ltr/Rtl direction and Vega tokens.
- `/resources`: build-only WXSS/SVG provider and feature inventory.

Pass a reactive Theme to `root(theme=...)` to switch theme or direction.
Classes use `mmui-*`, variables use `--mmui-*`; class/style and content
slots allow native customization. Existing core components and minimal themes
remain supported and are not redirected through this module.

Hover previews are tap/long-press surfaces; context menus provide a click
alternative to long-press. Kbd displays shortcut hints without listening for
desktop keys. Chart provides containers, legends and tooltips, not a chart
engine. Native navigation accepts MiniApp Route values, not browser URLs.
Form/Field present application-owned validation; Attachment does not own
upload backends.

## Verification and migration

The repository-maintained [migration map](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md)
and machine-readable API inventory distinguish implemented equivalents,
consolidated APIs, native substitutions and incomplete work. A named component
or gallery section alone is not proof of every upstream behavior.

The six-page [showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md)
covers all 64 component
families plus Form and Theme. It is independent of core's four-page Conformance
fixture and does not add a dependency to the default starter.

Run from the repository root:

```sh
moon test ui/src --target native
moon test ui/src --target js
bun run check:coverage
bun run check:candidate
```

Candidate verification is not real-host evidence. Build and import the exact
Skyline artifacts into WeChat Developer Tools, validate the checklist and keep
local fingerprint-bound evidence ignored. No release, publication or host pass
is implied by the module version.

Build the release-mode candidate from the repository root:

```sh
bun run minimoon build ui/examples/showcase
bun run minimoon verify ui/examples/showcase --candidate
```

Import `ui/examples/showcase/dist` unchanged into Developer Tools with Skyline
and a minimum online base library of 3.17.0. Follow every check in the showcase's
`miniapp.minimoon.json`, including multiple-value controls, delayed surfaces,
mobile sidebar gestures and page lifecycle. Core's Conformance fixture needs
its own new fingerprint-bound validation because the shared host bytes changed.

The API map covers 428 upstream functions and 89 types. Native substitution is
intentional: Carousel uses fixed native swiper slides; MessageScroller uses
keyed updates and explicit content revisions instead of DOM overflow anchors;
focus selectors, browser shortcuts and mouse-only behavior are not recreated.

MessageScroller observes keyed appends/prepends. Increment its
`content_revision` value when streaming changes content without changing
message keys, so layout measurement can preserve the reader's position.
