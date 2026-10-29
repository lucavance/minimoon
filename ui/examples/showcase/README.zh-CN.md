# Minimoon UI Showcase

[English](README.md)

这个六页示例同时承担验证职责，使用 `lampclaw/minimoon_ui 0.2.0` 与
核心 `lampclaw/minimoon 0.3.2`。覆盖全部 64 个固定版本的 RUI 组件族，
以及 Form、Theme 和可选 Markdown；原生替代方式见[迁移映射](../../docs/migration.md)（英文）。

## 直接导入体验

<!-- minimoon:preview:start -->
下载或克隆本仓库后，在微信开发者工具中直接导入 **`ui/examples/showcase/dist/`**。
导入产物目录，而非源码目录。打开已提交的产物无需安装 MoonBit、Node 或执行构建命令。
<!-- minimoon:preview:end -->

启用 Skyline，使用基础库 **3.17.0** 或更新版本，并设置 `setting.es6=true`、
`setting.enhance=true`、`setting.minified=true`。
按[开发者工具设置](../../../docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)（英文）
仅在忽略的私人配置中填写自己的 AppID。
也可下载同一提交的 CI `minimoon-ui-devtools-<commit>` 交付包。
它独立于核心的 `minimoon-devtools-<commit>`；导入包内原样的 `dist/` 前，核对文件与 ZIP 校验和。

## 页面与交互

各页切换 Nova/Vega 时应保留状态。Foundation 包含原生 Markdown，Forms
包含四阶段属性重置探针，Overlays 包含打开状态下 Drawer 四侧边缘滑动手势。

Forms 页面仅向公开 `https://echo.apifox.com/post` 发送非敏感标题，超时为十秒。
类型化回显不代表持久化存储。`vp run check:http-live` 将此表单与核心 HTTP 场景一起验证，
使用传输适配脚本，不在微信宿主中执行。接口变更后，需要按新产物指纹重新验收。

## 修改源码与重建

先准备[开发环境](../../../docs/guides/miniapp_quickstart.md#prerequisites)（英文），
修改示例源码，再从仓库根目录运行：

<!-- minimoon:rebuild:start -->
```bash
vp run minimoon verify ui/examples/showcase --candidate
```
<!-- minimoon:rebuild:end -->

该命令会先构建 release 模式产物，再执行自动化候选验证。
完成后重新导入或编译同一目录；`dist/` 继续作为生成产物维护。

## 维护者验收与边界

生成的 `smoke_checklist.json` 包含 `miniapp.minimoon.json` 声明的全部应用专属检查。
按上述宿主设置，在 Skyline 模拟器、真机预览和真机调试中验收全部六个页面。
遵循[宿主验收流程](../../../docs/operations/miniapp_devtools_validation.md)与
[发布交接流程](../../../docs/operations/release_candidate_handoff.md)（均为英文）。

候选报告保留真实宿主验证为 pending。UI Showcase 的证据独立、绑定指纹且被 Git 忽略，
不能用草稿工作台的证据替代。验证命令会重新构建产物；仅在指纹不变时复用证据，
变化后重新验收所有受影响的示例。
