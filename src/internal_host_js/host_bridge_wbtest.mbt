///|
test "ABI v10 host captures, merges, and drains asynchronous runtime wakes" {
  let host = shared_host_bridge()
  let protocol = shared_protocol_bridge()
  assert_true(host.contains("__minimoonRuntimeWakeV10"))
  assert_true(host.contains("Promise.resolve().then"))
  assert_true(host.contains("generation !== this._gn"))
  assert_true(host.contains("this._dw !== token"))
  assert_true(host.contains("tail && tail.kind === \"drain\""))
  assert_true(host.contains("{ kind: \"drain\", through: token.through }"))
  assert_true(host.contains("JSON.stringify({ through: entry.through })"))
  assert_true(
    host.contains(
      "minimoon_runtime_lifecycle(this.__mmInstanceId, \"$minimoon:drain\"",
    ),
  )
  assert_true(host.contains("this._st.asyncDrains += 1"))
  assert_true(host.contains("instanceId !== this.__mmInstanceId"))
  assert_true(host.contains("this._sb.get(command.key) === handle"))
  assert_true(host.contains("exactKeys(timeoutPayload, [\"ms\"])"))
  assert_true(host.contains("Number.isInteger(timeoutPayload.ms)"))
  assert_true(host.contains("try { task = wx[method]"))
  assert_true(host.contains("catch (error) { fail(error); return }"))
  assert_true(protocol.contains("asyncDrains: 0"))
  assert_true(
    protocol.contains(
      "if (!value || typeof value !== \"object\" || Array.isArray(value)) return false",
    ),
  )
  assert_false(
    host.contains(
      "module.exports = { registerMinimoonPage, __minimoonRuntimeWakeV10 }",
    ),
  )
}

///|
test "typed UI host paths are finite, page-owned, and revision-guarded" {
  let host = shared_host_bridge()
  let protocol = shared_protocol_bridge()
  for
    marker in [
      "this.createSelectorQuery()", "entry.measureRevision !== this._rv", "revision !== this._rv",
      "...eventDispatchers", "validMeasurementPayload(payload)", "measurementNodes(results, payload.ids)",
    ] {
    assert_true(host.contains(marker))
  }
  for
    marker in [
      "__mmDispatchTouchStart", "__mmDispatchTouchMove", "__mmDispatchTouchEnd",
      "__mmDispatchTouchCancel", "__mmDispatchLongPress", "__mmDispatchChanging",
      "__mmDispatchSubmit", "__mmDispatchReset", "__mmDispatchLoad", "__mmDispatchError",
      "payload.ids.length <= 128", "\"slider\"", "\"progress\"", "\"form\"", "\"label\"",
      "\"touchcancel\"", "\"ariaValueNow\"",
    ] {
    assert_true(protocol.contains(marker))
  }
}
