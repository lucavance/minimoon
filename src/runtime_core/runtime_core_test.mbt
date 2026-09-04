///|
enum RuntimeMsg {
  Increment
  Decrement
  IncrementThenDecrement
  StartEffect
  NavigateOnly
} derive(Eq)

///|
fn runtime_component(initial : Int) -> Component[Int, RuntimeMsg] {
  checked_component(
    model=initial,
    update=(model, msg) => {
      match msg {
        Increment => no_cmd(model + 1)
        Decrement => no_cmd(model - 1)
        IncrementThenDecrement =>
          with_cmds(model, [message(Increment), message(Decrement)])
        StartEffect =>
          with_cmd(
            model + 1,
            host_effect(host_effect_request("custom.echo", "{\"value\":1}"), _ => {
              Decrement
            }),
          )
        NavigateOnly => with_cmd(model, navigate_to_cmd("/pages/next/next"))
      }
    },
    view=(model, _emit) => @ui.text(model.to_string()),
    project=model => Ok("{\"count\":" + model.to_string() + "}"),
  )
}

///|
test "runtime command queue flushes one ordered batch" {
  let flushes : Ref[Array[Array[RuntimeCommand]]] = Ref([])
  let queue = RuntimeCommandQueue::new(commands => flushes.val.push(commands))
  queue.batch(fn() {
    queue.push(mount_context("counter"))
    queue.push(replace_view_tree("counter", "{\"count\":0}"))
  })
  assert_eq(flushes.val.length(), 1)
  assert_eq(flushes.val[0].length(), 2)
  assert_eq(flushes.val[0][0].describe(), "MountContext(counter)")
  assert_eq(queue.pending_count(), 0)
}

///|
test "runtime commands encode the resident host protocol" {
  let commands = [
    mount_context("counter"),
    replace_view_tree("counter", "{\"count\":1}"),
    navigate_to_command("/pages/details/details"),
    navigate_back_command(1),
    dispose_context("counter"),
  ]
  for command in commands {
    assert_eq(command.schema_json_size(), command.schema_json().length())
  }
  for
    command in [
      redirect_to_command("/pages/home/home"),
      emit_host_event("counter", "tap", "{}"),
    ] {
    assert_eq(command.schema_json_size(), command.schema_json().length())
  }
  inspect(
    runtime_commands_json(commands),
    content="[{\"type\":\"MountContext\",\"component_id\":\"counter\"},{\"type\":\"ReplaceViewTree\",\"component_id\":\"counter\",\"base_revision\":0,\"revision\":1,\"tree\":{\"count\":1}},{\"type\":\"NavigateTo\",\"url\":\"/pages/details/details\"},{\"type\":\"NavigateBack\",\"delta\":1},{\"type\":\"DisposeContext\",\"component_id\":\"counter\"}]",
  )
}

///|
test "runtime command diagnostics summarize patch and lifecycle traffic" {
  let ops = "[{\"op\":\"set\",\"path\":[\"text\"],\"value\":\"A\"}]"
  let diagnostics = runtime_command_diagnostics([
    mount_context("todos"),
    patch_view_tree("todos", ops),
    emit_host_event("todos", "tap", "{}"),
    dispose_context("todos"),
  ])
  assert_eq(diagnostics.command_count, 4)
  assert_eq(diagnostics.state_update_count, 1)
  assert_eq(diagnostics.event_count, 1)
  assert_eq(diagnostics.lifecycle_count, 2)
  assert_eq(diagnostics.warning, "")
}

///|
test "running component mounts and executes follow-up messages atomically" {
  let batches : Ref[Array[Array[RuntimeCommand]]] = Ref([])
  let queue = RuntimeCommandQueue::new(commands => batches.val.push(commands))
  let running = runtime_component(0)
    .with_model(10)
    .run_host(component_id="counter", queue~)
  assert_eq(running.context().id(), "counter")
  assert_eq(running.render_to_string(), "10")
  assert_true(running.mount().is_ok())
  assert_true(running.dispatch(IncrementThenDecrement).is_ok())
  assert_eq(running.model(), 10)
  assert_eq(batches.val.length(), 2)
  assert_eq(batches.val[1].length(), 3)
  assert_true(running.dispose().is_ok())
  assert_true(running.dispatch(Increment).is_disposed())
}

///|
test "invalid projection rolls back the model" {
  let batches : Ref[Array[Array[RuntimeCommand]]] = Ref([])
  let queue = RuntimeCommandQueue::new(commands => batches.val.push(commands))
  let component = checked_component(
    model=0,
    update=(model, _msg : Unit) => no_cmd(model + 1),
    view=(model, _emit) => @ui.text(model.to_string()),
    project=model => if model > 0 { Err("invalid") } else { Ok("{}") },
  )
  let running = component.run_host(component_id="rollback", queue~)
  let _ = running.mount()
  let _ = running.dispatch(())
  assert_eq(running.model(), 0)
  assert_true(batches.val[1][0].describe().contains("invalid_view"))
}

