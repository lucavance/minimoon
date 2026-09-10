///|
priv struct Harness {
  app : @minimoon.AppRuntime[Deps]
  page : @minimoon.PageRuntime
  latest : Ref[Workbench]
  message : Ref[WorkMsg]
  launch : String
}

///|
fn harness() -> Harness {
  let app = program().create_runtime()
  let latest = Ref(initial_workbench())
  let message = Ref(Cancel)
  let deps = app.deps()
  let page = app
    .create_page(
      @minimoon.page(
        id="test",
        route=@minimoon.route("pages/test/test"),
        title="test",
        build=context => {
          let (_, tap) = @minimoon.create_state((), update=(_, _ : Unit, _) => {
            @minimoon.with_cmd((), (deps.send)(message.val))
          })
          context
          .bind(deps.work)
          .view(model => {
            latest.val = model
            @minimoon.button(on_tap=tap(()), event_key="step", "step")
          })
        },
      ),
    )
    .unwrap()
  ignore(page.lifecycle("onLoad", "{}"))
  ignore(page.lifecycle("onShow", "{}"))
  ignore(page.mount())
  let launch = app.lifecycle("onLaunch", "{}")
  { app, page, latest, message, launch, }
}

///|
fn Harness::step(self : Harness, message : WorkMsg) -> String {
  self.message.val = message
  ignore(self.page.dispatch("step", "{}"))
  let commands = self.app.flush()
  ignore(self.page.flush())
  commands
}

///|
fn request_id(commands : String, capability : String) -> String raise {
  guard @json.parse(commands) is Array(entries) else {
    fail("expected commands")
  }
  for entry in entries {
    if entry is Object(fields) &&
      fields.get("capability") == Some(Json::string(capability)) &&
      fields.get("request_id") is Some(String(id)) {
      return id
    }
  }
  fail("missing " + capability + ": " + commands)
}

///|
fn Harness::resolve(
  self : Harness,
  commands : String,
  capability : String,
  phase : String,
  payload : Json,
) -> Unit raise {
  ignore(
    self.app.resolve_effect(
      request_id(commands, capability),
      phase,
      payload.stringify(),
    ),
  )
  ignore(self.app.flush())
  ignore(self.page.flush())
}

///|
fn Harness::ready(self : Harness) -> Unit raise {
  self.resolve(self.launch, "wx.getStorage", "failure", {
    "error": "getStorage:fail data not found",
  })
  assert_true(self.latest.val.storage == Ready)
}

///|
fn Harness::close(self : Harness) -> Unit {
  ignore(self.page.dispose())
  ignore(self.app.dispose())
}

///|
fn Harness::save(self : Harness, title : String) -> Unit raise {
  ignore(self.step(Title(title)))
  let commands = self.step(Save)
  self.resolve(commands, "wx.setStorage", "success", {})
}

///|
test "local CRUD commits after success and restores only saved records on restart" {
  let h = harness()
  defer h.close()
  h.ready()
  h.save("  Weekend  ")
  assert_eq(h.latest.val.store.records.length(), 1)
  assert_eq(h.latest.val.store.records[0].draft.title, "Weekend")
  assert_false(dirty(h.latest.val.buffer))
  ignore(h.step(Note("unsaved")))
  let stored = h.latest.val.store.to_json()
  let reopened = harness()
  defer reopened.close()
  reopened.resolve(reopened.launch, "wx.getStorage", "success", {
    "data": stored,
  })
  ignore(reopened.step(Choose(Open(1))))
  assert_eq(reopened.latest.val.buffer.draft.note, "")
  reopened.save("Edited")
  assert_eq(reopened.latest.val.store.records.length(), 1)
  ignore(reopened.step(Choose(Delete(1))))
  let remove = reopened.step(Confirm)
  assert_eq(reopened.latest.val.store.records.length(), 1)
  reopened.resolve(remove, "wx.setStorage", "success", {})
  assert_true(reopened.latest.val.store.records.is_empty())
  assert_true(reopened.latest.val.buffer.id is None)
}

///|
test "validation counts Unicode characters and rejects invalid input without storage commands" {
  assert_true(validate({ title: " ", note: "", }) is Err(_))
  assert_true(
    validate({ title: "🌙".repeat(80), note: "文".repeat(2000), }) is Ok(_),
  )
  assert_true(validate({ title: "🌙".repeat(81), note: "", }) is Err(_))
  assert_true(validate({ title: "ok", note: "文".repeat(2001), }) is Err(_))
  let h = harness()
  defer h.close()
  h.ready()
  assert_false(h.step(Save).contains("wx.setStorage"))
  assert_true(h.latest.val.notice.contains("标题不能为空"))
}

///|
test "saving is single flight, failure preserves state and edits during save remain dirty" {
  let h = harness()
  defer h.close()
  h.ready()
  ignore(h.step(Title("first")))
  let first = h.step(Save)
  assert_true(h.latest.val.store.records.is_empty())
  assert_false(h.step(Save).contains("wx.setStorage"))
  ignore(h.step(Title("newer")))
  h.resolve(first, "wx.setStorage", "failure", { "error": "quota" })
  assert_true(h.latest.val.store.records.is_empty())
  assert_eq(h.latest.val.buffer.draft.title, "newer")
  assert_true(h.latest.val.notice.contains("失败"))
  let second = h.step(Save)
  ignore(h.step(Title("latest")))
  h.resolve(second, "wx.setStorage", "success", {})
  assert_eq(h.latest.val.store.records[0].draft.title, "newer")
  assert_eq(h.latest.val.buffer.draft.title, "latest")
  assert_true(dirty(h.latest.val.buffer))
  let before = h.latest.val
  h.resolve(second, "wx.setStorage", "failure", { "error": "duplicate" })
  assert_true(h.latest.val == before)
}

