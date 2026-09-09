# 02. 应用编写模型 / Authoring Model

[上一篇 / Previous](01-SYSTEM-ARCHITECTURE.md) · [返回索引 / Back](README.md) · [下一篇 / Next](03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md)

## 1. Model、Msg 与 update / Model, Msg, and update

Minimoon 使用 Elm 风格状态机，但不要求一个全局应用 Model。每个页面或 keyed/dynamic `Val` 分支都可以创建自己的 `(Val[Model], Emit[Msg])`。消息是领域事件，`update` 计算 `(Model, Cmd)`，`view` 只读取当前 Model 并产生不可变 `Node`。

> **English:**
>
> Minimoon uses Elm-style state machines without requiring one global application model. Each page or keyed/dynamic `Val` branch can create its own `(Val[Model], Emit[Msg])`. Messages are domain events, `update` computes `(Model, Cmd)`, and `view` reads the current model to produce an immutable `Node`.

可选的 `App[Deps]` 增加应用级领域状态机；AppContext 创建 `(Shared[Model], Emit[Msg])`，
PageContext 的 bind/select 将共享值投影到页面局部 Val。页面事务提交后才外发应用消息，
应用提交不会被个别页面渲染失败回滚。详见 [共享状态指南](../guides/shared_state.md)。

> Optional `App[Deps]` adds owned application domain machines. AppContext creates
> `(Shared[Model], Emit[Msg])`; PageContext binds/selects page-local Val projections.
> Page messages leave only after commit, and failed page rendering does not undo an
> application commit. See the [shared-state guide](../guides/shared_state.md).

```mermaid
flowchart LR
    HostEvent[宿主事件 / Host event]
    Decode[typed decoder<br/>类型解码]
    Msg[Msg]
    Update[update Model Msg]
    Result[Model + Cmd]
    View[view Model]
    Node[Node tree<br/>节点树]
    Renderer[transactional renderer<br/>事务渲染]
    Effect[Cmd / effect / navigation]

    HostEvent --> Decode --> Msg --> Update --> Result
    Result --> View --> Node --> Renderer
    Result --> Effect
    Effect -. completion Msg .-> Update
```

[SVG](assets/diagrams/svg/02-AUTHORING-MODEL-1.svg) · [PNG 3×](assets/diagrams/png/02-AUTHORING-MODEL-1.png) · [Mermaid](assets/diagrams/source/02-AUTHORING-MODEL-1.mmd)

> **源码 / Source:** [`examples/miniapp_conformance_app/src/app/app.mbt`](../../examples/miniapp_conformance_app/src/app/app.mbt) · symbols: `FetchModel`, `FetchMsg`, `initial_fetch`, `update_fetch`

```moonbit
pub struct FetchModel {
  epoch : Int
  label : String
} derive(Eq)

pub(all) enum FetchMsg {
  Load
  Clear
  Finished(Int, Result[@minimoon.RequestResult, @minimoon.HostError])
}

pub fn update_fetch(
  current : FetchModel,
  message : FetchMsg,
  emit : @minimoon.Emit[FetchMsg],
) -> (FetchModel, @minimoon.Cmd) {
  match message {
    Load => {
      let epoch = current.epoch + 1
      @minimoon.with_cmd(
        { epoch, label: "loading" },
        @minimoon.request(
          "https://httpbingo.org/delay/2",
          emit.map(result => Finished(epoch, result)),
        ),
      )
    }
    Clear => @minimoon.no_cmd({ epoch: current.epoch + 1, label: "idle" })
    // Finished first checks the epoch, then derives the displayed result.
    _ => @minimoon.no_cmd(current)
  }
}
```

最后的通配分支是明确省略的回调处理，不是源码原样分支；真实函数先校验 epoch，再接受成功或失败结果。
同一个领域更新函数分别由 AppContext 和生命周期页创建状态：前者在页面卸载后继续，后者随页面释放。
首页计数等简单独立状态直接使用 `create_variable`，导航按钮直接持有 opaque `Cmd`，不需要额外的消息枚举。

> **English:**
>
> The wildcard explicitly abbreviates completion handling; the real function validates the epoch before accepting success or failure.
> AppContext and the lifecycle page create separate state using the same domain update: one survives page unload, the other is disposed with the page.
> Simple independent values such as the homepage counter use `create_variable`; navigation buttons hold opaque commands without an extra message enum.

## 2. 根 API 如何封装内部状态 / How the Root API Wraps Internal State

`create_state` 返回只读 `Val[Model]` 与可调用的 `Emit[Msg]`。应用可以读、发送和渲染，却拿不到可直接写入的 cell；所有写入都必须经过消息更新和 graph transaction。

> **English:**
>
> `create_state` returns a read-only `Val[Model]` and callable `Emit[Msg]`. Applications can read, send, and render, but cannot obtain a directly writable cell. Every write must pass through message update and a graph transaction.

