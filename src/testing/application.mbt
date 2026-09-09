///|
/// An application-owned test session. Pages mounted through it share the real
/// AppRuntime and remain independently visible until explicitly hidden/disposed.
struct TestApp[Deps] {
  runtime : @minimoon.AppRuntime[Deps]
  pages : Array[TestRuntime]
  disposed : Ref[Bool]
}

///|
priv struct ReadyOwner {
  name : String
  ready : () -> Bool
  flush : () -> String
}

///|
fn require_success(commands : String, owner : String) -> Unit raise {
  let commands = @json.parse(commands) catch {
    error =>
      raise Failure(
        owner + " returned invalid command JSON: " + error.to_string(),
      )
  }
  guard commands is Array(commands) else {
    raise Failure(owner + " returned a non-array command result")
  }
  for command in commands {
    if string_field(command, "type") == Some("RuntimeError") {
      raise Failure(
        owner +
        " failed: " +
        string_field(command, "code").unwrap_or("runtime_error") +
        ": " +
        string_field(command, "message").unwrap_or("unknown runtime failure"),
      )
    }
  }
}

///|
/// A step is one fair drain round across all currently ready owners. Empty
/// command output is not a stability signal: pure state work may emit no JSON.
fn drain_ready(owners : Array[ReadyOwner], max_steps : Int) -> Unit raise {
  guard max_steps > 0 else {
    raise Failure("quiesce max_steps must be positive")
  }
  for _step = 0; _step < max_steps; _step = _step + 1 {
    if owners.all(owner => !(owner.ready)()) {
      return
    }
    for owner in owners {
      if (owner.ready)() {
        require_success((owner.flush)(), owner.name)
      }
    }
  }
  let pending = owners.filter(owner => (owner.ready)()).map(owner => owner.name)
  if !pending.is_empty() {
    raise Failure(
      "quiesce exceeded " +
      max_steps.to_string() +
      " drain steps; pending owners: " +
      pending.join(", "),
    )
  }
}

///|
fn page_ready_owner(page : TestRuntime, name : String) -> ReadyOwner {
  {
    name,
    ready: () => !page.disposed.val && page.runtime.has_ready_work(),
    flush: () => page.runtime.flush(),
  }
}

///|
fn start_page(
  runtime : @minimoon.PageRuntime,
  input : Map[String, String],
) -> Unit raise {
  let owner = "page " + runtime.page_id()
  require_success(
    runtime.lifecycle(
      "onLoad",
      Json::object(input.map((_, value) => Json::string(value))).stringify(),
    ),
    owner + " onLoad",
  )
  require_success(runtime.lifecycle("onShow", "{}"), owner + " onShow")
  // The generated host's onReady entry calls mount; there is no synthetic
  // onReady lifecycle hook in the authoring protocol.
  require_success(runtime.mount(), owner + " onReady/mount")
}

///|
/// Mount a standalone page with real Load -> Show -> host Ready ordering.
/// Input decoding failures and runtime diagnostics become ordinary test errors.
pub fn mount(
  page : @minimoon.Page,
  input? : Map[String, String] = Map([]),
  layout? : @minimoon.PageLayout = @minimoon.PageLayout::unavailable(),
) -> TestRuntime raise {
  let input = input.copy()
  let runtime = match page.create_runtime(input~, layout~) {
    Ok(runtime) => runtime
    Err(error) =>
      raise Failure("cannot mount page " + page.id() + ": " + error.message())
  }
  let disposed = Ref(false)
  let result = {
    runtime,
    disposed,
    settle: max_steps => {
      drain_ready(
        [
          {
            name: "page " + runtime.page_id(),
            ready: () => !disposed.val && runtime.has_ready_work(),
            flush: () => runtime.flush(),
          },
        ],
        max_steps,
      )
    },
  }
  errdefer ignore(result.dispose())
  start_page(runtime, input)
  result.quiesce()
  result
}

///|
/// Launch and show an application, draining only work that is already ready.
/// This does not resolve host requests, advance timers or wait for networking.
pub fn[Deps] launch(app : @minimoon.App[Deps]) -> TestApp[Deps] raise {
  let result = TestApp::{
    runtime: app.create_runtime(),
    pages: [],
    disposed: Ref(false),
  }
  errdefer ignore(result.dispose())
  require_success(result.runtime.lifecycle("onLaunch", "{}"), "App onLaunch")
  require_success(result.runtime.lifecycle("onShow", "{}"), "App onShow")
  result.quiesce()
  result
}

///|
/// Build the page from this application's real dependencies. Mounting another
/// page does not hide previous pages; navigation visibility remains explicit.
pub fn[Deps] TestApp::mount(
  self : TestApp[Deps],
  factory : (Deps) -> @minimoon.Page,
  input? : Map[String, String] = Map([]),
  layout? : @minimoon.PageLayout = @minimoon.PageLayout::unavailable(),
) -> TestRuntime raise {
  guard !self.disposed.val else {
    raise Failure("cannot mount a page on a disposed TestApp")
  }
  let input = input.copy()
  let page = factory(self.runtime.deps())
  let runtime = match self.runtime.create_page(page, input~, layout~) {
    Ok(runtime) => runtime
    Err(error) =>
      raise Failure(
        "cannot mount App page " + page.id() + ": " + error.message(),
      )
  }
  let result = TestRuntime::{
    runtime,
    disposed: Ref(false),
    settle: max_steps => self.quiesce(max_steps~),
  }
  self.pages.push(result)
  errdefer ignore(result.dispose())
  start_page(runtime, input)
  result.quiesce()
  result
}

///|
/// Drain current ready work; an App-owned page settles the entire TestApp.
pub fn TestRuntime::quiesce(
  self : TestRuntime,
  max_steps? : Int = 1024,
) -> Unit raise {
  (self.settle)(max_steps)
}

///|
pub fn[Deps] TestApp::quiesce(
  self : TestApp[Deps],
  max_steps? : Int = 1024,
) -> Unit raise {
  let owners : Array[ReadyOwner] = [
    {
      name: "App",
      ready: () => !self.disposed.val && self.runtime.has_ready_work(),
      flush: () => self.runtime.flush(),
    },
  ]
  for index, page in self.pages {
    owners.push(
      page_ready_owner(
        page,
        "page " + page.page_id() + " (#" + (index + 1).to_string() + ")",
      ),
    )
  }
  drain_ready(owners, max_steps)
}

///|
/// Dispose mounted pages and the App exactly once. Use the low-level
/// AppRuntime when inspecting host cancellation commands.
pub fn[Deps] TestApp::dispose(self : TestApp[Deps]) -> Unit {
  if self.disposed.val {
    return
  }
  self.disposed.val = true
  for page in self.pages {
    ignore(page.dispose())
  }
  // Page settle callbacks retain this TestApp; release our reverse references.
  self.pages.clear()
  ignore(self.runtime.dispose())
}
