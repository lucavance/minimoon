///|
// Deliberately has no Eq implementation: route inputs are immutable snapshots,
// not reactive slots. Only the state constructed from them needs equality.
priv struct RequiredPageInput {
  value : String
}

///|
test "page definition is inert and required input previews never decode or run commands" {
  let previews = Ref(0)
  let decodes = Ref(0)
  let builds = Ref(0)
  let starts = Ref(0)
  let definition = page_with_input(
    id="required_input",
    route=route("pages/required_input/required_input"),
    title="Required input",
    preview_input=fn() {
      previews.val += 1
      RequiredPageInput::{ value: "preview", }
    },
    decode_input=fields => {
      decodes.val += 1
      match fields.get("id") {
        Some(value) => Ok(RequiredPageInput::{ value, })
        None => Err(decode_error("id is required"))
      }
    },
    build=(_, input) => {
      builds.val += 1
      let (value, _) = create_state_with_init(
        init=_ => {
          (
            input.value,
            Cmd(
              @val.CmdEffect((_send, finish) => {
                starts.val += 1
                finish()
                fn() { () }
              }),
            ),
          )
        },
        update=(_, next : String, _) => (next, none),
      )
      value.view(text)
    },
  )
  assert_eq((previews.val, decodes.val, builds.val, starts.val), (0, 0, 0, 0))
  assert_true(definition.initial_tree().stringify().contains("preview"))
  assert_true(definition.contract().contains("preview"))
  ignore(definition.contract_json())
  ignore(definition.wxml())
  assert_eq((previews.val, decodes.val, builds.val, starts.val), (4, 0, 4, 0))
  assert_true(
    definition.create_runtime() is Err(error) &&
    error.message() == "id is required",
  )
  assert_eq((decodes.val, builds.val, starts.val), (1, 4, 0))
  let runtime = definition.create_runtime(input={ "id": "actual" }).unwrap()
  assert_eq((decodes.val, builds.val, starts.val), (2, 5, 0))
  assert_true(runtime.snapshot().contains("actual"))
  let load = runtime.lifecycle("onLoad", "{\"id\":\"actual\"}")
  assert_true(load.contains("ReplaceViewTree"))
  assert_true(load.contains("\"base_revision\":0"))
  assert_true(load.contains("\"revision\":1"))
  assert_eq(starts.val, 0)
  ignore(runtime.lifecycle("onShow", "{}"))
  assert_eq(starts.val, 0)
  ignore(runtime.mount())
  assert_eq(starts.val, 1)
  assert_eq(runtime.mount(), "[]")
  assert_eq(starts.val, 1)
  assert_true(
    runtime
    .lifecycle("onLoad", "{\"id\":\"different\"}")
    .contains("duplicate_page_load"),
  )
  assert_eq((decodes.val, builds.val, starts.val), (2, 5, 1))
  ignore(runtime.dispose())
}

