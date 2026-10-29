# 持续维护的验证示例

[English](README.md)

仓库分别维护核心与 UI 示例，它们也分别承担真实宿主验证。

## 直接体验示例

<!-- minimoon:preview:start -->
下载或克隆本仓库后，将以下任一目录直接导入微信开发者工具。
打开已有产物无需安装 MoonBit、Node 或执行构建命令。

| 示例 | 页面数 | 原生 Tab 数 | 覆盖内容 | 导入目录，相对仓库根目录 |
| --- | ---: | ---: | --- | --- |
| [`miniapp_draft_workbench`](miniapp_draft_workbench/README.zh-CN.md) | 9 | 4 | 工作台 / 草稿 / 联机 / 更多; 本地草稿增删改查、类型化回显、App/Page 生命周期与四个能力实验室 | `examples/miniapp_draft_workbench/dist/` |
| [UI Showcase](../ui/examples/showcase/README.zh-CN.md) | 6 | 0 | 全部 64 个 RUI 组件族及 Form/Theme、原生控件、弹层、触控测量、资源和所有权 | `ui/examples/showcase/dist/` |
<!-- minimoon:preview:end -->

启用 Skyline，使用基础库 **3.17.0** 或更新版本，并开启 ES6 转换、增强编译和压缩。
按[开发者工具设置](../docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools)（英文）
在本地私有配置中填写自己的 AppID。

两个示例各有独立的开发者工具导入目录与产物指纹。共享宿主发生变化时，两者均需复验。
`swiper` 是待验证控件；应用主要通过真实页面导航组织内容，Runtime Lab
页面使用纵向 `scroll-view` 承载较长的交互测试。

`minimoon init` 内嵌的应用源码独立放在 [`templates/starter`](../templates/starter/)。
创建自己的应用请参照[快速上手](../docs/guides/miniapp_quickstart.md)（英文）；
通过草稿工作台和 UI Showcase 探索框架能力，无需复制它们的全部内容。

## 修改源码与重建

先准备[开发环境](../docs/guides/miniapp_quickstart.md#prerequisites)（英文），
修改选定示例的源码，再按其 README 重建。`minimoon init` 创建的双页 Starter
需要先构建，才能导入其产物。

## 维护者验收

完整仓库候选检查从仓库根目录运行：

```bash
vp run --no-cache check:candidate
```

`generated/verify_report.json` 是纳入版本管理的自动化候选记录。
`generated/devtools.evidence.json`（如存在）是绑定指纹的本地真实宿主记录，
被 Git 忽略。文档不复制产物指纹或本地验收结果。
