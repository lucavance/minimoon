# Application-owned shared state / 应用级共享状态

Minimoon does not require one global Model. An optional `App[Deps]` owns several
typed domain state machines; `Deps` is your application's dependency record,
not a framework singleton or string-key registry. Pages retain their local
`Model / Msg / update / Cmd / Sub` and compose read-only projections through `Val`.

Minimoon 不要求一个全局 Model。可选的 `App[Deps]` 管理多个不同类型的领域状态机，
`Deps` 是应用自己定义的依赖集合；页面仍保留局部状态。框架不会引入可任意修改的
全局 Signal、字符串 Store 注册表或另一套 AppCmd。

## Application package / 应用入口

Export `Deps` and `program() -> App[Deps]` from `src/app`. Import only the root
`lampclaw/minimoon` package in application code.

在 `src/app` 导出 `Deps` 和 `program() -> App[Deps]`，业务代码只需要导入根包。

```moonbit
pub struct Deps {
  count : @minimoon.Shared[Int]
  change_count : @minimoon.Emit[Int]
}

pub fn program() -> @minimoon.App[Deps] {
  @minimoon.app(build=context => {
    let (count, change_count) = context.create_pure_state(
      0, update=(count, delta : Int) => count + delta,
    )
    { count, change_count }
  })
}
```

`AppContext.create_state` and `create_state_with_init` support the same typed
update signature as local state: `(Model, Msg, Emit[Msg]) -> (Model, Cmd)`.
Create application state in the App builder, not in update/view callbacks.
Builders and initial-model computation must be pure: return initialization
commands from `init`; do not perform network or other effects in the builder.

有副作用的状态机使用 `context.create_state` 或 `create_state_with_init`，其 update
签名与局部状态一致。只能在 App builder 中创建应用状态，不要在 update/view 中创建。
builder 和初始模型计算必须保持纯函数：初始化副作用以 `init` 返回的 Cmd 表达。

## Configuration and pages / 配置与页面

```json
{
  "schemaVersion": 11,
  "application": { "package": "src/app", "program": "program" }
}
```

Merge this fragment into `miniapp.minimoon.json`, retaining name, pages and build
settings. `program` defaults to `program`. Every configured page must then
import the application package as `@application` and export
`program(deps : @application.Deps) -> @minimoon.Page`.

将片段合并到配置中，保留原有 name、pages 和构建设置。启用后，所有配置页面统一接收
同一个 `Deps` 类型。`minimoon add page` 会生成相应参数和 import。

```moonbit
pub fn program(deps : @application.Deps) -> @minimoon.Page {
  @minimoon.page(
    id="counter", route=@minimoon.route("pages/counter/counter"), title="Counter",
    build=context => {
      context.bind(deps.count).view(count => {
        @minimoon.button(
          on_tap=(deps.change_count)(1), event_key="counter/increment",
          count.to_string(),
        )
      })
    },
  )
}
```

Use `context.select(shared, model => model.field)` when a page needs only part
of a domain. Both Model and selected values implement `Eq`; equal projections
do not request a renderer update. Keep selectors pure. `Shared` is not a `Val`:
it has no direct public `read`, `map` or mutation API. Binding it to another
application, an unattached page, or a disposed owner fails immediately.

Treat models as values: return replacements from update, and do not mutate
arrays/maps obtained through a selector. The wrapper prevents direct state
writes; it does not deep-freeze arbitrary user-defined models.

页面只需要部分数据时使用 `select`；相等投影不会唤醒渲染。Model 与投影值均需实现
`Eq`，selector 必须纯净。Shared 不是可跨图直接读取的 Val，错误的应用归属会立即报错。
Model 按值使用，update 返回新值；不要原地修改 selector 获得的数组或 Map。封装禁止直接
写状态，但不会深度冻结任意业务模型。

Without `application`, factories remain `program() -> Page`. Both application
modes require source schema `11`; older configurations must migrate. Output
uses App Contract v11, runtime ABI v13 and renderer protocol v8. Rebuild all
artifacts together; do not mix old host/runtime bytes. Product versions are not
automatically advanced by these technical compatibility numbers.

不启用 `application` 时保留无参数页面工厂，但同样要求 schema `11`。旧 schema 必须迁移。必须整体
重新生成产物，不能混用旧宿主和新 runtime；技术契约版本不等于产品发布版本。

## Lifetime and effects / 生命周期与副作用

| Event / 事件 | Application / 应用 | Page / 页面 |
| --- | --- | --- |
| Launch | Run initialization once / 初始化一次 | Created separately / 单独创建 |
| Show | Resume foreground intervals / 恢复前台定时订阅 | Refresh latest projections / 追赶最新共享值 |
| Hide | Pause intervals, retain data and HTTP / 暂停定时订阅，保留数据与请求 | Pause shared projections / 暂停共享投影 |
| Page unload | Retain shared state/tasks / 共享状态和任务继续 | Dispose local state, bindings and tasks / 清理局部状态、绑定和任务 |
| Explicit App dispose | Invalidate addresses, cancel tasks, dispose pages / 地址失效、取消任务并回收页面 | Dispose all remaining instances / 回收全部页面实例 |

