///|
test "lab scopes component events and reconciles subscriptions" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let primary = "$component:toggle-card:cards:primary"
  let mount = runtime.mount()
  inspect(mount.contains("StartSubscription"), content="true")
  inspect(mount.contains("page-tick"), content="true")
  let enabled = runtime.dispatch(
    primary + "/enabled",
    "{\"detail\":{\"value\":true}}",
  )
  inspect(enabled.contains(primary + "/pulse"), content="true")
  inspect(enabled.contains("StartSubscription"), content="true")
  let pulse = runtime.subscription(primary + "/pulse", "{}")
  inspect(pulse.contains("component pulses: 1"), content="true")
  let disabled = runtime.dispatch(
    primary + "/enabled",
    "{\"detail\":{\"value\":false}}",
  )
  inspect(disabled.contains("StopSubscription"), content="true")
  inspect(runtime.snapshot().contains("\"kind\":\"switch\""), content="true")
  inspect(runtime.snapshot().contains("\"events\""), content="true")
  inspect(runtime.dispose().contains("StopSubscription"), content="true")
}

///|
test "lab keyed component reorder preserves identity and restarts lifecycle" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let secondary = "$component:toggle-card:cards:secondary"
  let _ = runtime.mount()
  let _ = runtime.dispatch(
    secondary + "/enabled",
    "{\"detail\":{\"value\":true}}",
  )
  let _ = runtime.dispatch(
    secondary + "/note",
    "{\"detail\":{\"value\":\"secondary note\"}}",
  )
  let _ = runtime.subscription(secondary + "/pulse", "{}")
  inspect(runtime.snapshot().contains("component pulses: 2"), content="true")
  inspect(runtime.snapshot().contains("secondary note"), content="true")
  inspect(
    runtime.dispatch("controls/reorder-cards", "{}").contains("PatchViewTree"),
    content="true",
  )
  let removed = runtime.dispatch("controls/remove-secondary", "{}")
  inspect(removed.contains("StopSubscription"), content="true")
  inspect(runtime.snapshot().contains("Secondary card"), content="false")
  let _ = runtime.dispatch("controls/restore-secondary", "{}")
  inspect(runtime.snapshot().contains("Secondary card"), content="true")
  inspect(runtime.snapshot().contains("component pulses: 2"), content="false")
  inspect(runtime.snapshot().contains("secondary note"), content="false")
}

///|
test "same-route page instances isolate component caches and disposal" {
  let first_app = @application.program().create_runtime()
  defer ignore(first_app.dispose())
  let first = first_app.create_page(program(first_app.deps())).unwrap()
  let _ = first.lifecycle("onLoad", "{}")
  let second_app = @application.program().create_runtime()
  defer ignore(second_app.dispose())
  let second = second_app.create_page(program(second_app.deps())).unwrap()
  let _ = second.lifecycle("onLoad", "{}")
  let primary = "$component:toggle-card:cards:primary"
  let _ = first.mount()
  let _ = second.mount()
  let _ = first.dispatch(
    primary + "/note",
    "{\"detail\":{\"value\":\"first\"}}",
  )
  let _ = second.dispatch(
    primary + "/note",
    "{\"detail\":{\"value\":\"second\"}}",
  )
  inspect(first.snapshot().contains("first"), content="true")
  inspect(second.snapshot().contains("second"), content="true")
  let _ = first.dispose()
  let result = second.dispatch(
    primary + "/enabled",
    "{\"detail\":{\"value\":true}}",
  )
  inspect(result.contains("StartSubscription"), content="true")
  inspect(second.snapshot().contains("second"), content="true")
}