///|
test "page input is snapshotted and every interaction waits for matching load" {
  let runtime = page_with_input(
    id="input_snapshot",
    route=route("pages/input_snapshot/input_snapshot"),
    title="Snapshot",
    preview_input=() => "preview",
    decode_input=fields => {
      let value = fields.get("id").unwrap_or("missing")
      // A decoder cannot mutate the independently retained Load snapshot.
      fields["id"] = "decoder mutation"
      Ok(value)
    },
    build=(_, input) => Val::constant(text(input)),
  )
  let input = { "id": "7" }
  let runtime = runtime.create_runtime(input~).unwrap()
  input["id"] = "caller mutation"
  assert_true(runtime.snapshot().contains("\"revision\":0"))
  assert_true(runtime.mount().contains("page_not_loaded"))
  assert_true(runtime.dispatch("", "{}").contains("page_not_loaded"))
  assert_true(runtime.dispatch_batch("[]").contains("page_not_loaded"))
  assert_true(runtime.lifecycle("onShow", "{}").contains("page_not_loaded"))
  assert_true(runtime.flush().contains("page_not_loaded"))
  assert_true(runtime.refresh().contains("page_not_loaded"))
  assert_true(runtime.subscription("clock", "{}").contains("page_not_loaded"))
  assert_true(
    runtime.resolve_effect("0", "success", "{}").contains("page_not_loaded"),
  )
  assert_eq(runtime.has_ready_work(), false)
  assert_true(runtime.lifecycle("onLoad", "{").contains("invalid_host_payload"))
  assert_true(
    runtime.lifecycle("onLoad", "[]").contains("page_input_decode_failed"),
  )
  assert_true(runtime.lifecycle("onLoad", "{}").contains("page_input_mismatch"))
  assert_true(runtime.snapshot().contains("\"revision\":0"))
  // Host numbers use the same string normalization as actual creation input.
  let loaded = runtime.lifecycle("onLoad", "{\"id\":7}")
  assert_true(loaded.contains("ReplaceViewTree"))
  assert_true(runtime.snapshot().contains("\"revision\":1"))
  assert_eq(runtime.flush(), "[]")
  ignore(runtime.dispose())
  assert_eq(runtime.mount(), "[]")
  assert_eq(runtime.lifecycle("onLoad", "{}"), "[]")
  assert_eq(runtime.flush(), "[]")
  assert_eq(runtime.has_ready_work(), false)
}

///|
test "invalid application page input never constructs or registers a page graph" {
  let builds = Ref(0)
  let app = shared_counter_app().create_runtime()
  let definition = page_with_input(
    id="app_required_input",
    route=route("pages/app_required_input/app_required_input"),
    title="Required App input",
    preview_input=() => "preview",
    decode_input=fields => {
      match fields.get("id") {
        Some(value) => Ok(value)
        None => Err(decode_error("id is required"))
      }
    },
    build=(context, input) => {
      builds.val += 1
      context.bind(app.deps().0).view(value => text(input + value.to_string()))
    },
  )
  assert_true(app.create_page(definition) is Err(_))
  assert_eq(builds.val, 0)
  assert_eq(app.driver.owner.page_count(), 0)
  let page = app.create_page(definition, input={ "id": "actual" }).unwrap()
  assert_eq(builds.val, 1)
  assert_eq(app.driver.owner.page_count(), 1)
  ignore(app.dispose())
  assert_eq(page.lifecycle("onLoad", "{\"id\":\"actual\"}"), "[]")
  assert_eq(page.has_ready_work(), false)
}

///|
test "page flush drains ready completions but excludes unresolved local effects" {
  let callback : Ref[((@val.Cmd) -> Unit)?] = Ref(None)
  let address : Ref[Emit[Int]?] = Ref(None)
  let definition = page(
    id="ready_work",
    route=route("pages/ready_work/ready_work"),
    title="Ready work",
    build=_ => {
      let (value, emit) = create_state_with_init(
        init=emit => {
          address.val = Some(emit)
          (
            0,
            Cmd(
              @val.CmdEffect((send, _finish) => {
                callback.val = Some(send)
                fn() { () }
              }),
            ),
          )
        },
        update=(value : Int, delta : Int, _) => (value + delta, none),
      )
      value.view(value => button(on_tap=emit(1), value.to_string()))
    },
  )
  let runtime = definition.create_runtime().unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  assert_eq(runtime.has_ready_work(), false)
  callback.val.unwrap()(address.val.unwrap()(3).0)
  assert_eq(runtime.has_ready_work(), true)
  assert_true(runtime.flush().contains("PatchViewTree"))
  assert_true(runtime.snapshot().contains("\"text\":\"3\""))
  assert_eq(runtime.has_ready_work(), false)
  ignore(runtime.dispose())
  callback.val.unwrap()(address.val.unwrap()(5).0)
  assert_eq(runtime.has_ready_work(), false)
  assert_eq(runtime.flush(), "[]")
}