Declare application capabilities on `app(capabilities=[...])`. Application
scope allows Request, Login, GetStorage and SetStorage plus local async work
and delay. A page's capability declaration does not grant privileges to App,
or vice versa. Navigation and node measurement need an explicit page owner;
they are not routed implicitly to whichever page is visible.

应用 capability 与页面声明互不继承。应用支持请求、登录、读写存储、局部异步任务和
延迟；导航和节点测量仍必须由页面负责，不能隐式借用当前可见页。

The runtime executing a `Cmd` owns its effect; the result `Emit` does not move
that ownership. A page that directly returns `request(..., app_emit)` still
owns the request. To survive page unload, send a business message to App and
return the request from the App update, as the maintained example does.

副作用归执行 `Cmd` 的 runtime 所有，而不是由结果 `Emit` 决定。页面直接返回
`request(..., app_emit)` 仍是页面请求。要让请求跨页面卸载存活，应先向 App 发送业务
消息，再由 App update 返回 request；维护中的示例采用的就是这条路径。

Page messages to App leave an outbox only after page commit. A rejected page
transaction sends nothing. An App commit is independent: one page failing to
render does not undo shared state or another page. There is no atomic render
transaction across pages. Each App processes messages FIFO; async completions
have their own wake path and need no later page input.

页面事务提交后才外发应用消息；页面回滚不会外发。应用提交后，个别页面渲染失败不会
回滚应用状态，也不会影响其他页面。跨页渲染不承诺原子性，应用消息按 FIFO 处理，异步
完成通过独立唤醒路径交付，不依赖再次点击。

Disposal is explicit for runtime owners/tests; WeChat has no invented App
shutdown hook here. It is idempotent. Late callbacks are ignored using owner
generations. Logout/reset is different from owner disposal: increment a business
epoch and compare it when a response arrives. A still-live App cannot know
whether a successful old request remains relevant to a new account.
Dynamic account/workspace scopes are deliberately deferred.

销毁幂等，不伪造微信不存在的 App 退出事件。销毁后旧回调按归属代次失效；但退出登录
或重置仍属于活应用的业务行为，需要业务 epoch 拒绝旧响应。动态账号/工作区作用域留待
真实需求驱动的后续设计。

## Tests and acceptance / 测试与验收

For MoonBit tests, import `lampclaw/minimoon/testing` as `@testing` and use
`@testing.launch(application.program())`. Create a page with
`app.mount(page.program, input=fields)`. The factory receives this test App's
real dependencies. The harness drives
Launch/Show and page Load/Show/Ready in order, exposes the same semantic
queries as standalone `@testing.mount`, and drains ready application/page work
with bounded `app.quiesce()`. Disposing a mounted test page leaves App alive;
`app.dispose()` disposes the application and all remaining pages.

For low-level protocol tests, `AppRuntime.create_page(page, input?)` returns
`Result[PageRuntime, DecodeError]`. On success send the matching `onLoad`, then
`onShow`, then call `mount()`. Use `app.flush()` and `page.flush()` while either
owner reports `has_ready_work()`. Unresolved HTTP and future timer ticks are
not ready work; `[]` output alone does not prove a bounded queue has drained.
Generated hosts schedule this work automatically.
Use `application.program().preview(deps => page.program(deps).contract())`
for metadata: previews never dispatch init commands or start subscriptions.

应用测试通过 `@testing.launch`、`app.mount` 和有界 `quiesce` 驱动共同所有者，
单页 dispose 不销毁 App。低层创建返回 Result，必须先传真实输入并完成 Load，
再 Show、mount；生成的宿主自动调度。预览只检查初始值，不启动初始化
命令、定时器或网络。测试结束要 dispose，不能将预览句柄作为运行时依赖长期保存。

The maintained example is [the core app package](https://github.com/lucavance/minimoon/blob/main/examples/miniapp_conformance_app/src/app/app.mbt),
with panels in Capability Probe and Details. In Developer Tools:

1. Increment on Capability Probe, navigate to Details, increment again, return: both share
   one count while local counters stay independent.
2. Start the public `https://httpbingo.org/delay/2` request and unload its page;
   another page receives the result. Hide/show must preserve shared data.
3. Start a request then Clear: the old completion must not overwrite idle.
4. Repeat navigation/unload and check a clean console. Revalidate the unchanged
   no-application UI showcase too, because the shared host bytes changed.

验收使用公共 API；不需自建 HTTPS 服务。自动化宿主脚本用可控 wx 替身验证乱序、重复
回调、页面卸载、应用销毁、后台暂停订阅和资源回收，它不是微信真实宿主证据。真实验证
仍需遵循 [Developer Tools 流程](../operations/miniapp_devtools_validation.md)，与精确
产物指纹绑定。验证命令不会自动提交、推送或发布。