///|
test "protocol v7 lab decodes scroll and high-frequency controls" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let _ = runtime.dispatch("controls/jump-controls", "{}")
  inspect(
    runtime.snapshot().contains("\"scrollIntoView\":\"control-lab\""),
    content="true",
  )
  let _ = runtime.dispatch(
    "controls/checked", "{\"detail\":{\"value\":[\"typed\",\"scoped\"]}}",
  )
  let _ = runtime.dispatch(
    "controls/radio", "{\"detail\":{\"value\":\"miniapp\"}}",
  )
  let _ = runtime.dispatch("controls/picker", "{\"detail\":{\"value\":\"1\"}}")
  let _ = runtime.dispatch("controls/slide", "{\"detail\":{\"current\":1}}")
  let _ = runtime.dispatch(
    "controls/scroll", "{\"detail\":{\"scrollLeft\":0,\"scrollTop\":42,\"scrollHeight\":300,\"scrollWidth\":100,\"deltaX\":0,\"deltaY\":4}}",
  )
  let snapshot = runtime.snapshot()
  inspect(snapshot.contains("picker: Skyline"), content="true")
  inspect(snapshot.contains("current swiper page: 2"), content="true")
  inspect(snapshot.contains("Swiper page 2"), content="true")
  inspect(snapshot.contains("scroll top: 42"), content="true")
  inspect(snapshot.contains("\"kind\":\"swiper\""), content="true")
  inspect(snapshot.contains("\"kind\":\"navigator\""), content="true")
  inspect(snapshot.contains("instance=secondary"), content="true")
  inspect(
    runtime
    .dispatch("controls/picker", "{\"detail\":{\"value\":\"invalid\"}}")
    .contains("event_decode_failed"),
    content="true",
  )
  inspect(
    runtime
    .dispatch("controls/slide", "{\"detail\":{\"value\":1}}")
    .contains("event_decode_failed"),
    content="true",
  )
}

///|
test "controlled native values survive one structural transaction" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let _ = runtime.dispatch(
    "dynamic/name", "{\"detail\":{\"value\":\"Native structural probe\"}}",
  )
  let reconciled = runtime.dispatch("controls/reconcile-native", "{}")
  inspect(
    reconciled.split("\"type\":\"PatchViewTree\"").length() == 2,
    content="true",
  )
  inspect(reconciled.contains("\"op\":\"set\""), content="true")
  inspect(reconciled.contains("\"op\":\"move\""), content="true")
  inspect(reconciled.contains("ReplaceViewTree"), content="false")
  let snapshot = runtime.snapshot()
  inspect(
    snapshot.contains("\"range\":[\"Skyline\",\"ArkUI\",\"MoonBit\"]"),
    content="true",
  )
  inspect(snapshot.contains("\"value\":2"), content="true")
  inspect(snapshot.contains("picker: MoonBit"), content="true")
  inspect(snapshot.contains("\"current\":1"), content="true")
  inspect(snapshot.contains("\"circular\":false"), content="true")
  inspect(snapshot.contains("Swiper page 1"), content="true")
  inspect(snapshot.contains("hello:Minimoon"), content="true")
  inspect(snapshot.contains("input event:reconciled"), content="true")
  inspect(snapshot.contains("Native structural probe"), content="false")
  inspect(snapshot.contains("native reconcile:completed"), content="true")
  inspect(
    runtime.dispatch("controls/reconcile-native", "{}") == "[]",
    content="true",
  )
}

