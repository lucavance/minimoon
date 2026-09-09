///|
test "interaction exercises minimal-v2 semantic navigation and overlays" {
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
  let _ = runtime.dispatch("composition/parent-update", "{}")
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
