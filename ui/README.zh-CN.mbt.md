# Minimoon UI

[English](README.md)

面向 Minimoon 的原生触控 Skyline 组件。模块 `lampclaw/minimoon_ui 0.2.0`
声明核心依赖 `lampclaw/minimoon 0.3.0`。
注册表可用性和发布记录见[项目状态](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)。
当前源码有独立的工具链固定版本；已发布归档保持不可变。
现有调用继续受支持，Nova 是默认视觉方案；使用 `theme(preset=VegaV1)` 保留旧方案。

当前参考 RUI 0.3.6，来自 Rabbita 提交
`7d5940fed9b1ba795c84582394024233997ec267`。历史 RUI 0.1.1 的 517 符号映射
与新的根包／Markdown 655 符号映射并存。组件库使用公开的 Minimoon 节点与 Val 组合，
不依赖 Rabbita 浏览器运行时。MIT 声明和上游视觉方案归属保留在 [LICENSE](LICENSE) 与
[第三方声明](THIRD_PARTY_NOTICES.md)。版本变更见[更新日志](CHANGELOG.md)（英文）。

## 直接体验 Showcase

<!-- minimoon:preview:start -->
下载或克隆仓库后，在微信开发者工具中直接导入 **`ui/examples/showcase/dist/`**。
打开已提交的产物无需安装 MoonBit、Node 或执行构建命令。
[六页 Showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.zh-CN.md)
覆盖全部 64 个组件族及 Form 和 Theme。
<!-- minimoon:preview:end -->

