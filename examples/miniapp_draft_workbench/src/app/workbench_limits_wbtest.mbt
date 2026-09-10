///|
test "capacity rejects a 51st record but permits edits; IDs are never reused after clear" {
  let h = harness()
  defer h.close()
  h.ready()
  for index = 0; index < 50; index = index + 1 {
    ignore(h.step(Choose(New)))
    h.save("draft " + index.to_string())
  }
  assert_eq(h.latest.val.store.records.length(), 50)
  ignore(h.step(Choose(New)))
  ignore(h.step(Title("overflow")))
  assert_false(h.step(Save).contains("wx.setStorage"))
  assert_true(h.latest.val.notice.contains("50"))
  ignore(h.step(Choose(Open(1))))
  ignore(h.step(Confirm))
  h.save("updated")
  assert_eq(h.latest.val.store.records.length(), 50)
  ignore(h.step(Choose(ClearAll)))
  let clear = h.step(Confirm)
  h.resolve(clear, "wx.setStorage", "success", Json::empty_object())
  h.save("after clear")
  assert_eq(h.latest.val.store.records[0].id, 51)
}

///|
test "delete and clear preserve input typed after confirmation and invalidate pending echo" {
  for intent in [Delete(1), ClearAll] {
    let h = harness()
    defer h.close()
    h.ready()
    h.save("saved")
    let echo = h.step(Send)
    ignore(h.step(Choose(intent)))
    let remove = h.step(Confirm)
    ignore(h.step(Note("typed during delete")))
    h.resolve(remove, "wx.setStorage", "success", Json::empty_object())
    assert_true(h.latest.val.store.records.is_empty())
    assert_true(h.latest.val.buffer.id is None)
    assert_eq(h.latest.val.buffer.draft.note, "typed during delete")
    assert_true(dirty(h.latest.val.buffer))
    assert_eq(h.latest.val.echo.submitted.title, "")
    h.resolve(echo, "wx.request", "success", {
      "statusCode": 200,
      "data": { "json": { "title": "saved", "note": "" } },
    })
    assert_true(h.latest.val.echo.status == EchoOutdated)
  }
}
