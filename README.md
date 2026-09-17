# Minimoon

[中文](README.zh-CN.md) · [Quickstart](docs/guides/miniapp_quickstart.md) · [Documentation](docs/README.md)

Build WeChat Skyline MiniApps in MoonBit: describe pages, update typed state,
and let Minimoon generate the MiniApp files. No handwritten JavaScript bridge
or `setData` is needed.

## Project status

This source documents core `lampclaw/minimoon 0.2.1` and optional
`lampclaw/minimoon_ui 0.1.0`, both pre-1.0. Install the latest published CLI
from Mooncakes to create an independent application;
see [project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)
for the publication checkpoint and differences from the published packages.

## What you can build

- Stateful pages and reusable components with typed events, local state and navigation.
- HTTP-backed applications with typed requests and optional application-owned shared state.
- Native, touch-first interfaces using the optional Minimoon UI library; the starter needs only core.

## Before you start

Use `moon 0.1.20260904` / `moonc v0.10.12` or newer, Node `>=24.20.0`,
Bun `1.4.2` and WeChat Developer Tools with Skyline support.
Git is needed for the optional source development workflow.
Existing `moon 0.1.20260907` installations need no downgrade.
Both CI jobs pin `0.10.13+cbb11c36f` (`moon 0.1.20260915`);
the supported minimum remains unchanged.
See [environment setup](docs/guides/miniapp_quickstart.md#prerequisites) for
version checks and the pinned CI toolchain.

## Create your first app

Start in a development directory outside any existing Moon workspace, with
enough free space. Run these commands in a terminal with MoonBit, Node and Bun
available:

<!-- minimoon:onboarding:start -->
```bash
moon install lampclaw/minimoon/cmd/minimoon
minimoon --version
minimoon init my-app
cd my-app
moon update
bun install
minimoon build .
minimoon verify . --candidate
```
<!-- minimoon:onboarding:end -->

After candidate verification passes, open WeChat Developer Tools and import
**`my-app/dist/`**. Apply the [host settings](docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)
before running the MiniApp.

Use a new or empty `my-app/`. The app's `moon.mod` declares its core dependency,
resolved from Mooncakes; no `moon.work` or framework checkout is needed.
Do not pass `--minimoon-root` for this setup. `bun install` installs the app's
style build tools.

Omitting the CLI version selects the latest version in the registry. For a
repeatable installation, see [fixed-version installation](docs/guides/miniapp_quickstart.md#install-a-specific-version).
To develop the framework or use unpublished changes, follow the separate
[source workflow](docs/guides/miniapp_quickstart.md#create-from-the-current-source).

With `moonc v0.10.13`, the published `0.2.1` CLI supports the Starter above.
Apps that enable `application` need the current source CLI for an unpublished
build compatibility fix; see [toolchain compatibility](docs/reference/compatibility_and_upgrades.md#toolchain-compatibility).

Enable Skyline, ES6-to-ES5 transformation, enhanced compilation and minification
(`setting.es6=true`, `setting.enhance=true`, `setting.minified=true`);
use an online minimum base library of **3.17.0**.
For your AppID, edit only the ignored private configuration described in the
[quickstart](docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools).

You should see **Hello Minimoon**, a counter starting at **0**, a name input and
**Open details**. Tap **+1**: the counter becomes **1**. Open Details and return.
A passed CLI check is automated validation, not proof that these host interactions passed.

### Make your first change

In your generated app's `src/pages/home/page.mbt`, find the initial model inside
`program()` and change `name: "Minimoon"` to `name: "My App"`.
From `my-app/`, rerun `minimoon build .` and `minimoon verify . --candidate`.
Cold-restart the MiniApp: the heading should now read **Hello My App**.

Edit `src/`, not `dist/` or `generated/`. For rebuild-on-change, run
`minimoon dev .` in the app directory; this watches and rebuilds files, not
a browser preview server.

## What page code looks like

This small illustration shows the ordinary `page` / `Val` style. It is not
a replacement for the starter's complete Home page and its navigation/tests:

<!-- minimoon:counter:start -->
```moonbit
pub fn program() -> @minimoon.Page {
  @minimoon.page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    build=_ => {
      let (count, update_count) = @minimoon.create_variable(0)
      count.view(value => @minimoon.div([
        @minimoon.h1(value.to_string()),
        @minimoon.button(
          on_tap=update_count(current => current + 1),
          event_key="increment",
          "+1",
        ),
      ]))
    },
  )
}
```
<!-- minimoon:counter:end -->

`count` is a read-only value, `update_count` creates the update command, and
`view` describes what to display. The starter imports `lampclaw/minimoon`
in its page's `moon.pkg`. More complex behavior uses typed Model/Msg updates;
components are ordinary functions, not a mandatory object hierarchy.

## Learn next

1. [Pages, state and components](docs/guides/miniapp_authoring_example.md)
2. [Typed HTTP requests](docs/guides/http.md)
3. [Navigation and layout](docs/guides/native_navigation.md)
4. [Application-owned shared state](docs/guides/shared_state.md)
5. [Optional Minimoon UI](https://github.com/lucavance/minimoon/blob/main/ui/README.md)

## Examples

| Example | Use it for |
| --- | --- |
| Starter, created by `minimoon init` | Starting your own two-page application |
| [Draft Workbench](https://github.com/lucavance/minimoon/blob/main/examples/miniapp_draft_workbench/README.md) | Local drafts, typed echo and lifecycle: 9 pages, 4 native Tabs — 工作台 / 草稿 / 联机 / 更多 |
| [UI Showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md) | Exploring native UI components across 6 pages |

Draft Workbench's Platform laboratory owns the HTTP scenarios. From the framework
checkout, `bun run check:http-live` checks those scenarios, a typed draft echo
after editor unload, and the UI Form echo against public Apifox Echo (12 cases);
it is not a WeChat host test.

## Boundaries and next steps

Minimoon targets WeChat Skyline, not browser DOM compatibility or a general
cross-platform renderer. UI is optional, and applications supply their own
backends, credentials and production request domains.

The near-term focus is a reliable onboarding path and release preparation.
Dynamic account/workspace scopes and additional targets remain deferred, not
promised features or dates. Follow the [Roadmap](https://github.com/lucavance/minimoon/blob/main/docs/roadmap.md)
for priorities rather than treating this README as a task tracker.

## Contributing and internals

Start with the [documentation index](docs/README.md). The
[architecture](docs/architecture.md), [API ergonomics](docs/guides/api_ergonomics.md),
[repository validation and release workflow](docs/operations/release_candidate_handoff.md)
and [host checklist](docs/operations/miniapp_devtools_validation.md) cover the
details needed by framework contributors. Full repository gates and release
evidence are not prerequisites for writing your first application.

See [LICENSE](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES.md)
for licensing and Rabbita/RUI provenance.