> **源码 / Source:** [`src/authoring_core.mbt`](../../src/authoring_core.mbt) · symbols: `Emit`, `Val`, `create_state`

```moonbit
pub(all) struct Emit[Msg]((Msg) -> Cmd)

pub fn[Model : Eq, Msg] create_state(
  initial : Model,
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Val[Model], Emit[Msg]) {
  let (value, emit) = @val.create_state(
    initial,
    update=(model, message, inner) => {
      let (next, command) = update(model, message, wrap_emit(inner))
      (next, command.0)
    },
  )
  (Val(value), wrap_emit(emit))
}
```

这是一个语义化精简片段：真实实现还完整映射 `subscriptions`，可在源码链接中查看。封装有两个目的：对应用隐藏内部 emitter 表示，并保证 `Cmd` 只能由 runtime 在候选事务成功后解释。

> **English:**
>
> This is a semantically shortened excerpt; the real implementation also maps `subscriptions` in full, as shown by the source link. Encapsulation hides the internal emitter representation and ensures that only the runtime interprets `Cmd` after a candidate transaction succeeds.

## 3. Val 是增量值，不是 Signal / Val Is an Incremental Value, Not a Signal

`Val[A]` 表示页面 graph 内可增量重算的只读值。`map2` 至 `map9` 组合独立依赖，`assoc` 按 key 保留局部所有权，`switch` 替换单分支，`enumerate` 缓存有限 tag，`enumerate_bounded_by` 为无限 tag 加事务化 LRU 上限。

> **English:**
>
> `Val[A]` represents a read-only value that can be incrementally recomputed inside a page graph. `map2` through `map9` combine independent dependencies, `assoc` retains local ownership by key, `switch` replaces one branch, `enumerate` caches a finite tag domain, and `enumerate_bounded_by` adds a transactional LRU bound for unbounded tags.

```mermaid
flowchart TB
    Page[Page graph / 页面图]
    Input[page input Val]
    StateA[local Val A]
    StateB[local Val B]
    Map[Val::map2..map9]
    Assoc[Val::assoc<br/>keyed local scopes]
    Switch[Val::switch / enumerate]
    Root[Val Node root]

    Page --> Input
    Page --> StateA
    Page --> StateB
    Input --> Map
    StateA --> Map
    StateB --> Map
    Map --> Assoc
    Map --> Switch
    Assoc --> Root
    Switch --> Root
```

[SVG](assets/diagrams/svg/02-AUTHORING-MODEL-2.svg) · [PNG 3×](assets/diagrams/png/02-AUTHORING-MODEL-2.png) · [Mermaid](assets/diagrams/source/02-AUTHORING-MODEL-2.mmd)

> **源码 / Source:** [`src/authoring_core.mbt`](../../src/authoring_core.mbt) · symbols: `Val::map2`, `Val::assoc`, `Val::enumerate_bounded_by`

```moonbit
pub fn[A : Eq, B : Eq, C] Val::map2(
  a : Val[A],
  b : Val[B],
  map : (A, B) -> C,
) -> Val[C] {
  Val(@val.Val::map2(a.0, b.0, map))
}

pub fn[K : Hash + Eq, V : Eq, C : Eq] Val::assoc(
  self : Val[Vector[(K, V)]],
  map : (K, Val[V]) -> Val[C],
) -> Val[Vector[C]] {
  Val(self.0.assoc((key, value) => map(key, Val(value)).0))
}
```

`Eq` 约束不是装饰：graph 用它判断写入是否改变值、projection 是否需要继续、缓存输入是否可复用。keyed child 的 key 则同时承担 UI identity 和局部 state/subscription scope identity；不稳定 key 会表现为组件重建，而不是普通重绘。

> **English:**
>
> The `Eq` constraints are not decorative. The graph uses them to determine whether a write changed a value, whether projection should continue, and whether cached input is reusable. A keyed child’s key also identifies its local state/subscription scope; unstable keys cause component reconstruction rather than an ordinary repaint.

## 4. Cmd 与 Sub 的生命周期 / Cmd and Sub Lifecycle

`Cmd` 描述一次性工作：同步消息、批处理、本地异步 effect、声明过的 host capability 或导航。`Sub` 描述随当前 Model/页面生命周期持续存在的来源。两者都 opaque，应用不能绕过 runtime 手动完成 effect 或管理 interval handle。

> **English:**
>
> `Cmd` describes one-shot work: a synchronous message, batch, local asynchronous effect, declared host capability, or navigation. `Sub` describes sources that remain active with the current model/page lifecycle. Both are opaque, so applications cannot bypass the runtime to complete effects or manage interval handles manually.

