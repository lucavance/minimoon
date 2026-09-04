# Minimoon

[English](README.md) · [文档索引](docs/README.md) · [双语代码分析](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/README.md)

Minimoon 是面向微信小程序 Skyline 的 MoonBit UI 框架。`0.1.0` 以 Elm-style
编写模型为入口，采用 App Contract v7、runtime ABI v10、renderer protocol v7
和 CommonJS 小程序宿主边界。

```text
Model / Msg / update / Cmd / Sub
  -> 通过 Val 组合 Page 与局部组件
  -> 页面独占的事务化增量图
  -> 标准化小程序树与带 revision 的 diff
  -> 有序宿主调度与带确认的 Skyline 渲染
```

应用只导入 `lampclaw/minimoon`。作者不直接编写 `setData`、JavaScript 桥接、
可变 Signal、投影字段或 renderer patch；局部组件仍可在 keyed 或动态 `Val`
分支中拥有自己的状态机。

## 安装与创建应用

准备 registry 包期间，先从 Minimoon checkout 安装 CLI：

```bash
moon install --path src/cmd/minimoon
minimoon init /tmp/my-app --minimoon-root "$PWD" # 本地 workspace 模式
cd /tmp/my-app
bun install
minimoon build .
minimoon verify .
```

不传 `--minimoon-root` 时，`minimoon init /tmp/my-app` 会生成独立 registry
consumer：`moon.mod` 保留带版本的 `lampclaw/minimoon` 依赖，且不会生成
`moon.work`。发布前会从实际压缩包验证候选包；真正发布仍是独立的 release 操作。

CLI 内嵌一个面向生产起步的双页 `starter`，并支持增量开发和类型化脚手架：

```bash
minimoon dev .
minimoon add page activity_log --after home --title "Activity Log"
minimoon add component status_badge --page home
```

## 编写模型

每个配置的页面包导出 `program() -> Page`：

```moonbit
pub enum Msg { Increment }

fn view(value : Int, emit : @minimoon.Emit[Msg]) -> @minimoon.Node {
    @minimoon.div([
      @minimoon.h1(value.to_string()),
      @minimoon.button(
        on_tap=emit(Increment),
        event_key="increment",
        "+1",
      ),
    ])
}

pub fn program() -> @minimoon.Page {
  @minimoon.elmish_page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    model=0,
    update=(current, message, _emit) => {
      match message {
        Increment => @minimoon.no_cmd(current + 1)
      }
    },
    view~,
  )
}
```

`elmish_page` 覆盖常见的 model-first 页面；局部或带输入的组合使用
`@minimoon.create_state`、`create_state_with_init` 或
`create_state_with_input`，每个构造器都返回 `(Val[Model], Emit[Msg])`。
update 通过 `no_cmd`、`with_cmd` 或 `with_cmds` 返回 `(Model, Cmd)`。
`create_pure_state` 用于纯更新，`create_variable` 用于函数式更新。
`create_resource` 在作用域提交后启动一次加载并直接返回 `Val[Status[T]]`；
第一个成功提交的终态获胜，重试与刷新由应用状态显式建模。

公共边界的 `Cmd` 是不透明、非泛型值。可以组合 `none`、`batch`、`delay`、
`effect`、`perform`、`attempt`，也可以调用 `login`、`get_storage`、`request`、
`navigate_to` 等根函数。消息和宿主结果 sink 使用可调用的 `Emit[T]`；
`Emit::map` 可以适配子级 payload，但不会暴露可变状态。

`Emit` 只携带私有的 graph/state 地址；对应 dispatcher 存放在 graph 独占的
分代 registry 中。因此命令若在其他页面 graph、所属 scope 被回收后或页面销毁后
执行，都会确定性地变成 no-op。订阅条目采用同样的可回收所有权：被保留但隐藏的
scope 暂停订阅，而被删除或淘汰的 scope 会释放对应 registry 槽位。

`Val` 是单个页面图中的增量值，而不是可变 Signal。`Val::map2` 到 `map9`
组合任意独立输入，`Val::view2` 到 `view9` 专门组合生成 `Node`；
`assoc`/`assoc_by` 保留 keyed 局部所有权；`switch` 在标签变化时
替换分支；`enumerate` 缓存有限标签域；`enumerate_bounded_by` 为无界标签域增加
事务化 LRU 容量限制。

动态分支初始化只有在候选投影提交后才会发布；被拒绝的分支永远不会执行初始化
命令，已提交的初始化则会在 graph pull 之外安全排空，并允许继续创建级联分支。

状态、事件路由、订阅、分支缓存、标准化子树和渲染树作为同一个事务提交；候选
被拒绝时会完整恢复上一事务。

