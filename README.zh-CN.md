# Minimoon

公共 `request` 支持 HTTP 方法、有序查询参数、请求头、JSON/表单/文本请求体及超时。
详见 [HTTP 契约](docs/reference/miniapp_host_capabilities.md#http-requests)。
仓库内运行 `bun run check:http-live` 可通过公共 API 验证生成的 Home 页面；
这不是微信真实宿主验收，也不会生成宿主通过证据。

[English](README.md) · [文档索引](docs/README.md) · [双语代码分析](https://github.com/lucavance/minimoon/blob/main/docs/code-analysis/README.md)

Minimoon 是面向微信小程序 Skyline 的 MoonBit UI 框架。`0.2.0` 以 Elm-style
编写模型为入口，采用 App Contract v9、runtime ABI v11、renderer protocol v8
和 CommonJS 小程序宿主边界。

```text
Model / Msg / update / Cmd / Sub
  -> 通过 Val 组合 Page 与局部组件
  -> 页面独占的事务化增量图
  -> 标准化小程序树与带 revision 的 diff
  -> 有序宿主调度与带确认的 Skyline 渲染
```

应用导入 `lampclaw/minimoon`，并可选用独立的 `lampclaw/minimoon_ui` 模块。
作者不直接编写 `setData`、JavaScript 桥接、
可变 Signal、投影字段或 renderer patch；局部组件仍可在 keyed 或动态 `Val`
分支中拥有自己的状态机。

## 安装与创建应用

使用已发布版本时，从 registry 安装匹配的 CLI，再创建独立应用：

```bash
moon install lampclaw/minimoon/cmd/minimoon@0.2.0
minimoon init /tmp/my-app
cd /tmp/my-app
bun install
minimoon build .
minimoon verify .
```

Registry 模式在 `moon.mod` 中保留 `lampclaw/minimoon@0.2.0`，不生成
`moon.work`。当前发布可用性见仓库的
[项目状态](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)。
本地框架开发时，在 Minimoon checkout 运行 `moon install --path src/cmd/minimoon`，
再执行 `minimoon init /tmp/my-app --minimoon-root "$PWD"`，显式创建绑定本地源码的 workspace。

CLI 内嵌一个面向生产起步的双页 `starter`，并支持增量开发和类型化脚手架：

```bash
minimoon dev .
minimoon add page activity_log --after home --title "Activity Log"
minimoon add component status_badge --page home
```

## 编写模型

未配置 `application` 时，页面包导出下例的 `program() -> Page`。
启用后，页面改为导出 `program(deps : @application.Deps) -> Page`，详见
[共享状态配置](docs/guides/shared_state.md)。

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

页面局部 `Emit` 携带私有的 graph/state 地址；对应 dispatcher 存放在 graph 独占的
分代 registry 中。因此命令若在其他页面 graph、所属 scope 被回收后或页面销毁后
执行，都会确定性地变成 no-op。订阅条目采用同样的可回收所有权：被保留但隐藏的
scope 暂停订阅，而被删除或淘汰的 scope 会释放对应 registry 槽位。

应用所有的 `Emit` 则指向 App 的领域状态机，允许页面跨页面/App 边界发送消息，
但只有页面事务提交后才从 outbox 投递。页面卸载不会让 App 地址失效，App 销毁才会。

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

## 可选 Minimoon UI

独立模块 `lampclaw/minimoon_ui 0.1.0` 依赖核心 `0.2.0`，以 `@ui` 导入。
它把 RUI 0.1.1 的组件能力适配为类型化小程序节点、页面独占状态、触控交互
和按需生成的 Vega WXSS。旧组件包与 minimal 主题仍保持兼容。
安装、能力映射和六页展示应用见
[UI 模块文档](https://github.com/lucavance/minimoon/tree/main/ui)。

核心 0.2 新增原生控件、触摸事件、布局测量和声明式 `layer`／`layer_root`。
构建期资源提供包生成 WXSS／SVG，不把资源字符串带入应用 JavaScript。
新产物需要重新验证 Skyline；候选状态不代表已经发布或通过真实宿主验证。

## 应用级共享状态

页面需要共享会话、偏好或请求状态时，可选用 `App[Deps]`。App builder 创建多个
独立的类型化领域状态机，页面通过 `PageContext.bind/select` 将 `Shared[T]` 绑定为
页面局部 Val，同时保留自己的 Model。App 所有的请求在页面卸载后继续，前台定时订阅在 Hide
时暂停；显式 App 销毁会取消任务并忽略旧回调。不强制使用一个全局 Model。
副作用归执行 `Cmd` 的 runtime 所有，而非结果 emitter；要让请求跨页面卸载存活，
应向 App 发送业务消息，再由 App update 返回请求命令。
配置、生命周期和验收见 [共享状态指南](docs/guides/shared_state.md)。

## 小程序边界

配置使用 App Contract v9。`componentTheme` 可省略；省略时不会增加内置组件
CSS：

```json
{
  "schemaVersion": 9,
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
启用 `application` 时另生成 `minimoon.app.js`，负责 App 所有的调度器与生命周期；
未启用时保留 `App({})` 注册。

宿主调度器立即执行第一个入口，同一时间只允许一个渲染在途并保持入口顺序。tap
等离散事件始终无损、有序；等待确认期间相邻、同 key 且同类型的 scroll、changing，
以及同 key 且同一触点的 touchmove 可以折叠为最新 payload，tap 会阻断合并。整批事件会先全部
解码，再修改任何状态。渲染通过
commit sentinel 和 `setData` callback 确认；三秒超时后只执行一次权威 snapshot
重试，第二次失败则关闭该页面调度器。队列深度、合并数量、确认延迟、重试、超时与
COW shadow copy 工作量都可通过 renderer stats 观察。

Runtime ABI v11 还为页面所有的局部异步命令提供有序宿主唤醒。挂起的 `perform`
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
  --notes "Minimoon 0.2.0 checklist passed"
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

`check:api` 精确锁定核心 `0.2` 的根包与 resources 接口，编译冻结的 0.1 consumer，
并仅允许 components、styles 与 testing 可选包增加接口。UI `0.1` 为根包、
headless、theme 与 resources 分别维护可加性接口快照。
`check:candidate` 是可在 Linux 执行的自动候选交接门禁；成功完成后，即使本机已有证据，
它也会把受跟踪报告恢复为 candidate 状态。覆盖率由上方独立的 `check:coverage`
门禁验证。本地作出 release 决策时，依次
运行 `bun run check:all` 与 `bun run check:mvp`，两者都要求与当前指纹匹配的
开发者工具证据，覆盖核心四页示例与 UI 六页 showcase。发布及暂存前再运行
`check:candidate` 恢复公开报告，并要求两套指纹不变、源码 checkout 干净。
[发布操作指南](docs/operations/release_candidate_handoff.md) 定义核心/UI 的发布顺序及
纯 registry consumer 检查。
仓库归档门禁先执行 `moon package --frozen --list`，再检查每个模块的 registry 包
白名单与独立评审的硬上限：核心包 280 KiB、至少预留 8 KiB；UI 包
250 KiB、至少预留 16 KiB。这些是仓库预算，不是注册表服务的限制。

仓库检查默认在旁边的 `../.minimoon-check-tmp/` 创建独立运行目录，使用仓库父目录
所在的磁盘，且不继承当前 Moon 工作区。可用 `MINIMOON_CHECK_TMPDIR` 指定绝对路径
或相对仓库的路径。父进程在成功、失败或检查子进程崩溃后清理本轮目录，并向工具
传递该目录作为 `TMPDIR`、`TMP` 和 `TEMP`。详见[临时存储说明](docs/operations/release_candidate_handoff.md#validation-temporary-storage)。

工具链下限已于 2026-09-04 使用 `moon 0.1.20260827` 与 `moonc v0.10.11`
重新验证。仓库和生成的 starter 支持 Node `>=24.20.0`；CI 验证 24.20.0
最低边界与 26.8.1 主环境，Bun 固定为 `1.4.2`。唯一独立维护的
JavaScript 是 `scripts/bridge/weapp_tailwindcss_adapter.mjs`；生产和验证宿主
源码由 MoonBit 模板持有，提交的小程序 JavaScript 均为生成产物。

Minimoon `0.2.0` 仍属于 pre-1.0。产品版本由 `moon.mod` 与 `CHANGELOG.md`
定义，不使用 Git 版本标签。
