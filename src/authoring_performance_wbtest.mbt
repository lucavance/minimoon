///|
// Use the public Page/Val composition path, including command serialization.
fn changing_page(nodes : Int32) -> PageRuntime {
  let runtime = page(
      id="perf",
      route=route("pages/perf/perf"),
      title="Performance",
      build=_ => {
        let (value, emit) = create_pure_state(false, update=(value, _ : Unit) => {
          !value
        })
        value.view(value => {
          fragment(
            Array::makei(nodes - 2, index => {
              if index == 0 {
                button(
                  on_tap=emit(()),
                  event_key="toggle",
                  if value {
                    "value-B"
                  } else {
                    "value-A"
                  },
                )
              } else {
                text("stable-" + index.to_string())
              }
            }),
          )
        })
      },
    )
    .create_runtime()
    .unwrap()
  ignore(runtime.lifecycle("onLoad", "{}"))
  ignore(runtime.mount())
  runtime
}

///|
fn bench_changing_page(b : @bench.T, nodes : Int32) -> Unit {
  let runtime = changing_page(nodes)
  defer ignore(runtime.dispose())
  b.bench(fn() { b.keep(runtime.dispatch("toggle", "{}")) })
  let summaries : Json = @json.parse(b.dump_summaries()) catch {
    _ => abort("invalid benchmark summary")
  }
  println(
    "MINIMOON_PERF " +
    Json::object({
      "scenario": Json::string("page-update"),
      "nodes": Json::number(nodes.to_double()),
      "summaries": summaries,
    }).stringify(),
  )
}

///|
test "actual Page Val update 100 nodes" (b : @bench.T) {
  bench_changing_page(b, 100)
}

///|
test "actual Page Val update 500 nodes" (b : @bench.T) {
  bench_changing_page(b, 500)
}

///|
test "actual Page Val update 2000 nodes" (b : @bench.T) {
  bench_changing_page(b, 2000)
}

///|
test "actual update benchmarks change one fixed-width value and serialize a patch" {
  fn count_nodes(value : Json) -> Int32 {
    match value {
      Object(fields) =>
        match fields.get("children") {
          Some(Array(children)) =>
            1 + children.fold(init=0, (sum, child) => sum + count_nodes(child))
          _ => abort("missing normalized children")
        }
      _ => abort("expected normalized node")
    }
  }
  let tree = fn(runtime : PageRuntime) -> String raise {
    match @json.parse(runtime.snapshot()) {
      Object(fields) => fields["tree"].stringify()
      _ => abort("expected snapshot object")
    }
  }
  for nodes in [100, 500, 2000] {
    let runtime = changing_page(nodes)
    let before = tree(runtime)
    assert_eq(count_nodes(@json.parse(before)), nodes)
    let command = runtime.dispatch("toggle", "{}")
    let after = tree(runtime)
    assert_true(command.contains("PatchViewTree"))
    assert_eq(after, before.replace_all(old="value-A", new="value-B"))
    assert_eq(after.length(), before.length())
    ignore(runtime.dispatch("toggle", "{}"))
    assert_eq(tree(runtime), before)
    ignore(runtime.dispose())
    assert_eq(runtime.dispatch("toggle", "{}"), "[]")
  }
}

///|
struct QueueScenario {
  app : AppRuntime[(Shared[Int32], Emit[Int32])]
  pages : Array[PageRuntime]
  send : (Int32) -> Cmd
}

///|
fn queue_scenario(
  page_count : Int32,
  received? : Array[Int32],
) -> QueueScenario {
  let app = app(build=context => {
    context.create_pure_state(0, update=(value, msg : Int32) => {
      if received is Some(values) {
        values.push(msg)
      }
      (value + msg) % 1000003
    })
  }).create_runtime()
  ignore(app.lifecycle("onLaunch", "{}"))
  let deps = app.deps()
  let message = Ref(0)
  let pages = Array::makei(page_count, index => {
    let id = "queue_" + index.to_string()
    let page = app
      .create_page(
        page(id~, route=route("pages/" + id + "/" + id), title=id, build=context => {
          context
          .bind(deps.0)
          .view(value => {
            div([
              text("sum:" + value.to_string()),
              button(
                on_tap=Cmd(
                  @val.CmdEffect((send, finish) => {
                    send((deps.1)(message.val).0)
                    finish()
                    fn() { () }
                  }),
                ),
                event_key="send",
                "Send",
              ),
            ])
          })
        }),
      )
      .unwrap()
    ignore(page.lifecycle("onLoad", "{}"))
    ignore(page.mount())
    page
  })
  // Enqueue through a page event so all messages remain pending until App.flush.
  {
    app,
    pages,
    send: value => {
      message.val = value
      none
    },
  }
}

