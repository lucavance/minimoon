///|
test "package README authoring examples mount through the public runtime" {
  let page_runtime = readme_page().create_runtime()
  let _ = page_runtime.mount()
  assert_true(page_runtime.snapshot().contains("MoonBit"))
  let _ = page_runtime.dispose()

  let local_runtime = readme_local_page().create_runtime()
  assert_true(local_runtime.snapshot().contains("pending"))
  let _ = local_runtime.mount()
  assert_true(local_runtime.snapshot().contains("ready"))
  let _ = local_runtime.dispose()
}
