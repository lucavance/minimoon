# Minimoon

[English](README.md) · [快速开始](docs/guides/miniapp_quickstart.md) · [文档索引](docs/README.md)

用 MoonBit 开发微信 Skyline 小程序：描述页面、更新类型化状态，由 Minimoon
生成小程序文件。无需手写 JavaScript 桥接或 `setData`。

## 项目状态

核心 `lampclaw/minimoon 0.3.2` 与可选的 `lampclaw/minimoon_ui 0.2.0`
仍处于 1.0 之前的阶段。
[项目状态](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)
记录注册表可用性与发布证据。

## 已实现的主要能力

- 使用类型化事件、本地状态和导航编写页面与可复用组件。
- 使用类型化 HTTP 与可选的应用级共享状态构建有数据交互的应用。
- 通过可选的 Minimoon UI 编写原生、触控优先的界面；Starter 只依赖核心。

## 示例选择

<!-- minimoon:preview:start -->
下载或克隆本仓库后，将以下已提交的目录直接导入微信开发者工具即可体验。
打开现有产物无需安装 MoonBit、Node 或执行构建命令。

| 示例 | 用途 | 导入目录，相对仓库根目录 |
| --- | --- | --- |
| [草稿工作台](https://github.com/lucavance/minimoon/blob/main/examples/miniapp_draft_workbench/README.zh-CN.md) | 本地草稿、联机回显与生命周期：9 个页面、4 个原生 Tab — 工作台 / 草稿 / 联机 / 更多 | `examples/miniapp_draft_workbench/dist/` |
| [UI Showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.zh-CN.md) | 通过 6 个页面体验原生 UI 组件 | `ui/examples/showcase/dist/` |
<!-- minimoon:preview:end -->

启用 Skyline，使用基础库 **3.17.0** 或更新版本，并开启 ES6 转换、增强编译和压缩
（`setting.es6=true`、`setting.enhance=true`、`setting.minified=true`）。
按[开发者工具设置](docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)（英文）
在本地私有配置中填写自己的 AppID。修改源码或创建自己的 Starter 时，再准备以下开发环境。

## 开始之前

准备 `moon 0.1.20261023`／`moonc v0.10.17+d971670cd`、Node `>=26.12.1`、
全局 `vp 1.4.0`（当前源码环境），以及支持 Skyline 的微信开发者工具。
`vp` 管理 Node 和内部使用的 Bun `1.4.4`，无需单独安装 Bun。
[环境说明](docs/guides/miniapp_quickstart.md#prerequisites)（英文）包含版本检查与可选的 Git 源码流程。

## 创建第一个应用

完成环境设置后，在已有 Moon 工作区之外执行：

<!-- minimoon:onboarding:start -->
```bash
moon install lampclaw/minimoon/cmd/minimoon@0.3.2
minimoon --version
minimoon init my-app
cd my-app
moon update
vp install
minimoon build .
minimoon verify . --candidate
```
<!-- minimoon:onboarding:end -->

候选验证通过后，打开微信开发者工具，导入 **`my-app/dist/`**。
按[开发者工具设置](docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)
配置后运行小程序。

`my-app/` 必须不存在或为空。应用的 `moon.mod` 声明核心依赖，由 Mooncakes
解析；无需 `moon.work` 或框架源码目录。此流程不传 `--minimoon-root`。
`vp install` 安装应用的样式构建工具。

确认 `minimoon --version` 输出 `0.3.2`；如有其他版本，检查 PATH 中的旧 CLI。
参见[固定版本安装](docs/guides/miniapp_quickstart.md#install-a-specific-version)及
[已有应用升级步骤](docs/reference/compatibility_and_upgrades.md#upgrade-procedure)。
开发框架或使用尚未发布的改动时，使用单独的
[源码流程](docs/guides/miniapp_quickstart.md#create-from-the-current-source)。

你应看到 **Hello Minimoon**、初始值为 **0** 的计数器、名称输入框与 **Open details**。
点击 **+1** 后变为 **1**，进入 Details 后可以返回。
CLI 检查通过只代表自动化验证，不代表这些宿主交互已经通过。

### 第一次修改

打开生成应用的 `src/pages/home/page.mbt`，在 `program()` 的初始 Model 中
将 `name: "Minimoon"` 改为 `name: "My App"`。
在 `my-app/` 重新执行 `minimoon build .` 与 `minimoon verify . --candidate`，
冷启动小程序，标题应变为 **Hello My App**。

修改 `src/`，不要修改 `dist/` 或 `generated/`。
在应用目录运行 `minimoon dev .` 可监听并重新构建；它不是浏览器预览服务器。

## 页面代码是什么样的

下面是普通 `page`／`Val` 写法的简短示意，不用于直接替换 Starter
完整的 Home 页面及其导航、测试：

<!-- minimoon:counter:start -->
```moonbit
pub fn program() -> @minimoon.Page {
  @minimoon.page(
    id="home",
    route=@minimoon.route("pages/home/home"),
    title="Home",
    build=_ => {
      let (count, update_count) = @minimoon.create_variable(0)
      count.view(value => @minimoon.div([
        @minimoon.h1(value.to_string()),
        @minimoon.button(
          on_tap=update_count(current => current + 1),
          event_key="increment",
          "+1",
        ),
      ]))
    },
  )
}
```
<!-- minimoon:counter:end -->

`count` 是只读值，`update_count` 创建更新命令，`view` 描述显示内容。
Starter 已在页面的 `moon.pkg` 导入 `lampclaw/minimoon`。
复杂交互可以使用类型化 Model／Msg 更新；组件是普通函数，不要求建立对象层级。

## 接下来学习

1. [页面、状态与组件](docs/guides/miniapp_authoring_example.md)
2. [类型化 HTTP](docs/guides/http.md)
3. [导航与布局](docs/guides/native_navigation.md)
4. [应用级共享状态](docs/guides/shared_state.md)
5. [可选 Minimoon UI](https://github.com/lucavance/minimoon/blob/main/ui/README.zh-CN.md)

## 当前边界与下一步

Minimoon 面向微信 Skyline，不是浏览器 DOM 兼容层或通用跨平台渲染器。
UI 是可选依赖；业务后端、凭据和生产请求域名由应用自行配置。

近期重点是可靠的入门流程和发布准备。动态账号／工作区作用域、其他渲染目标
仍是延期方向，不承诺功能或日期。详细优先级见
[Roadmap](https://github.com/lucavance/minimoon/blob/main/docs/roadmap.md)，本页不重复维护任务清单。

## 贡献与内部原理

从[文档索引](docs/README.md)进入
[架构](docs/architecture.md)、[API 编写指南](docs/guides/api_ergonomics.md)、
[仓库验证与发布流程](https://github.com/lucavance/minimoon/blob/main/docs/operations/release_candidate_handoff.md)和
[宿主清单](docs/operations/miniapp_devtools_validation.md)。
完整仓库门禁与发布证据不是编写第一个应用的前置步骤。

许可证与 Rabbita／RUI 来源见 [LICENSE](LICENSE) 和
[第三方声明](THIRD_PARTY_NOTICES.md)。
