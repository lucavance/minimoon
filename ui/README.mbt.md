# Minimoon UI

Native, touch-first Skyline components for Minimoon. Module
`lampclaw/minimoon_ui 0.1.1` declares core `0.2.2`; this source guide uses
the compatible core `lampclaw/minimoon 0.2.3` patch without republishing UI.

The fixed reference is RUI 0.1.1 in Rabbita 0.15.6, commit
`b1291945fd0201a0b5b39513b88585d6122db7bc`. The library uses public Minimoon
nodes and Val composition, not Rabbita's browser runtime. The MIT notice and
upstream visual-recipe attribution are retained in [LICENSE](LICENSE) and
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). See the module's
[changelog](CHANGELOG.md) for versioned changes.

## Install

Use `moon 0.1.20260920` / `moonc v0.10.14` or newer and the matching core CLI
`0.2.3`. Global `vp 0.3.3` manages Node `26.9.0` and Bun `1.4.2`;
Node `>=24.20.0` remains supported and CI checks the lower boundary. Follow
the [environment setup](https://github.com/lucavance/minimoon/blob/main/docs/guides/miniapp_quickstart.md#prerequisites);
no separate Bun installation or local `vite-plus` dependency is needed.
First confirm registry availability in
[project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md).
Before publication, use an explicit source workspace instead of assuming these
versions are downloadable.

Add both modules to the application's TOML-style `moon.mod`:

```moonbit
import {
  "lampclaw/minimoon@0.2.3",
  "lampclaw/minimoon_ui@0.1.1",
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

Enable build resources in App Contract v11:

```json
{
  "schemaVersion": 11,
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
Schema `8`, `9` and `10` configurations must migrate to `11`;
generated artifacts use Contract v11/runtime ABI v13. To combine UI
with shared state, opt into the core [App setup](https://github.com/lucavance/minimoon/blob/main/docs/guides/shared_state.md)
and make page factories take `Deps`; UI roots still belong to individual pages.

Feature selection currently chooses resource groups, not per-component CSS
tree shaking: base/foundation/compound styles and the six theme icons are shared;
form styles are included when required. The resolved feature inventory is
deterministic, but selecting one feature does not produce only its selectors.

## Upgrade an existing UI application

Upgrade the CLI and your direct core dependency to `0.2.3`; keep UI at `0.1.1`.
UI itself keeps its published core `0.2.2` declaration. Set Node `26.9.0` in
`devEngines.runtime` while retaining `engines.node: ">=24.20.0"` and Bun
`1.4.2` in `devEngines.packageManager`. Update
an existing style `package.json` to weapp-tailwindcss `5.5.7`, keeping Tailwind
`4.3.3`, PostCSS `8.5.28` and its override; run `vp install` to refresh the
lockfile. `minimoon build` does not rewrite that manifest. Use explicit package
qualifiers and public trait extensions where required by the new MoonBit
compiler. Follow the [complete upgrade procedure](https://github.com/lucavance/minimoon/blob/main/docs/reference/compatibility_and_upgrades.md#upgrade-procedure),
then rebuild all resources and generated artifacts. Old fingerprints do not
validate the new bytes.

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
families plus Form and Theme. It is independent of core's nine-route Draft Workbench
fixture and does not add a dependency to the default starter.

Run from the repository root:

```sh
moon test ui/src --target native
moon test ui/src --target js
vp run --no-cache check:coverage
vp run --no-cache check:candidate
```

Candidate verification is not real-host evidence. Build and import the exact
Skyline artifacts into WeChat Developer Tools, validate the checklist and keep
local fingerprint-bound evidence ignored. No release, publication or host pass
is implied by the module version.

Build the release-mode candidate from the repository root:

```sh
vp run minimoon build ui/examples/showcase
vp run minimoon verify ui/examples/showcase --candidate
```

Import `ui/examples/showcase/dist` unchanged into Developer Tools with Skyline
and a minimum online base library of 3.17.0. Follow every check in the showcase's
`miniapp.minimoon.json`, including multiple-value controls, delayed surfaces,
mobile sidebar gestures and page lifecycle. Core's Draft Workbench fixture needs
its own new fingerprint-bound validation because the shared host bytes changed.

The API map covers 428 upstream functions and 89 types. Native substitution is
intentional: Carousel uses fixed native swiper slides; MessageScroller uses
keyed updates and explicit content revisions instead of DOM overflow anchors;
focus selectors, browser shortcuts and mouse-only behavior are not recreated.

MessageScroller observes keyed appends/prepends. Increment its
`content_revision` value when streaming changes content without changing
message keys, so layout measurement can preserve the reader's position.

## Maintainer publication boundary

Publication is a separate, explicitly authorized maintainer action. Do not
publish directly from this repository's `ui/` directory or run
`moon -C ui publish`: the packaging issue observed with `moon 0.1.20260907`
can inherit the root `.moonignore` `/ui/` exclusion and produce an empty archive. The repository gate packages an
isolated source copy and validates its actual ZIP, required files and consumers.

UI `0.1.1` is already published, with its original core `0.2.2` dependency.
This core `0.2.3` migration updates repository guidance and consumers, but does
not republish UI or change the occupied registry archive. The checked source
archive remains `_build/publish/lampclaw-minimoon_ui-0.1.1.zip`; its current
repository documentation may differ from the immutable published README.
Future UI publications must use an unoccupied version and the independently
extracted, reviewed archive workflow.

For core `0.2.3`, the user authorizes publication after complete candidate checks
and both CI jobs pass, without waiting for new host validation. Developer Tools
remains pending, reports keep `release: false`, and no host pass is implied.
The actual `verify --release` evidence gate is unchanged. Follow the
[ordered release procedure](https://github.com/lucavance/minimoon/blob/main/docs/operations/release_candidate_handoff.md#ordered-local-registry-publication).
The linked guides are repository-hosted because `ui/docs` is not shipped in
the registry archive.