///|
test "lab exercises branches, unkeyed rows, keyed reorder, input, and root replacement" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  inspect(runtime.snapshot().contains("collapsed branch"), content="true")
  inspect(
    runtime.dispatch("dynamic/toggle", "{}").contains("\"op\":\"splice\""),
    content="true",
  )
  inspect(runtime.snapshot().contains("expanded branch"), content="true")
  inspect(
    runtime.dispatch("dynamic/add-note", "{}").contains("\"op\":\"splice\""),
    content="true",
  )
  inspect(runtime.snapshot().contains("note-1"), content="true")
  inspect(
    runtime.dispatch("dynamic/remove-note", "{}").contains("\"op\":\"splice\""),
    content="true",
  )
  inspect(runtime.snapshot().contains("note-1"), content="false")
  inspect(
    runtime
    .dispatch(
      "dynamic/name", "{\"detail\":{\"value\":\"MoonBit cursor probe\"}}",
    )
    .contains("\"op\":\"set\""),
    content="true",
  )
  let reorder = runtime.dispatch("dynamic/reorder", "{}")
  inspect(reorder.contains("\"op\":\"move\""), content="true")
  inspect(reorder.contains("\"identity\":\"k:c\""), content="true")
  inspect(reorder.contains("\"identity\":\"k:focus-probe\""), content="false")
  inspect(reorder.contains("\"op\":\"splice\""), content="false")
  inspect(reorder.contains("ReplaceViewTree"), content="false")
  inspect(
    runtime.snapshot().contains("\"identity\":\"k:focus-probe\""),
    content="true",
  )
  inspect(runtime.snapshot().contains("\"identity\":\"k:c\""), content="true")
  inspect(
    runtime.snapshot().contains("hello:MoonBit cursor probe"),
    content="true",
  )
  let reset = runtime.dispatch("dynamic/reset-controlled-input", "{}")
  inspect(reset.contains("\"op\":\"set\""), content="true")
  inspect(reset.contains("\"op\":\"move\""), content="false")
  inspect(reset.contains("\"op\":\"splice\""), content="false")
  inspect(reset.contains("ReplaceViewTree"), content="false")
  inspect(runtime.snapshot().contains("hello:Minimoon"), content="true")
  inspect(runtime.snapshot().contains("input event:reset"), content="true")
  inspect(runtime.snapshot().contains("MoonBit cursor probe"), content="false")
  let _ = runtime.dispatch("dynamic/select-c", "{}")
  inspect(runtime.snapshot().contains("selected:c"), content="true")
  let _ = runtime.dispatch(
    "dynamic/name-focus", "{\"detail\":{\"value\":\"MoonBit cursor probe\",\"height\":44}}",
  )
  inspect(
    runtime.snapshot().contains("input event:focus:MoonBit cursor probe"),
    content="true",
  )
  let _ = runtime.dispatch(
    "dynamic/name-blur", "{\"detail\":{\"value\":\"MoonBit cursor probe\"}}",
  )
  inspect(
    runtime.snapshot().contains("input event:blur:MoonBit cursor probe"),
    content="true",
  )
  let _ = runtime.dispatch(
    "dynamic/name-confirm", "{\"detail\":{\"value\":\"MoonBit cursor probe\"}}",
  )
  inspect(
    runtime.snapshot().contains("input event:confirm:MoonBit cursor probe"),
    content="true",
  )
  inspect(
    runtime.dispatch("dynamic/replace-root", "{}").contains("ReplaceViewTree"),
    content="true",
  )
  inspect(runtime.snapshot().contains("\"kind\":\"fragment\""), content="true")
}

///|
test "lab isolates focused keyed reorder from the resident page tick" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let armed = runtime.dispatch("dynamic/arm-focused-reorder", "{}")
  inspect(
    armed ==
    "[{\"type\":\"StopSubscription\",\"component_id\":\"lab\",\"key\":\"lab/page-tick\"},{\"type\":\"StartSubscription\",\"component_id\":\"lab\",\"key\":\"lab/focused-keyed-reorder\",\"interval_ms\":10000}]",
    content="true",
  )
  inspect(armed.contains("lab/focused-keyed-reorder"), content="true")
  inspect(armed.contains("lab/page-tick"), content="true")
  inspect(armed.contains("StartSubscription"), content="true")
  inspect(armed.contains("StopSubscription"), content="true")
  inspect(armed.contains("PatchViewTree"), content="false")
  inspect(armed.contains("ReplaceViewTree"), content="false")
  let fired = runtime.subscription("lab/focused-keyed-reorder", "{}")
  inspect(fired.contains("\"op\":\"move\""), content="true")
  inspect(fired.split("\"type\":").length() == 4, content="true")
  inspect(fired.split("\"op\":").length() == 2, content="true")
  inspect(fired.contains("\"identity\":\"k:c\""), content="true")
  inspect(fired.contains("\"identity\":\"k:focus-probe\""), content="false")
  inspect(fired.contains("\"op\":\"set\""), content="false")
  inspect(fired.contains("\"op\":\"splice\""), content="false")
  inspect(fired.contains("ReplaceViewTree"), content="false")
  inspect(fired.contains("StopSubscription"), content="true")
  inspect(fired.contains("StartSubscription"), content="true")
  inspect(fired.contains("lab/page-tick"), content="true")
  let _ = runtime.dispatch("dynamic/arm-focused-reorder", "{}")
  let disposed = runtime.dispose()
  inspect(disposed.contains("lab/focused-keyed-reorder"), content="true")
  inspect(disposed.contains("StopSubscription"), content="true")
}