///|
test "unknown reads and malformed versions fail closed; initialize and clear require successful writes" {
  let h = harness()
  defer h.close()
  h.resolve(h.launch, "wx.getStorage", "failure", { "error": "permission" })
  assert_true(h.latest.val.storage == ReadFailed)
  assert_false(h.step(Save).contains("wx.setStorage"))
  let retry = h.step(Reload)
  h.resolve(retry, "wx.getStorage", "success", {
    "data": { "version": 99, "next_id": 1, "records": [] },
  })
  assert_true(h.latest.val.storage == ReadFailed)
  assert_false(h.step(Choose(Initialize)).contains("wx.setStorage"))
  let initialize = h.step(Confirm)
  h.resolve(initialize, "wx.setStorage", "failure", { "error": "quota" })
  assert_true(h.latest.val.storage == ReadFailed)
  ignore(h.step(Choose(Initialize)))
  let initialize = h.step(Confirm)
  h.resolve(initialize, "wx.setStorage", "success", {})
  assert_true(h.latest.val.storage == Ready)
  h.save("keep")
  for intent in [Delete(1), ClearAll] {
    ignore(h.step(Choose(intent)))
    let pending = h.step(Confirm)
    h.resolve(pending, "wx.setStorage", "failure", { "error": "quota" })
    assert_eq(h.latest.val.store.records.length(), 1)
    assert_eq(h.latest.val.buffer.draft.title, "keep")
  }
}

///|
test "restoration validates identity, version, record count and content" {
  for
    value in [
      Json::string("not a store"),
      {
        "version": 1,
        "next_id": 1,
        "records": [{ "id": 1, "draft": { "title": "bad id", "note": "" } }],
      },
      {
        "version": 1,
        "next_id": 2,
        "records": [{ "id": 1, "draft": { "title": "", "note": "" } }],
      },
      { "version": 2, "next_id": 1, "records": [] },
    ] {
    assert_true(decode_store(value) is Err(_))
  }
  let record : Record = { id: 1, draft: { title: "one", note: "", }, }
  assert_true(
    decode_store(
      ({ version: 1, next_id: 2, records: [record, record], } : Store).to_json(),
    )
    is Err(_),
  )
}

///|
test "unsaved switching requires confirmation; startup route selection waits for restoration" {
  let h = harness()
  defer h.close()
  ignore(h.step(Choose(Open(7))))
  let store : Store = {
    version: 1,
    next_id: 8,
    records: [{ id: 7, draft: { title: "restored", note: "", }, }],
  }
  h.resolve(h.launch, "wx.getStorage", "success", { "data": store.to_json() })
  assert_eq(h.latest.val.buffer.draft.title, "restored")
  ignore(h.step(Title("unsaved")))
  ignore(h.step(Choose(New)))
  assert_true(h.latest.val.confirm == Some(New))
  ignore(h.step(Cancel))
  assert_eq(h.latest.val.buffer.draft.title, "unsaved")
  ignore(h.step(Choose(New)))
  ignore(h.step(Confirm))
  assert_eq(h.latest.val.buffer.draft.title, "")
  assert_eq(h.latest.val.store.records.length(), 1)
}

///|
test "typed App echo is not persistence and stale completion cannot overwrite edits" {
  let h = harness()
  defer h.close()
  h.ready()
  ignore(h.step(Title("first")))
  let first = h.step(Send)
  assert_false(h.step(Send).contains("wx.request"))
  ignore(h.step(Title("second")))
  h.resolve(first, "wx.request", "success", {
    "statusCode": 200,
    "data": { "json": { "title": "first", "note": "" } },
  })
  assert_true(h.latest.val.echo.status == EchoOutdated)
  assert_eq(h.latest.val.buffer.draft.title, "second")
  let second = h.step(Send)
  h.resolve(second, "wx.request", "success", {
    "statusCode": 200,
    "data": { "json": { "title": "second", "note": "" }, "origin": "private" },
  })
  assert_true(h.latest.val.echo.status is EchoOk(_))
  assert_true(h.latest.val.store.records.is_empty())
  assert_true(dirty(h.latest.val.buffer))
  h.resolve(first, "wx.request", "failure", { "error": "late" })
  assert_true(h.latest.val.echo.status is EchoOk(_))
}

///|
test "HTTP, network, schema and mismatched echo failures support retry" {
  let h = harness()
  defer h.close()
  h.ready()
  ignore(h.step(Title("retry")))
  let cases : Array[(String, Json)] = [
    ("success", { "statusCode": 503, "data": "private" }),
    ("failure", { "error": "timeout" }),
    ("success", { "statusCode": 200, "data": { "json": { "title": 42 } } }),
    (
      "success",
      {
        "statusCode": 200,
        "data": { "json": { "title": "wrong", "note": "" } },
      },
    ),
  ]
  for (phase, response) in cases {
    let pending = h.step(Send)
    h.resolve(pending, "wx.request", phase, response)
    assert_true(h.latest.val.echo.status is EchoFailed(_))
    assert_true(h.latest.val.store.records.is_empty())
  }
}