可选包保持生产依赖显式。`lampclaw/minimoon/testing` 通过每次重新定位的语义
scope 和原生形状交互来查询并驱动真实的标准化小程序树；无样式的
`lampclaw/minimoon/components` 提供受控与自持状态的
Disclosure、单选/多选 Accordion、Tabs、Dialog、Sheet 与 Dropdown；
`lampclaw/minimoon/components/styles` 将它们绑定到可选的 `minimal-v2`
主题。所有具有任意 `Node` 内容插槽的组件还提供兼容新增的 `_with_input` 形式，
以组合响应式子插槽而不改变既有静态 API。根包 `Semantics` 会把 dialog/menu role、checked、modal、orientation、
popup 关联、label 与 description 送入受校验的 renderer protocol；`input` 与
`textarea` 的 focus、blur、confirm payload 也保持类型化。

## 小程序边界

配置使用 App Contract v7。`componentTheme` 可省略；省略时不会增加内置组件
CSS：

```json
{
  "schemaVersion": 7,
  "name": "my_app",
  "componentTheme": "minimal-v2",
  "pages": [
    { "package": "src/pages/home" },
    { "package": "src/pages/details" }
  ]
}
```

可选的 `devtoolsChecks` 用于声明有序的应用专属人工检查项；生成器会将其追加到
`generated/smoke_checklist.json`，并随 CI 开发者工具交接产物一起交付。

生成应用只有一份 `minimoon.runtime.js`、一份 `minimoon.host.js`、一份
`minimoon.protocol.js`、一份压缩的 `minimoon.initial.js`、一份共享
`minimoon.templates.wxml` 和一份全局 `app.wxss`。每个页面只保留很小的索引注册
bridge、模板导入、JSON 与空页面 WXSS。

宿主调度器立即执行第一个入口，同一时间只允许一个渲染在途并保持入口顺序。tap
等离散事件始终无损、有序；只有等待确认期间相邻且同 key 的 scroll 事件会折叠为
最新 payload，tap 会阻断合并。整批事件会先全部解码，再修改任何状态。渲染通过
commit sentinel 和 `setData` callback 确认；三秒超时后只执行一次权威 snapshot
重试，第二次失败则关闭该页面调度器。队列深度、合并数量、确认延迟、重试、超时与
COW shadow copy 工作量都可通过 renderer stats 观察。

Runtime ABI v10 还为页面所有的局部异步命令提供有序宿主唤醒。挂起的 `perform`
和 `attempt` 无需等待下一次点击或生命周期入口即可排空结果；页面销毁会取消结果
投递，而框架 `delay` 的宿主计时器会被物理清除。

## 构建与真机验证

```bash
minimoon build . --mode dev
minimoon verify .
minimoon build . --mode release
```

将未修改的 `dist/` 导入微信开发者工具。使用 Skyline，开启 ES6 转 ES5、增强
编译与代码压缩（`setting.es6=true`、`setting.enhance=true`、
`setting.minified=true`），线上最低基础库设置为 3.17.0 或更新版本。

真机证据只对完全相同的 release 字节有效。完成清单后，记录真实工具版本与时间：

```bash
minimoon devtools record . \
  --status passed \
  --recorded-at <实际时间> \
  --tool-version "<实际版本>" \
  --notes "Minimoon 0.1.0 checklist passed"
minimoon verify . --release
```

`generated/devtools.evidence.json` 仅保存在本机并由 Git 忽略；其中的时间、
工具版本、备注和验证结果不会被提交，也不会由 CI 上传。

## 仓库门禁

```bash
moon info
moon fmt --check
moon test --target native
moon test --target js
bun run check:coverage
bun run check:docs
bun run check:api
bun run check:candidate
git diff --check
```

`check:api` 精确锁定 `0.1.x` 根包接口，并仅允许 components、styles 与
testing 可选包增加接口。
`check:candidate` 是可在 Linux 执行的自动候选交接门禁；即使本机已有证据，
它也始终把受跟踪报告恢复为 candidate 状态。本地作出 release 决策时，依次
运行 `bun run check:all` 与 `bun run check:mvp`，两者都要求与当前指纹匹配的
开发者工具证据；暂存改动前再运行一次 `check:candidate`。
`moon package --frozen --list` 同时约束 registry 包白名单、250 KiB
硬上限与至少 16 KiB 的预留余量。

工具链下限已于 2026-09-04 使用 `moon 0.1.20260827` 与 `moonc v0.10.11`
重新验证。仓库和生成的
starter 都固定使用 Node `26.8.1` 与 Bun `1.4.0`。唯一独立维护的 JavaScript
是 `scripts/bridge/weapp_tailwindcss_adapter.mjs`；生产和验证宿主源码由
MoonBit 模板持有，提交的小程序 JavaScript 均为生成产物。

Minimoon `0.1.0` 仍属于 pre-1.0。产品版本由 `moon.mod` 与 `CHANGELOG.md`
定义，不使用 Git 版本标签。