///|
test "lab delay probe uses a cancellable 600ms host timeout" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let started = runtime.dispatch("dynamic/start-delay", "{}")
  inspect(
    started.contains("\"capability\":\"minimoon.timeout\""),
    content="true",
  )
  inspect(
    started.split("\"type\":\"InvokeCapability\"").length() == 2,
    content="true",
  )
  inspect(started.contains("\"payload\":{\"ms\":600}"), content="true")
  inspect(started.contains("\"request_id\":\"lab:0\""), content="true")
  inspect(
    runtime.snapshot().contains("delay probe:running:600ms"),
    content="true",
  )
  let completed = runtime.resolve_effect("lab:0", "success", "{}")
  inspect(completed.contains("PatchViewTree"), content="true")
  inspect(
    runtime.snapshot().contains("delay probe:completed:600ms"),
    content="true",
  )

  let disposing_app = @application.program().create_runtime()
  defer ignore(disposing_app.dispose())
  let disposing = disposing_app
    .create_page(program(disposing_app.deps()))
    .unwrap()
  let _ = disposing.lifecycle("onLoad", "{}")
  let _ = disposing.mount()
  let _ = disposing.dispatch("dynamic/start-delay", "{}")
  let disposed = disposing.dispose()
  inspect(disposed.contains("CancelEffect"), content="true")
  inspect(
    disposed.split("\"type\":\"CancelEffect\"").length() == 2,
    content="true",
  )
  inspect(disposed.contains("\"request_id\":\"lab:0\""), content="true")
}

///|
test "conformance lab uses ABI v12, shared WXML, and query isolation marker" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app
    .create_page(program(runtime_app.deps()), input={ "instance": "second" })
    .unwrap()
  let _ = runtime.lifecycle("onLoad", "{\"instance\":\"second\"}")
  inspect(runtime.snapshot().contains("instance: second"), content="true")
  let contract = @application.program().preview(deps => program(deps).contract())
  inspect(contract.contains("\"runtimeApiVersion\":12"), content="true")
  inspect(contract.contains("\"rendererProtocolVersion\":8"), content="true")
  let wxml = @application.program().preview(deps => program(deps).wxml())
  inspect(wxml.contains("minimoon_dynamic_node"), content="true")
  inspect(wxml.contains("minimoon.templates.wxml"), content="true")
}

///|
test "lab exposes bilingual guidance and stack-aware return" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let tree = runtime.snapshot()
  inspect(tree.contains("\"section\":\"lab-intro\""), content="true")
  inspect(tree.contains("增量运行实验室"), content="true")
  let _ = runtime.mount()
  let back = runtime.dispatch("lab/back-studio", "{}")
  inspect(back.contains("\"type\":\"NavigateBackOrRedirect\""), content="true")
  inspect(back.contains("/pages/showcase/showcase"), content="true")
}

