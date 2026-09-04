# MiniApp quickstart

## Prerequisites

Use `moon 0.1.20260827` with `moonc v0.10.11` or newer. JavaScript tooling is
reproducible with the generated `.node-version` (`26.8.1`) and Bun `1.4.0`;
keep the exact package versions and PostCSS override emitted by `minimoon init`.

## 1. Install the CLI from a checkout

```bash
moon install --path src/cmd/minimoon
minimoon --version
```

Expected product version: `0.1.0`.

## 2. Create and build

```bash
minimoon init /tmp/my-app --minimoon-root "$PWD"
cd /tmp/my-app
bun install
minimoon build .
minimoon verify .
```

The explicit `--minimoon-root` creates `moon.work` for local framework
development. Once the package is published, omit that option to create a
standalone registry consumer. Registry mode keeps the versioned dependency in
`moon.mod` and emits no `moon.work`.

The application imports only `lampclaw/minimoon`, exports `program() -> Page`,
and lists page packages in App Contract v7 `miniapp.minimoon.json`.

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
  --notes "Minimoon 0.1.0 checklist passed"
minimoon verify . --release
```

New applications start with real-host evidence pending. Never copy another
application's evidence. For framework coverage use the single
[`miniapp_conformance_app`](../../examples/miniapp_conformance_app/README.md)
and its four-page checklist.
