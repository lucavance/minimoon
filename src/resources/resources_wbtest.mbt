///|
test "resource encoding preserves Unicode, stylesheet bytes and asset content" {
  let encoded = encode({
    id: "sample",
    version: "1.0.0",
    wxss: ".sample { color: red; }\n",
    assets: [{ path: "assets/sample/help.txt", content: Text("帮助\n"), }],
  })
  assert_true(encoded.contains("\"id\":\"sample\""))
  assert_true(encoded.contains(".sample { color: red; }\\n"))
  assert_true(encoded.contains("帮助\\n"))
}

///|
test "binary resource probe encoding preserves arbitrary bytes without UTF8 conversion" {
  let bytes = b"\x00\xff\x89PNG"
  let encoded = encode({
    id: "binary",
    version: "1",
    wxss: "",
    assets: [{ path: "assets/icon.png", content: Binary(bytes), }],
  })
  assert_true(encoded.contains("\"encoding\":\"base64\""))
  assert_true(encoded.contains(@base64.encode(bytes)))
  assert_eq(@base64.decode(@base64.encode(bytes)), bytes)
}