///|
fn QueueScenario::enqueue(self : QueueScenario, messages : Int32) -> Unit {
  for index in 0..<messages {
    ignore((self.send)(index))
    ignore(self.pages[0].dispatch("send", "{}"))
  }
}

///|
fn QueueScenario::drain(self : QueueScenario) -> Int32 {
  let mut drains = 0
  while self.app.has_ready_work() {
    ignore(self.app.flush())
    drains += 1
  }
  drains
}

///|
fn bench_queue(b : @bench.T, messages : Int32, pages : Int32) -> Unit {
  let scenario = queue_scenario(pages)
  defer ignore(scenario.app.dispose())
  let enqueue = Ref(0.0)
  let drain = Ref(0.0)
  let projection = Ref(0.0)
  let samples = Ref(0)
  let drains = Ref(0)
  b.bench(count=10U, fn() {
    let start = @bench.monotonic_clock_start()
    scenario.enqueue(messages)
    enqueue.val += @bench.monotonic_clock_end(start)
    let start = @bench.monotonic_clock_start()
    drains.val += scenario.drain()
    drain.val += @bench.monotonic_clock_end(start)
    let start = @bench.monotonic_clock_start()
    for page in scenario.pages {
      b.keep(page.refresh())
    }
    projection.val += @bench.monotonic_clock_end(start)
    samples.val += 1
  })
  println(
    "MINIMOON_PERF " +
    Json::object({
      "scenario": Json::string("application-queue"),
      "messages": Json::number(messages.to_double()),
      "pages": Json::number(pages.to_double()),
      "samples": Json::number(samples.val.to_double()),
      "drains": Json::number(drains.val.to_double()),
      "enqueueUs": Json::number(enqueue.val / samples.val.to_double()),
      "drainUs": Json::number(drain.val / samples.val.to_double()),
      "projectionUs": Json::number(projection.val / samples.val.to_double()),
    }).stringify(),
  )
}

///|
test "App queue 100 messages 1 page" (b : @bench.T) {
  bench_queue(b, 100, 1)
}

///|
test "App queue 100 messages 4 pages" (b : @bench.T) {
  bench_queue(b, 100, 4)
}

///|
test "App queue 3000 messages 1 page" (b : @bench.T) {
  bench_queue(b, 3000, 1)
}

///|
test "App queue 3000 messages 4 pages" (b : @bench.T) {
  bench_queue(b, 3000, 4)
}

///|
test "App queue 10000 messages 1 page" (b : @bench.T) {
  bench_queue(b, 10000, 1)
}

///|
test "App queue 10000 messages 4 pages" (b : @bench.T) {
  bench_queue(b, 10000, 4)
}

///|
test "queue scenarios preserve FIFO bounded drains projections hidden catchup and disposal" {
  for messages in [100, 3000, 10000] {
    for pages in [1, 4] {
      let received : Array[Int32] = []
      let scenario = queue_scenario(pages, received~)
      defer ignore(scenario.app.dispose())
      if pages == 4 {
        ignore(scenario.pages[3].lifecycle("onHide", "{}"))
      }
      scenario.enqueue(messages)
      assert_eq(scenario.app.driver.owner.pending_count(), messages)
      assert_eq(scenario.drain(), (messages + 2047) / 2048)
      assert_eq(received, Array::makei(messages, index => index))
      let expected = "sum:" +
        (messages * (messages - 1) / 2 % 1000003).to_string()
      for index, page in scenario.pages {
        ignore(page.refresh())
        if index == 3 {
          assert_true(page.snapshot().contains("sum:0"))
          ignore(page.lifecycle("onShow", "{}"))
        }
        assert_true(page.snapshot().contains(expected))
        ignore(page.dispose())
      }
      assert_eq(scenario.app.driver.owner.page_count(), 0)
      assert_eq(scenario.app.driver.owner.pending_count(), 0)
    }
  }
}