```mermaid
sequenceDiagram
    participant Build as page build / 页面构建
    participant State as Val + Emit
    participant Runtime as resident runtime / 驻留运行时
    participant Host as generated host / 生成宿主
    participant WX as wx.* / timer

    Build->>State: init(emit) -> Model + Cmd
    State->>Runtime: accepted command
    Runtime->>Host: InvokeCapability or StartSubscription
    Host->>WX: declared adapter call
    WX-->>Host: success / fail / tick
    Host-->>Runtime: resolve_effect or subscription
    Runtime-->>State: typed Msg
    State->>Runtime: new Model + Cmd
    Build-->>Runtime: subscriptions(Model)
    Runtime->>Host: stop removed keys / start new keys
```

[SVG](assets/diagrams/svg/02-AUTHORING-MODEL-3.svg) · [PNG 3×](assets/diagrams/png/02-AUTHORING-MODEL-3.png) · [Mermaid](assets/diagrams/source/02-AUTHORING-MODEL-3.mmd)

> **源码 / Source:** [`src/authoring_page.mbt`](../../src/authoring_page.mbt) · symbols: `PageContext::every`, `PageContext::lifecycle`

```moonbit
pub fn PageContext::every(
  _self : PageContext,
  key~ : String,
  interval_ms~ : Int,
  command : Cmd,
) -> Sub {
  Sub(@val.sub_every(key~, interval_ms~, command.0))
}

pub fn PageContext::lifecycle(
  _self : PageContext,
  hook~ : PageLifecycleHook,
  command : Cmd,
) -> Sub {
  Sub(@val.sub_lifecycle(hook.host_name(), command.0))
}
```

订阅 key 必须稳定且在当前集合中唯一。模型变化后 runtime 比较旧、新 key：保留者复用 handle，删除者先 dispose，新增者再启动。分支不可见时 graph scope 会暂停相关订阅；scope 真正提交删除时才最终清理。

> **English:**
>
> Subscription keys must be stable and unique in the current set. After a model change, the runtime compares old and new keys: retained keys reuse handles, removed keys are disposed first, and new keys then start. When a branch becomes invisible, its graph scope pauses related subscriptions; final cleanup occurs only when scope deletion commits.

## 5. Page 是工厂，不是单例 / Page Is a Factory, Not a Singleton

`page` 和 `page_with_input` 仅保存闭包，定义时不执行 builder 或 decoder。`create_runtime(input?)` 复制并解码真实输入，成功后才创建 graph 并返回 `Ok(PageRuntime)`；失败返回 `Err(DecodeError)`。预览使用独立的 `preview_input()`，不执行命令。页面初始化命令等待首次 Ready/mount。

> **English:**
>
> `page` and `page_with_input` only store closures; definition executes neither builder nor decoder. `create_runtime(input?)` copies and decodes real input before creating a graph and returning `Ok(PageRuntime)`, or returns `Err(DecodeError)` without one. Previews use independent `preview_input()` values and execute no commands. Initial page commands wait for the first Ready/mount.

> **源码 / Source:** [`src/authoring_page.mbt`](../../src/authoring_page.mbt) · symbols: `make_page`, `page`, `page_with_input`

```moonbit
let make_program = fn(input : Input) {
  let graph = @val.Graph::new()
  let initialized = Ref(false)
  let root = graph.build(fn() { build({ graph, }, input) })
  // Lifecycle decoders and PageProgram are created for this graph instance.
  @renderer.page_program(
    id~,
    route=route_path,
    title~,
    model=0,
    update=(epoch, message) => graph_update(graph, message, epoch, initialized),
    view=(events, _) => graph.run(fn() { materialize(root.0.read(), events) }),
  )
}
```

这是省略 capabilities、subscriptions 和 commit/rollback hooks 的连续逻辑摘要。维护时最容易犯的错误，是把 page factory 外的可变变量捕获成跨实例共享状态；正确的 state、cache 和 subscription 所有权都应在 `make_program` 调用内创建。

> **English:**
>
> This contiguous logic summary omits capabilities, subscriptions, and commit/rollback hooks. A common maintenance error is capturing mutable state outside the page factory and unintentionally sharing it across instances. Correct state, cache, and subscription ownership must be created inside each `make_program` invocation.

## 6. 何时扩展公开 API / When to Extend the Public API

只有重复 dogfood 需求且无法由现有 `Val`、`Emit`、`Cmd`、`Sub` 或 typed capability 表达时，才应扩展根 API。直接公开 mutable signal、patch、`setData` 或 raw `wx.*` callback 会破坏事务边界、host 验证和跨实例隔离，不属于语法便利性改动。

> **English:**
>
> Extend the root API only when repeated dogfood needs cannot be expressed with existing `Val`, `Emit`, `Cmd`, `Sub`, or typed capabilities. Exposing mutable signals, patches, `setData`, or raw `wx.*` callbacks would break transaction boundaries, host validation, and instance isolation; those are not mere ergonomic changes.