///|
test "lab exercises minimal-v2 semantic navigation and overlays" {
  let runtime_app = @application.program().create_runtime()
  defer ignore(runtime_app.dispose())
  let runtime = runtime_app.create_page(program(runtime_app.deps())).unwrap()
  let _ = runtime.lifecycle("onLoad", "{}")
  let _ = runtime.mount()
  let initial = runtime.snapshot()
  inspect(initial.contains("mm-disclosure"), content="true")
  inspect(initial.contains("\"role\":\"tablist\""), content="true")
  inspect(
    initial.contains("\"ariaLabel\":\"Conformance tab sections\""),
    content="true",
  )
  inspect(initial.contains("Overview tab panel"), content="true")
  inspect(initial.contains("Disclosure panel content"), content="false")
  let _ = runtime.dispatch("conformance-disclosure/toggle", "{}")
  inspect(
    runtime.snapshot().contains("Disclosure panel content"),
    content="true",
  )
  let _ = runtime.dispatch("conformance-accordion/second/toggle", "{}")
  inspect(runtime.snapshot().contains("Accordion second panel"), content="true")
  let _ = runtime.dispatch("conformance-accordion-multiple/second/toggle", "{}")
  inspect(runtime.snapshot().contains("Multiple first panel"), content="true")
  inspect(runtime.snapshot().contains("Multiple second panel"), content="true")
  inspect(runtime.snapshot().contains("reactive counter:0"), content="false")
  let _ = runtime.dispatch(
    "conformance-reactive-accordion/counter/toggle", "{}",
  )
  inspect(runtime.snapshot().contains("reactive counter:0"), content="true")
  let _ = runtime.dispatch("conformance-reactive-counter/increment", "{}")
  inspect(runtime.snapshot().contains("reactive counter:1"), content="true")
  let _ = runtime.dispatch("dynamic/increment", "{}")
  inspect(runtime.snapshot().contains("reactive counter:1"), content="true")
  let _ = runtime.dispatch(
    "conformance-reactive-accordion/counter/toggle", "{}",
  )
  inspect(runtime.snapshot().contains("reactive counter:1"), content="false")
  let _ = runtime.dispatch(
    "conformance-reactive-accordion/counter/toggle", "{}",
  )
  inspect(runtime.snapshot().contains("reactive counter:1"), content="true")
  let _ = runtime.dispatch("conformance-tabs/details/select", "{}")
  inspect(runtime.snapshot().contains("Details tab panel"), content="true")
  inspect(runtime.snapshot().contains("\"ariaSelected\":true"), content="true")
  let _ = runtime.dispatch("conformance-dialog/open", "{}")
  inspect(runtime.snapshot().contains("Conformance dialog"), content="true")
  inspect(runtime.snapshot().contains("\"ariaModal\":true"), content="true")
  let _ = runtime.dispatch("conformance-dialog/content-close", "{}")
  inspect(runtime.snapshot().contains("Conformance dialog"), content="false")
  let _ = runtime.dispatch("conformance-dialog/open", "{}")
  let _ = runtime.dispatch("conformance-dialog/overlay/close", "{}")
  inspect(runtime.snapshot().contains("Conformance dialog"), content="false")
  let _ = runtime.dispatch("conformance-sheet/open", "{}")
  inspect(runtime.snapshot().contains("Sheet panel content"), content="true")
  inspect(runtime.snapshot().contains("\"section\":\"sheet\""), content="true")
  let _ = runtime.dispatch("conformance-sheet/close", "{}")
  inspect(runtime.snapshot().contains("Sheet panel content"), content="false")
  let _ = runtime.dispatch("conformance-sheet/open", "{}")
  let _ = runtime.dispatch("conformance-sheet/overlay/close", "{}")
  inspect(runtime.snapshot().contains("Sheet panel content"), content="false")
  let _ = runtime.dispatch("conformance-menu/toggle", "{}")
  inspect(runtime.snapshot().contains("\"role\":\"menu\""), content="true")
  inspect(runtime.snapshot().contains("dropdown--top-start"), content="true")
  inspect(
    runtime.snapshot().contains("dropdown--bottom-start"),
    content="false",
  )
  inspect(
    runtime
    .snapshot()
    .contains("\"ariaLabelledBy\":\"conformance-menu-trigger\""),
    content="true",
  )
  let _ = runtime.dispatch("conformance-menu/item/compact", "{}")
  inspect(runtime.snapshot().contains("\"ariaChecked\":true"), content="true")
  let _ = runtime.dispatch("conformance-menu/item/theme-dark", "{}")
  inspect(
    runtime.snapshot().contains("\"role\":\"menuitemradio\""),
    content="true",
  )
  let _ = runtime.dispatch("conformance-menu/item/more/submenu", "{}")
  inspect(runtime.snapshot().contains("About Minimoon"), content="true")
  let _ = runtime.dispatch("conformance-menu/item/about", "{}")
  inspect(runtime.snapshot().contains("Preferences"), content="false")
  let _ = runtime.dispatch("conformance-menu/toggle", "{}")
  let _ = runtime.dispatch("conformance-menu/dismiss", "{}")
  inspect(runtime.snapshot().contains("Preferences"), content="false")
}
