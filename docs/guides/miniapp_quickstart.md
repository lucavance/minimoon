# MiniApp quickstart

## Prerequisites

Use `moon 0.1.20260827` with `moonc v0.10.11` or newer. JavaScript tooling
supports Node `>=24.20.0`, and Bun is pinned to `1.4.2`; keep the exact package
versions and PostCSS override emitted by `minimoon init`.

## 1. Install the matching CLI

```bash
moon install lampclaw/minimoon/cmd/minimoon@0.2.0
minimoon --version
```

Expected product version: `0.2.0`. See
[project status](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)
for current registry availability. For local development, run
`moon install --path src/cmd/minimoon` from a Minimoon checkout instead.

## 2. Create and build

```bash
minimoon init /tmp/my-app
cd /tmp/my-app
bun install
minimoon build .
minimoon verify .
```

Registry mode keeps `lampclaw/minimoon@0.2.0` in `moon.mod` and emits no
`moon.work`. For local framework development, pass `--minimoon-root "$PWD"`
when running `init` from the framework checkout; it creates a workspace binding.

The default starter imports only `lampclaw/minimoon`, exports
`program() -> Page`, and lists page packages in App Contract v9
`miniapp.minimoon.json`. It is a no-App example with no implicit UI dependency;
see the [shared-state guide](shared_state.md) to opt into application-owned
state and dependency-taking page factories. For native UI, add
`lampclaw/minimoon_ui@0.1.0`, import its root as `@ui`, and declare its build
resources as shown in the
[UI guide](https://github.com/lucavance/minimoon/blob/main/ui/README.mbt.md).

## 3. Add state

```moonbit
pub enum Msg { Increment }

pub fn program() -> @minimoon.Page {
  @minimoon.elmish_page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    model=0,
    update=(current, message, _emit) => match message {
      Increment => @minimoon.no_cmd(current + 1)
    },
    view=(value, emit) => @minimoon.button(
      on_tap=emit(Increment),
      event_key="increment",
      value.to_string(),
    ),
  )
}
```

## 4. Validate in WeChat Developer Tools

```bash
minimoon build . --mode release
```

Import `dist/` unchanged and verify:

- Skyline is active.
- ES6-to-ES5 transformation, enhanced compilation, and code minification remain
  enabled (`setting.es6=true`, `setting.enhance=true`,
  `setting.minified=true`).
- the online minimum base library is 3.17.0 or newer.
- taps, rapid repeated taps, controlled inputs, navigation, lifecycle, and
  unload work with a clean console.
- pages retain independent state across navigation and stack-aware fallback.

Record the exact release only after it passes:

```bash
minimoon devtools record . \
  --status passed \
  --recorded-at <actual-timestamp> \
  --tool-version "<actual-version>" \
  --notes "Minimoon 0.2.0 checklist passed"
minimoon verify . --release
```

The generated evidence file remains local and Git-ignored; never commit it or
copy another application's evidence. `verify --candidate` ignores that local
file and restores public candidate reports after a release decision. For
framework coverage use the core
[`miniapp_conformance_app`](https://github.com/lucavance/minimoon/blob/main/examples/miniapp_conformance_app/README.md)
and its four-page checklist, plus the independent six-page
[UI showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md)
when evaluating the UI module. Their host evidence is separate.
