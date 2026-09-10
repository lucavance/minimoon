# Minimoon 草稿工作台

Minimoon Draft Workbench 是基于已发布核心 `lampclaw/minimoon 0.2.0` 的轻量示例：
**四个原生 Tab、一个编辑器、四个能力实验室，共九条路由**。
它同时承担核心框架 conformance 验收，不是账号系统或云笔记服务。

原工程 `miniapp_conformance_app` 已迁移为 `miniapp_draft_workbench`，
模块为 `lampclaw/miniapp_draft_workbench`；旧目录和路由不提供兼容别名。
独立 [UI Showcase](../../ui/examples/showcase/README.md) 和 Starter 不属于这次业务改造。

## 构建与打开

在仓库根目录运行：

```bash
bun run minimoon verify examples/miniapp_draft_workbench --candidate
```

导入 **`examples/miniapp_draft_workbench/dist/`**，不要导入源码目录。
沿用 Skyline、基础库至少 3.17.0，以及
`setting.es6=true`、`setting.enhance=true`、`setting.minified=true`。
仅在忽略的私人配置中填写 AppID。也可下载同一提交的 CI
`minimoon-devtools-<commit>` 交付包，核对校验和后导入其中的 `dist/`。

界面沿用深蓝固定导航、安全区计算和浅弧形 Hero；使用现有核心组件和
MoonBit 自有资源，不依赖 UI 模块、远程素材或手写 JavaScript。

## 页面分工

| 页面 | 源码包（相对 src） | 职责 |
| --- | --- | --- |
| 工作台 | pages/workbench | 数量、当前摘要、新建与继续编辑 |
| 草稿 | pages/drafts | 已保存列表、再次编辑、确认删除 |
| 联机 | pages/online | App 请求状态、类型化回显、失败重试 |
| 更多 | pages/more | 数据管理、演示指南、实验室入口 |
| 草稿编辑 | pages/draft_editor | 新建／按 ID 编辑／继续编辑、手动保存、本页试发 |
| 交互与组件 | pages/interaction | 原生控件、局部组件、Disclosure/Accordion/Tabs、弹层与菜单 |
| 平台与 HTTP | pages/platform | 登录、独立存储、位置、媒体、提示及十种公共 HTTP 场景 |
| 请求生命周期 | pages/request_lifecycle | 共享计数、延迟请求、隐藏与卸载对照 |
| 状态与渲染 | pages/runtime_lab | keyed 身份、焦点、结构同步、异步、释放与实例隔离 |

所有页面接收 App 的 `Deps`；页面不导入另一个页面的生产实现。
`app` 拥有类型化业务状态，`components/workbench` 组合公共视图，
`shared/shell` 负责布局。路由为 `pages/<名称>/<名称>`。
编辑器要求非空 `from`；`mode` 为 new/edit/resume，edit 还要求正整数 id。

## 三条闭环

1. **本地草稿**：新建 → 校验 → 保存 → 列表 → 编辑／删除 → 重启恢复。
   标题去除首尾空白后必填，最多 80 个 Unicode 字符；正文最多 2000 个，最多 50 条。
   使用独立版本化键 `minimoon-draft-workbench-v1`，最近保存的排在前面。
   写入成功才更新已保存集合；失败不误报成功。写入期间不能重复保存、删除或清空，
   但可以继续输入；新输入仍标记未保存。未知读取错误、坏数据或未知版本不自动覆盖，
   可重试；初始化需要确认覆盖原数据。
2. **联机回显**：编辑 → 后台发送 → 加载 → 类型化回显 → 失败重试。
   默认 POST 到公开 `https://httpbingo.org/post`，10 秒超时。
   只发送非敏感示例内容。**回显不等于云端保存**，不修改编辑器或本地数据。
   请求关联内容版本，修改、切换、删除或清空后旧响应不能替代新内容。
3. **跨页与生命周期**：App 持有一份编辑缓冲，返回后可继续编辑；
   四 Tab 展示同一状态来源。新建或切换其他草稿前确认丢弃未保存修改。
   编辑器“后台发送”归 App 所有，离开后联机页自动显示结果；
   展开“技术说明”中的“本页试发”归 Page 所有，卸载时取消。
   **隐藏不等于卸载**，切 Tab 不能代替卸载验收；App 存活不代表进程退出后还能请求。

未保存输入仅在本次 App 运行内保留；重启只恢复已保存草稿。
清空只覆盖工作台专用键，不清除平台实验室存储。没有账号、云存储、
自动保存、多人协作或持久化请求历史。

## 三分钟演示

- 先断网，在工作台新建“周末计划”，正文“去公园走走”；保存并从草稿列表重新打开，
  修改后保存。重启确认数据存在，再新建一条并删除，重启确认删除生效。
- 联网，打开保留的草稿，点击“后台发送”，立即进入联机页观察结果主动出现。
  请求足够快时可能已经完成，这是正常成功；慢请求所有权对比使用实验室的公共延迟接口。
- 再发送并立刻修改标题，确认回显不会覆盖输入；展开技术说明，试发后返回，
  检查 Network 中的取消和无迟到更新。断网发送验证失败反馈，恢复网络后重试。

不要为演示伪造成功。公共服务不可达时记录联机未通过，本地闭环仍可独立演示。
完整清单见 [微信宿主验收](../../docs/operations/miniapp_devtools_validation.md)。

## 验证与边界

自动化覆盖存储损坏／失败／重复操作、跨页缓冲、请求乱序／重复回调／解码失败、
Page 与 App 所有权，以及原有控件和渲染实验。
`bun run check:http-live` 验证十种平台 HTTP 场景，以及编辑器卸载后的 App 草稿回显；
使用真实公共 API，但传输适配仍是脚本，不等于真实微信宿主。

`generated/verify_report.json` 与 `release_summary.json` 是公开 candidate 记录；
`devtools.evidence.json` 私人且被 Git 忽略。新名称、九路由和新产物必须重新验收，
不能沿用旧核心证据；UI 的未变指纹仍只对应 UI。
不宣称生产请求域名或完整 HTTPS/TLS 验证，也不会自动发布包。
