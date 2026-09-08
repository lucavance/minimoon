# Minimoon authoring contract

This package-level README is compiled with the root package. It keeps the
primary authoring examples synchronized with the public API while the module
README remains the longer user-facing introduction.

## Elm-style pages

`Emit[Msg]` is a callable message sink. Mapping it adapts child payloads without
exposing a mutable signal or a renderer patch.

```moonbit check
///|
priv enum ReadmePageMsg {
  ReadmeIncrement
  ReadmeNameChanged(String)
}

///|
#warnings("-unused_value")
fn readme_page() -> Page {
  elmish_page(
    id="readme",
    route=route("pages/readme/readme"),
    title="Readme",
    model=(0, "MoonBit"),
    update=(model, message, _emit) => {
      match message {
        ReadmeIncrement => no_cmd((model.0 + 1, model.1))
        ReadmeNameChanged(name) => with_cmd((model.0, name), none)
      }
    },
    view=(model, emit) => {
      div([
        button(on_tap=emit(ReadmeIncrement), model.0.to_string()),
        input(value=model.1, on_input=value => emit(ReadmeNameChanged(value))),
      ])
    },
  )
}
```

## HTTP requests

HTTP requests use their page or application's declared `Request` capability. Non-2xx status codes
are transport successes; invalid arguments are deferred `InvalidPayload` errors.
The runtime executing the command owns the request, not its result emitter.
For an App-owned request, send a message to App and return `request` from the
App update; a request executed by a page still ends with that page's lifetime.

```moonbit check
///|
#warnings("-unused_value")
fn readme_request(resolve : Emit[Result[RequestResult, HostError]]) -> Cmd {
  request(
    "https://httpbingo.org/post",
    resolve,
    http_method=Post,
    query=[query("tag", "one"), query("tag", "two")],
    headers={ "X-Minimoon-Test": "public-smoke" },
    body=JsonBody(Json::object({ "message": Json::string("测试") })),
    timeout_ms=15000,
  )
}
```

## Optional application state

Without `application`, configured page factories take no arguments. With it,
the application factory returns `App[Deps]` and every page factory receives
those `Deps`. App constructors return `Shared[Model]`, while page-local
constructors return `Val[Model]`. Bind/select creates a page-owned projection.

Unlike page-local emitters, the App emitter below delivers across the page/App
boundary after the page transaction commits. It remains usable after another
page unloads, until its App is disposed.

```moonbit check
///|
priv struct ReadmeAppDeps {
  count : Shared[Int]
  change_count : Emit[Int]
}

///|
#warnings("-unused_value")
fn readme_app() -> App[ReadmeAppDeps] {
  app(build=context => {
    let (count, change_count) = context.create_pure_state(0, update=(
      count,
      delta : Int,
    ) => count + delta)
    { count, change_count, }
  })
}

///|
#warnings("-unused_value")
fn readme_shared_page(deps : ReadmeAppDeps) -> Page {
  page(
    id="readme_shared",
    route=route("pages/readme-shared/readme-shared"),
    title="Shared state",
    build=context => {
      context
      .bind(deps.count)
      .view(count => {
        button(
          on_tap=(deps.change_count)(1),
          event_key="readme/shared/increment",
          "Shared count: " + count.to_string(),
        )
      })
    },
  )
}
```

## Local state and resources

State constructors return the read-only incremental value and its emitter.
One-shot resources start when their committed scope is initialized, and their
first successfully committed terminal completion wins.

```moonbit check
///|
priv enum ReadmeLocalMsg {
  ReadmeAdd
}

///|
fn readme_local_authoring(input_value : Val[Int]) -> Val[Node] {
  let (pure, pure_emit) = create_pure_state(0, update=(
    model,
    _message : ReadmeLocalMsg,
  ) => model + 1)
  let (state, state_emit) = create_state(0, update=(
    model,
    _message : ReadmeLocalMsg,
    _emit,
  ) => with_cmds(model + 1, []))
  let (initialized, initialized_emit) = create_state_with_init(
    init=emit => (0, emit(ReadmeAdd)),
    update=(model, _message : ReadmeLocalMsg, _emit) => no_cmd(model + 1),
  )
  let (input_state, input_emit) = create_state_with_input(
    input=input_value,
    init=(_emit, input) => no_cmd(input),
    update=(model, input, _message : ReadmeLocalMsg, _emit) => {
      no_cmd(model + input)
    },
  )
  let (flag, set_flag) = create_variable(false)
  let resource = create_resource(done => done(Ok("ready")))
  Val::view6(pure, state, initialized, input_state, flag, resource, (
    a,
    b,
    c,
    d,
    enabled,
    status,
  ) => {
    let status_text = match status {
      Pending => "pending"
      Loaded(value) => value
      Failed(_) => "failed"
    }
    div([
      button(on_tap=pure_emit(ReadmeAdd), a.to_string()),
      button(on_tap=state_emit(ReadmeAdd), b.to_string()),
      button(on_tap=initialized_emit(ReadmeAdd), c.to_string()),
      button(on_tap=input_emit(ReadmeAdd), d.to_string()),
      button(on_tap=set_flag(value => !value), enabled.to_string()),
      p(status_text),
    ])
  })
}

///|
#warnings("-unused_value")
fn readme_local_page() -> Page {
  page(
    id="readme_local",
    route=route("pages/readme-local/readme-local"),
    title="Readme local",
    build=_ => readme_local_authoring(Val::constant(2)),
  )
}
```
