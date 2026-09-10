# Minimoon

[English](README.md) · [快速开始](docs/guides/miniapp_quickstart.md) · [文档索引](docs/README.md)

用 MoonBit 开发微信 Skyline 小程序：描述页面、更新类型化状态，由 Minimoon
生成小程序文件。无需手写 JavaScript 桥接或 `setData`。

## 项目状态

核心 `lampclaw/minimoon 0.2.0` 与可选的 `lampclaw/minimoon_ui 0.1.0`
是 pre-1.0 候选版本。本页默认通过源码体验；**只有对应版本发布后**才使用
registry 安装。发布可用性见[项目状态](https://github.com/lucavance/minimoon/blob/main/docs/project_status.md)。
功能已实现、自动化检查、真实宿主验收与正式发布是不同阶段。

## 已实现的主要能力

- 使用类型化事件、本地状态和导航编写页面与可复用组件。
- 使用类型化 HTTP 与可选的应用级共享状态构建有数据交互的应用。
- 通过可选的 Minimoon UI 编写原生、触控优先的界面；Starter 只依赖核心。

## 开始之前

准备 `moon 0.1.20260904`／`moonc v0.10.12` 或更新版本、Node `>=24.20.0`、
Bun `1.4.2`、Git，以及支持 Skyline 的微信开发者工具。
已有 `moon 0.1.20260907` 无需降级。
[环境说明](docs/guides/miniapp_quickstart.md#prerequisites)包含版本检查与 CI 固定工具链。

## 创建第一个应用

选择空间充足的开发目录，将框架 `minimoon/` 和应用 `my-app/` 放在同一级。
在已能使用 MoonBit、Node 和 Bun 的终端中执行：

<!-- minimoon:onboarding:start -->
```bash
git clone https://github.com/lucavance/minimoon.git minimoon
cd minimoon
bun install --frozen-lockfile
moon update
moon install --path src/cmd/minimoon
minimoon --version
minimoon init ../my-app --minimoon-root "$PWD"
cd ../my-app
bun install
minimoon build .
minimoon verify . --candidate
```
<!-- minimoon:onboarding:end -->

`my-app/` 必须不存在或为空。生成的 `moon.work` 将应用绑定到同级源码，
不需要下载尚未发布的核心 registry 包；开发期间保留该源码目录。
独立的 [registry 安装流程](docs/guides/miniapp_quickstart.md#registry-installation-after-publication)
见快速开始。

向微信开发者工具导入 **`my-app/dist/`**，不是仓库根目录。
启用 Skyline、ES6 转 ES5、增强编译与压缩（`setting.es6=true`、
`setting.enhance=true`、`setting.minified=true`），线上最低基础库为 **3.17.0**。
自己的 AppID 只写入 Git 忽略的私有配置，见
[开发者工具设置](docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)。

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
5. [可选 Minimoon UI](https://github.com/lucavance/minimoon/blob/main/ui/README.md)

## 示例选择

| 示例 | 用途 |
| --- | --- |
| `minimoon init` 创建的 Starter | 开始自己的双页应用 |
| [草稿工作台](https://github.com/lucavance/minimoon/blob/main/examples/miniapp_draft_workbench/README.md) | 本地草稿、联机回显与生命周期：9 个页面、4 个原生 Tab — 工作台 / 草稿 / 联机 / 更多 |
| [UI Showcase](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md) | 通过 6 个页面体验原生 UI 组件 |

草稿工作台的平台实验室集中演示 HTTP 场景。在框架仓库运行
`bun run check:http-live` 可验证这些场景、编辑器卸载后的 App 草稿回显及
UI 表单回显，共 12 项；使用真实公共 Apifox Echo API，但不是微信宿主测试。

## 当前边界与下一步

Minimoon 面向微信 Skyline，不是浏览器 DOM 兼容层或通用跨平台渲染器。
UI 是可选依赖；业务后端、凭据和生产请求域名由应用自行配置。

近期重点是可靠的入门流程和发布准备。动态账号／工作区作用域、其他渲染目标
仍是延期方向，不承诺功能或日期。详细优先级见
[Roadmap](https://github.com/lucavance/minimoon/blob/main/docs/roadmap.md)，本页不重复维护任务清单。

## 贡献与内部原理

从[文档索引](docs/README.md)进入
[架构](docs/architecture.md)、[API 编写指南](docs/guides/api_ergonomics.md)、
[仓库验证与发布流程](docs/operations/release_candidate_handoff.md)和
[宿主清单](docs/operations/miniapp_devtools_validation.md)。
完整仓库门禁与发布证据不是编写第一个应用的前置步骤。

许可证与 Rabbita／RUI 来源见 [LICENSE](LICENSE) 和
[第三方声明](THIRD_PARTY_NOTICES.md)。
