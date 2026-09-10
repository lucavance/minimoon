///|
struct ProbeTimer {
  due : Int
  resolve : (Unit) -> Unit
}

///|
struct ProbeClock {
  now : Ref[Int]
  timers : Ref[Array[ProbeTimer]]
}

///|
fn probe_clock() -> ProbeClock {
  { now: Ref(0), timers: Ref([]), }
}

///|
fn ProbeClock::schedule(
  self : ProbeClock,
  resolve : (Unit) -> Unit,
  milliseconds : Int,
) -> Unit {
  self.timers.val.push({ due: self.now.val + milliseconds, resolve, })
}

///|
fn ProbeClock::advance(self : ProbeClock, milliseconds : Int) -> Unit {
  let target = self.now.val + milliseconds
  let ready : Array[ProbeTimer] = []
  let pending : Array[ProbeTimer] = []
  for timer in self.timers.val {
    if timer.due <= target {
      ready.push(timer)
    } else {
      pending.push(timer)
    }
  }
  self.timers.val = pending
  self.now.val = target
  for timer in ready {
    (timer.resolve)(())
  }
}

///|
async fn flush_probe_microtasks() -> Unit {
  @async.pause()
  @async.pause()
}

///|
async test "lab perform and attempt probes finish at deterministic boundaries" {
  let clock = probe_clock()
  let runtime = program_with_probe_scheduler((resolve, milliseconds) => {
      clock.schedule(resolve, milliseconds)
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let started = runtime.dispatch("dynamic/start-async", "{}")
  inspect(started.contains("PatchViewTree"), content="true")
  inspect(
    runtime.snapshot().contains("perform probe:running:250ms"),
    content="true",
  )
  inspect(
    runtime.snapshot().contains("attempt probe:running:400ms"),
    content="true",
  )
  assert_eq(clock.timers.val.length(), 2)
  clock.advance(249)
  flush_probe_microtasks()
  assert_true(runtime.snapshot().contains("perform probe:running:250ms"))
  clock.advance(1)
  flush_probe_microtasks()
  let first = runtime.lifecycle("$minimoon:drain", "{\"through\":1}")
  assert_true(first.contains("PatchViewTree"))
  assert_true(
    runtime.snapshot().contains("perform probe:succeeded:250ms:ready"),
  )
  assert_true(runtime.snapshot().contains("attempt probe:running:400ms"))
  clock.advance(149)
  flush_probe_microtasks()
  assert_true(runtime.snapshot().contains("attempt probe:running:400ms"))
  clock.advance(1)
  flush_probe_microtasks()
  let second = runtime.lifecycle("$minimoon:drain", "{\"through\":2}")
  assert_true(second.contains("PatchViewTree"))
  let completed = runtime.snapshot()
  inspect(
    completed.contains("perform probe:succeeded:250ms:ready"),
    content="true",
  )
  inspect(
    completed.contains("attempt probe:failed:400ms:planned"),
    content="true",
  )
  inspect(completed.contains("unexpected:"), content="false")
  assert_eq(clock.timers.val.length(), 0)
  let _ = runtime.dispose()
}

///|
async test "disposed lab ignores suspended probe completions" {
  let clock = probe_clock()
  let runtime = program_with_probe_scheduler((resolve, milliseconds) => {
      clock.schedule(resolve, milliseconds)
    })
    .create_runtime()
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let _ = runtime.dispatch("dynamic/start-async", "{}")
  assert_eq(clock.timers.val.length(), 2)
  let _ = runtime.dispose()
  clock.advance(400)
  flush_probe_microtasks()
  assert_eq(clock.timers.val.length(), 0)
  let disposed = runtime.snapshot()
  inspect(disposed.contains("perform probe:running:250ms"), content="true")
  inspect(disposed.contains("attempt probe:running:400ms"), content="true")
  inspect(disposed.contains("perform probe:succeeded"), content="false")
  inspect(disposed.contains("attempt probe:failed"), content="false")
}