启用 Skyline，使用基础库 **3.17.0** 或更新版本，并开启 ES6 转换、增强编译和压缩。
按[开发者工具设置](https://github.com/lucavance/minimoon/blob/main/docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)（英文）
仅在本地私有配置中填写自己的 AppID。修改源码或在自己的应用中使用 UI 时，再准备以下环境。

## 安装

当前源码使用 `moon 0.1.20261023`／`moonc v0.10.17+d971670cd`、源码 CLI、
全局 `vp 1.4.0`、Node `26.12.1` 和 Bun `1.4.4`，要求 Node `>=26.12.1`。
已发布归档保留发布时的要求，见[兼容表](https://github.com/lucavance/minimoon/blob/main/docs/reference/compatibility_and_upgrades.md#packaging-and-javascript-dependencies)（英文）。
按[环境说明](https://github.com/lucavance/minimoon/blob/main/docs/guides/miniapp_quickstart.md#prerequisites)（英文）准备环境，
无需另外安装 Bun 或本地 `vite-plus`。先在[项目状态](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)
确认注册表可用性；使用尚未进入已发布归档的开发改动时，显式配置源码工作区。

在应用的 TOML 风格 `moon.mod` 中添加两个模块：

```moonbit
import {
  "lampclaw/minimoon@0.3.0",
  "lampclaw/minimoon_ui@0.2.0",
}
```

在页面的 `moon.pkg` 中导入组件包：

```moonbit
import {
  "lampclaw/minimoon" @minimoon,
  "lampclaw/minimoon_ui" @ui,
}
```

声明已发布依赖后运行 `moon update`。本仓库通过 `moon.work` 本地解析两个模块；
开发工作区也可以同时包含应用与两个模块目录。仅使用注册表的应用应移除这些本地覆盖。
注册表状态统一以项目状态记录为准。

在 App Contract v11 中启用构建资源：

```json
{
  "schemaVersion": 11,
  "name": "ui_app",
  "resources": [
    {"package": "lampclaw/minimoon_ui/resources", "features": []}
  ],
  "pages": [{"package": "src/pages/home"}]
}
```

空特性列表包含完整资源包；非空列表如 `["button", "dialog", "slider"]` 只选择指定组件
及其资源依赖。未知特性会使构建失败。原生资源提供器导出 WXSS/SVG，不导入应用 JavaScript。
核心不依赖 UI 模块。schema `8`、`9`、`10` 需迁移到 `11`；生成产物使用
Contract v11/runtime ABI v13。结合共享状态时，按[App 设置](https://github.com/lucavance/minimoon/blob/main/docs/guides/shared_state.md)（英文）
启用应用根并让页面工厂接收 `Deps`；UI 根仍归页面所有。

特性选择控制资源组，不做逐组件 CSS tree shaking：基础／复合样式和六个主题图标共享，
按需包含表单样式。资源清单确定且可复现，但选择单一特性不会只生成它的选择器。

## 升级现有 UI 应用

将 CLI 与直接核心依赖升级至 `0.3.0`，UI 升级至 `0.2.0`；UI 自身也声明核心 `0.3.0`。
在 `devEngines.runtime` 中设置 Node `26.12.1`，`engines.node` 设为 `">=26.12.1"`，
`devEngines.packageManager` 中设置 Bun `1.4.4`。现有样式 `package.json` 使用
weapp-tailwindcss `5.6.3`、Tailwind `4.3.3` 和 PostCSS `8.5.32` 及对应 override；
运行 `vp install` 更新锁文件。旧 CLI/core `0.2.5`／UI `0.1.3` 归档保持不可变。
`minimoon build` 不会改写这些配置。按新编译器要求使用显式包限定符和公开 trait 扩展。
完成[升级步骤](https://github.com/lucavance/minimoon/blob/main/docs/reference/compatibility_and_upgrades.md#upgrade-procedure)（英文）后，
重新构建全部资源和生成产物；旧指纹不能验证新字节。

## 页面所有权

在页面构建器内创建一个 UI 根：

```moonbit
pub fn program() -> @minimoon.Page {
  @minimoon.page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="UI",
    capabilities=[@minimoon.MeasureNodes],
    build=page => @ui.root(page, context => {
      @ui.dialog(
        context,
        id="welcome",
        title="Welcome",
        trigger_label="Open",
        content=@minimoon.Val::constant(@minimoon.text("Hello Skyline")),
      )
    }),
  )
}
```

`UiContext` 与通知归页面所有。锚定弹层、自定义触控控件和消息滚动测量需声明
`MeasureNodes`。组件 ID 应唯一且仅包含字母、数字、下划线或连字符。
组件接收类型化回调与响应式内容；子状态在节点渲染回调之外创建。

原生事件可能以一个预解码批次到达。相对操作须在分发时读取状态：使用 Elm 消息或
`emit(current => current + 1)`，避免用渲染时捕获的值计算替换状态。
UI 控件内部也遵循此规则，包括多选与连续切换。

交互组件提供受控状态、自有状态便捷形式或显式 provider 作用域。弹层打开时，
`Val[Node]` 插槽仍保持响应式；`@ui.stack` 组合独立组件值。
UI 根将声明式弹层提升到滚动／裁剪区域之外，不会在全局注册表中保留已移除的 Val 作用域。

每页渲染一次 `toaster(context)` 或 `sonner(context)`；两者呈现相同队列。
`toast(context, toast_notice(...))` 创建命令。页面隐藏时定时器暂停，释放时回收。

## 包与定制

- 默认包：组件构建器、受控 API 和复合 provider。
- `/headless`：日期选择、位置计算、滑块和尺寸调整算法。
- `/theme`：类型化 Light/Dark 配色、Ltr/Rtl 方向和 Nova/VegaV1 预设。
- `/markdown`：可选 CommonMark、表格／任务／删除线／脚注、原生行内布局和链接／锚点回调，见 [Markdown](src/markdown/README.mbt.md)（英文）。
- `/resources`：仅用于构建的 WXSS/SVG 提供器与特性清单。

向 `root(theme=...)` 传入响应式 Theme 可切换主题和方向。类名使用 `mmui-*`，
变量使用 `--mmui-*`；class/style 与内容插槽支持原生定制。
核心现有组件和最小主题继续独立受支持，不经由 UI 模块重定向。

悬停预览使用点击／长按弹层；上下文菜单提供长按以外的点击入口。
Kbd 展示快捷键提示，不监听桌面键盘。Chart 提供容器、图例与提示，不包含图表引擎。
原生导航接收 MiniApp Route 值，不接收浏览器 URL。
Form/Field 展示应用拥有的校验状态；Attachment 不负责上传后端。

## 验证与迁移

仓库维护的[迁移映射](https://github.com/lucavance/minimoon/blob/main/ui/docs/migration.md)（英文）与
机器可读 API 清单区分已实现等价项、合并 API、原生替代和未完成内容。
组件名或展示章节本身不能证明全部上游行为。

[六页 Showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.zh-CN.md)
覆盖全部 64 个组件族及 Form 和 Theme；它独立于核心九路由草稿工作台，也不为默认 Starter 增加依赖。

从仓库根目录执行：

```sh
moon test ui/src --target native
moon test ui/src --target js
vp run --no-cache check:coverage
vp run --no-cache check:candidate
```

候选验证不等于真实宿主证据。将精确的 Skyline 产物导入微信开发者工具验收清单，
把绑定指纹的本地证据保留在 Git 忽略范围。模块版本本身不表示发布或宿主验收通过。

修改 Showcase 源码后，从仓库根目录重建和验证：

<!-- minimoon:rebuild:start -->
```bash
vp run minimoon verify ui/examples/showcase --candidate
```
<!-- minimoon:rebuild:end -->

该命令先构建 release 模式产物，再执行候选验证。
将 `ui/examples/showcase/dist/` 原样导入开发者工具，启用 Skyline，线上最低基础库至少为 3.17.0。
完成 `miniapp.minimoon.json` 的全部检查，包括多值控件、延迟弹层、移动侧栏手势和页面生命周期。
共享宿主字节变化时，复验所有受影响的示例；核心和 UI 的证据各自独立。

历史 API 映射覆盖 428 个上游函数和 89 个类型。原生替代是明确的设计选择：
Carousel 使用固定的原生 swiper 幻灯片；MessageScroller 使用 keyed 更新与显式内容版本，
不使用 DOM 溢出锚定；焦点选择器、浏览器快捷键与鼠标专属行为不做复刻。

MessageScroller 观察 keyed 追加／前插。流式修改已有内容而不改变消息键时，
递增 `content_revision`，让布局测量保留阅读位置。

## 维护者发布边界

发布需要单独明确授权。不要直接从仓库的 `ui/` 发布或执行 `moon -C ui publish`：
`moon 0.1.20260907` 上观察到的打包问题可能继承根 `.moonignore` 的 `/ui/` 排除规则，
导致空归档。仓库检查通过隔离源码副本打包，核对实际 ZIP、必需文件和消费者。

检查的源码归档为 `_build/publish/lampclaw-minimoon_ui-0.2.0.zip`。
只有在注册表核心 `0.3.0` 与全新消费者通过后，才能按授权从独立目录发布审阅的内容。
已发布 UI 归档保持不可变；上传前确认新版本尚未占用。

核心 `0.3.0`／UI `0.2.0` 的历史发布清单要求完整候选检查、两个 CI 任务、
匹配指纹的宿主验收和全新注册表消费者。开发者工具证据保留在本地，纳入版本管理的报告维持候选状态。
后续操作遵循[有序发布流程](https://github.com/lucavance/minimoon/blob/main/docs/operations/release_candidate_handoff.md#ordered-local-registry-publication)（英文）。
相关指南链接至仓库，因为注册表归档不包含 `ui/docs`。