///|
test "projection guard skips equal state while commands still run" {
  let batches : Ref[Array[Array[RuntimeCommand]]] = Ref([])
  let projections = Ref(0)
  let queue = RuntimeCommandQueue::new(commands => batches.val.push(commands))
  let component = checked_component(
    model=0,
    update=(model, msg : RuntimeMsg) => {
      match msg {
        NavigateOnly => with_cmd(model, navigate_to_cmd("/pages/next/next"))
        _ => no_cmd(model + 1)
      }
    },
    view=(model, _emit) => @ui.text(model.to_string()),
    project=model => {
      projections.val += 1
      Ok(model.to_string())
    },
    projection_guard=(previous, next) => previous != next,
  )
  let running = component.run_host(component_id="guarded", queue~)
  let _ = running.mount()
  assert_eq(projections.val, 1)
  let _ = running.dispatch(NavigateOnly)
  assert_eq(projections.val, 1)
  assert_eq(batches.val[1].length(), 1)
  assert_eq(batches.val[1][0].describe(), "NavigateTo(/pages/next/next)")
}

///|
test "host effects resolve once and late results are suppressed" {
  let batches : Ref[Array[Array[RuntimeCommand]]] = Ref([])
  let queue = RuntimeCommandQueue::new(commands => batches.val.push(commands))
  let running = runtime_component(0).run_host(component_id="counter", queue~)
  let _ = running.mount()
  let _ = running.dispatch(StartEffect)
  assert_eq(running.model(), 1)
  assert_eq(running.pending_effect_count(), 1)
  assert_true(
    runtime_command_diagnostics(batches.val[1])
    .describe()
    .contains("effect:counter/counter:0/custom.echo"),
  )
  assert_eq(
    running.resolve_host_effect("counter:0", HostEffectOk("{}")),
    EffectResolved,
  )
  assert_eq(running.model(), 0)
  assert_eq(
    running.resolve_host_effect("counter:0", HostEffectOk("{}")),
    EffectUnknownRequest,
  )
  assert_eq(
    running.resolve_host_effect("counter:missing", HostEffectOk("{}")),
    EffectUnknownRequest,
  )
  let _ = running.dispatch(StartEffect)
  let _ = running.dispose()
  let cancellation_described = Ref(false)
  for batch in batches.val {
    if runtime_command_diagnostics(batch)
      .describe()
      .contains("effect_cancel:counter/counter:1") {
      cancellation_described.val = true
    }
  }
  assert_true(cancellation_described.val)
  assert_eq(
    running.resolve_host_effect("counter:1", HostEffectOk("{}")),
    EffectContextDisposed,
  )
}

///|
test "completed host effects retain no per-request tombstones" {
  let queue = RuntimeCommandQueue::new(_ => ())
  let running = runtime_component(0).run_host(component_id="bounded", queue~)
  let _ = running.mount()
  for sequence = 0; sequence < 4096; sequence = sequence + 1 {
    let _ = running.dispatch(StartEffect)
    assert_eq(running.pending_effect_count(), 1)
    assert_eq(
      running.resolve_host_effect(
        "bounded:" + sequence.to_string(),
        HostEffectOk("{}"),
      ),
      EffectResolved,
    )
    assert_eq(running.pending_effect_count(), 0)
  }
  assert_eq(running.model(), 0)
  assert_eq(
    running.resolve_host_effect("bounded:4095", HostEffectOk("{}")),
    EffectUnknownRequest,
  )
  assert_eq(running.pending_effect_count(), 0)
}

///|
enum OwnedEffectMsg {
  StartOwnedEffect
  StartSynchronousOwnedEffect
  OwnedEffectIncrement
  OwnedEffectAppend(Int)
} derive(Eq)

///|
enum ReentrantCancelMsg {
  StartReentrantCancel
  ReentrantCancelPublished
} derive(Eq)

