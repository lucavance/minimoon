///|
test "resource encoding preserves Unicode, stylesheet bytes and asset content" {
  let encoded = encode({
    id: "sample",
    version: "1.0.0",
    wxss: ".sample { color: red; }\n",
    assets: [{ path: "assets/sample/help.txt", content: "帮助\n", }],
  })
  assert_true(encoded.contains("\"id\":\"sample\""))
  assert_true(encoded.contains(".sample { color: red; }\\n"))
  assert_true(encoded.contains("帮助\\n"))
}
