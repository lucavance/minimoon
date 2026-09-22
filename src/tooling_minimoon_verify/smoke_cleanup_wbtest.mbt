///|
async test "host smoke drains Hide and cleans every App on success or failure" {
  let root = @fs.tmpdir(prefix="minimoon-smoke-cleanup")
  defer @fs.rmdir(root, recursive=true)
  for mode in ["success", "launch", "page", "unload", "dispose", "plain"] {
    let current = join(root, mode)
    let events = join(current, "events")
    let files : Array[String] = []
    for name in ["first", "second"] {
      let directory = join(current, name)
      let logging = "const log = value => require('node:fs').appendFileSync(" +
        events.escape() +
        ", " +
        name.escape() +
        " + ':' + value + '\\n')\n"
      let conditions = "const mode = " +
        mode.escape() +
        ", first = " +
        (name == "first").to_string() +
        "\n"
      write(join(directory, "app.wxss"), "")
      if mode == "plain" {
        write(
          join(directory, "app.js"),
          logging + "App({ onHide() { queueMicrotask(() => log('hide')) } })",
        )
      } else {
        write(
          join(directory, "app.js"),
          "require('./minimoon.app.js').registerMinimoonApp()",
        )
        write(
          join(directory, "minimoon.app.js"),
          logging +
          conditions +
          (
            #|exports.registerMinimoonApp = () => {
            #|  let timer
            #|  App({
            #|    onLaunch() { timer = setInterval(() => {}, 60000); if (first && mode === 'launch') throw Error('launch failure') },
            #|    onShow() { queueMicrotask(() => log('show')) },
            #|    onHide() { queueMicrotask(() => log('hide')) },
            #|  })
            #|  return { dispose() { clearInterval(timer); log('dispose'); if (first && mode === 'dispose') throw Error('dispose failure') } }
            #|}
          ),
        )
      }
      let page = join(directory, "page.js")
      files.push(page)
      write(
        page,
        logging +
        conditions +
        (
          #|Page({ data: {},
          #|  onLoad() { this.__mmInstanceId = 1 }, onShow() {},
          #|  onReady() { if (first && mode === 'page') throw Error('page failure') },
          #|  onUnload() { this.__mmInstanceId = null; log('unload'); if (first && mode === 'unload') throw Error('unload failure') },
          #|})
        ),
      )
    }
    let script = join(current, "smoke.cjs")
    write(script, host_smoke_source(files))
    let (passed, detail) = run(
      "vp",
      @toolchain.bun_args([script]),
      current,
      timeout_ms=5000,
    )
    assert_eq(passed, mode == "success" || mode == "plain", msg=detail)
    assert_false(detail.contains("timed out"), msg=detail)
    let trace = @fs.read_file(events).text()
    if mode == "success" || mode == "plain" {
      for name in ["first", "second"] {
        assert_true(trace.contains(name + ":hide"), msg=trace)
        assert_true(trace.contains(name + ":unload"), msg=trace)
      }
    }
    if mode != "plain" {
      assert_true(trace.contains("first:dispose"), msg=trace)
      if mode != "launch" {
        assert_true(trace.contains("second:dispose"), msg=trace)
      }
    }
  }
}