///|
test "local effects are page-owned, wake after emits, and cancel on dispose" {
  let saved_emit : Ref[((OwnedEffectMsg) -> Unit)?] = Ref(None)
  let saved_finish : Ref[(() -> Unit)?] = Ref(None)
  let cancellations = Ref(0)
  let wakes = Ref(0)
  let wake_sequences : Array[Int] = []
  let component = checked_component(
    model=0,
    update=(model, msg) => {
      match msg {
        StartOwnedEffect =>
          with_cmd(
            model,
            local_effect((emit, finish) => {
              saved_emit.val = Some(emit)
              saved_finish.val = Some(finish)
              fn() { cancellations.val += 1 }
            }),
          )
        StartSynchronousOwnedEffect =>
          with_cmd(
            model,
            local_effect((emit, finish) => {
              emit(OwnedEffectIncrement)
              finish()
              fn() { cancellations.val += 100 }
            }),
          )
        OwnedEffectIncrement => no_cmd(model + 1)
        OwnedEffectAppend(value) => no_cmd(model * 10 + value)
      }
    },
    view=(model, _emit) => @ui.text(model.to_string()),
    project=model => Ok(model.to_string()),
  )
  let queue = RuntimeCommandQueue::new(_ => ())
  let running = component.run_host(component_id="owned", queue~, wake_async=fn(
    sequence,
  ) {
    wakes.val += 1
    wake_sequences.push(sequence)
  })
  let _ = running.mount()
  let _ = running.dispatch(StartSynchronousOwnedEffect)
  assert_eq(running.model(), 1)
  assert_eq(running.pending_local_effect_count(), 0)
  assert_eq(wakes.val, 0)
  assert_eq(cancellations.val, 0)
  let _ = running.dispatch(StartOwnedEffect)
  assert_eq(running.pending_local_effect_count(), 1)
  saved_emit.val.unwrap()(OwnedEffectAppend(2))
  saved_emit.val.unwrap()(OwnedEffectAppend(3))
  assert_eq(running.model(), 1)
  assert_eq(running.pending_local_message_count(), 2)
  assert_eq(wakes.val, 2)
  assert_eq(wake_sequences, [1, 2])
  saved_finish.val.unwrap()()
  assert_eq(running.pending_local_effect_count(), 0)
  assert_true(running.drain_local_messages(through=1).is_ok())
  assert_eq(running.model(), 12)
  assert_eq(running.pending_local_message_count(), 1)
  assert_true(running.drain_local_messages(through=2).is_ok())
  assert_eq(running.model(), 123)
  assert_eq(running.pending_local_message_count(), 0)
  saved_emit.val.unwrap()(OwnedEffectAppend(4))
  assert_eq(running.model(), 123)
  assert_eq(wakes.val, 2)

  let _ = running.dispatch(StartOwnedEffect)
  assert_eq(running.pending_local_effect_count(), 1)
  saved_emit.val.unwrap()(OwnedEffectAppend(4))
  assert_eq(running.pending_local_message_count(), 1)
  assert_eq(wakes.val, 3)
  assert_eq(wake_sequences, [1, 2, 3])
  assert_true(running.dispose().is_ok())
  assert_eq(cancellations.val, 1)
  assert_eq(running.pending_local_effect_count(), 0)
  assert_eq(running.pending_local_message_count(), 0)
  saved_emit.val.unwrap()(OwnedEffectAppend(5))
  assert_eq(running.model(), 123)
  assert_eq(wakes.val, 3)
  assert_true(running.drain_local_messages(through=3).is_disposed())
  assert_eq(running.model(), 123)
  assert_true(running.dispose().is_disposed())
  assert_eq(cancellations.val, 1)
}

///|
test "local effect cancellation suppresses reentrant emit and finish" {
  let cancellations = Ref(0)
  let wakes = Ref(0)
  let component = checked_component(
    model=0,
    update=(model, msg) => {
      match msg {
        StartReentrantCancel =>
          with_cmd(
            model,
            local_effect((emit, finish) => {
              fn() {
                cancellations.val += 1
                emit(ReentrantCancelPublished)
                finish()
              }
            }),
          )
        ReentrantCancelPublished => no_cmd(model + 1)
      }
    },
    view=(model, _emit) => @ui.text(model.to_string()),
    project=model => Ok(model.to_string()),
  )
  let queue = RuntimeCommandQueue::new(_ => ())
  let running = component.run_host(component_id="reentrant-cancel", queue~, wake_async=_ => {
    wakes.val += 1
  })
  let _ = running.mount()
  let _ = running.dispatch(StartReentrantCancel)
  assert_eq(running.pending_local_effect_count(), 1)
  assert_true(running.dispose().is_ok())
  assert_eq(cancellations.val, 1)
  assert_eq(running.model(), 0)
  assert_eq(running.pending_local_effect_count(), 0)
  assert_eq(running.pending_local_message_count(), 0)
  assert_eq(wakes.val, 0)
  assert_true(running.dispose().is_disposed())
  assert_eq(cancellations.val, 1)
  assert_eq(running.model(), 0)
  assert_eq(wakes.val, 0)
}

///|
test "component context owns cleanup and rejects late writes" {
  let batches : Ref[Array[Array[RuntimeCommand]]] = Ref([])
  let queue = RuntimeCommandQueue::new(commands => batches.val.push(commands))
  let context = ComponentContext::new("counter", queue)
  assert_eq(context.id(), "counter")
  assert_true(context.lifecycle_state() is ComponentCreated)
  assert_true(context.mount().is_ok())
  assert_true(context.mount().is_ok())
  assert_true(context.lifecycle_state() is ComponentMounted)
  assert_true(context.emit_event("tap", "{}").is_ok())
  let cleaned = Ref(0)
  let _ = context.on_cleanup(fn() { cleaned.val = cleaned.val + 1 })
  let _ = context.on_cleanup(fn() { cleaned.val = cleaned.val + 1 })
  assert_true(context.dispose().is_ok())
  assert_eq(cleaned.val, 2)
  assert_true(context.update_state("{}").is_disposed())
  assert_true(context.dispose().is_disposed())
  assert_true(context.lifecycle_state() is ComponentDisposed)
  assert_true(context.on_cleanup(fn() {  }).is_disposed())
}

///|
test "command mapping preserves host effects and navigation" {
  let command : Cmd[Int] = cmd_batch([
    message(1),
    navigate_to_cmd("/pages/details/details"),
    navigate_back_or_redirect_cmd(1, "/pages/home/home"),
  ])
  match map_cmd(command, value => value.to_string()) {
    CmdBatch(commands) => {
      match commands[0] {
        CmdMessage("1") => ()
        _ => fail("mapped message missing")
      }
      guard commands[1] is CmdNavigateTo(_) else { fail("navigateTo missing") }
      guard commands[2] is CmdNavigateBackOrRedirect(_, _) else {
        fail("navigateBack fallback missing")
      }
    }
    _ => fail("mapped batch missing")
  }
}

///|
test "command helpers cover local effects and navigation" {
  let empty_command : Cmd[Int] = none()
  match map_cmd(empty_command, (value : Int) => value.to_string()) {
    CmdNone => ()
    _ => fail("mapped empty command missing")
  }
  let local_value = Ref("")
  match
    map_cmd(
      local_effect((emit, finish) => {
        emit(7)
        finish()
        fn() {  }
      }),
      value => "local:" + value.to_string(),
    ) {
    CmdLocalEffect(start) => {
      let _ = start(value => local_value.val = value, fn() {  })
    }
    _ => fail("mapped local effect missing")
  }
  assert_eq(local_value.val, "local:7")
  match
    map_cmd(host_effect(host_effect_request("custom.echo", "{}"), _ => 9), value => {
      "host:" + value.to_string()
    }) {
    CmdHostEffect(_, resolve) =>
      assert_eq(resolve(HostEffectOk("{}")), "host:9")
    _ => fail("mapped host effect missing")
  }
  let redirect_command : Cmd[Int] = redirect_to_cmd("/redirect")
  let back_command : Cmd[Int] = navigate_back_cmd(2)
  for
    command in [
      map_cmd(redirect_command, value => value.to_string()),
      map_cmd(back_command, value => value.to_string()),
    ] {
    match command {
      CmdRedirectTo(_) | CmdNavigateBack(_) => ()
      _ => fail("mapped navigation command missing")
    }
  }
  let (model, _) : (Int, Cmd[Unit]) = with_navigate_to(1, "/next")
  let (redirected, _) : (Int, Cmd[Unit]) = with_redirect_to(2, "/redirect")
  let (back, _) : (Int, Cmd[Unit]) = with_navigate_back(3, 1)
  assert_eq(model + redirected + back, 6)
}

///|
test "runtime diagnostics cover every host command family and warning level" {
  let commands = [
    replace_view_tree("page", "{}"),
    runtime_error("page", "invalid", "bad"),
    navigate_to_command("/next"),
    redirect_to_command("/redirect"),
    navigate_back_command(2),
    navigate_back_or_redirect_command(1, "/home"),
    start_subscription_command("page", "clock", 1000),
    stop_subscription_command("page", "clock"),
  ]
  let descriptions = commands.map(command => command.describe()).join("|")
  assert_true(descriptions.contains("ReplaceViewTree(page, 0->1, {})"))
  assert_true(descriptions.contains("RedirectTo(/redirect)"))
  assert_true(descriptions.contains("NavigateBackOrRedirect(1, /home)"))
  assert_true(descriptions.contains("StartSubscription(page, clock, 1000)"))
  let diagnostics = runtime_command_diagnostics(commands)
  assert_eq(diagnostics.effect_count, 0)
  assert_true(diagnostics.breakdown.contains("navigate_back_or#1//home"))
  assert_true(diagnostics.describe().contains("commands=8"))

  let medium = runtime_command_diagnostics([
    replace_view_tree("page", String::make(256 * 1024, 'x')),
  ])
  assert_true(medium.describe().contains("at least 256KiB"))
  let large = runtime_command_diagnostics([
    replace_view_tree("page", String::make(1024 * 1024, 'x')),
  ])
  assert_true(large.describe().contains("at least 1MiB"))
}
