# Conformance：核心框架验收示例

这是 Minimoon `0.2.0` 的核心框架示例：**四个原生 Tab，三个有明确任务的二级页面**。
使用 App Contract `11`、runtime ABI `13`、renderer protocol `8`；
独立 UI 模块的[六页 Showcase](../../ui/examples/showcase/README.md)不在本轮整合范围内。

## 页面归属

| 页面 | 源码目录（相对本示例） | 主任务 | 深入入口 |
| --- | --- | --- | --- |
| 首页 | `src/pages/showcase` | 产品介绍、本地计数与重置、三个 Tab 快捷入口 | 交互／平台／应用 |
| 交互 | `src/pages/interaction` | 原生控件、局部组件、Disclosure／Accordion／Tabs、弹层和菜单 | 状态与渲染实验 |
| 平台 | `src/pages/platform` | 登录、存储、提示、位置、媒体、十种 HTTP 场景 | 请求生命周期 |
| 应用 | `src/pages/application` | 唯一完整的共享计数／请求／草稿结果面板 | 草稿编辑、请求生命周期 |
| 请求生命周期 | `src/pages/request_lifecycle` | 隐藏、卸载与 App 请求寿命的对照 | 打开或替换为草稿编辑 |
| 状态与渲染实验 | `src/pages/runtime_lab` | 增量更新、keyed 身份、受控同步、异步、释放、实例隔离 | 第二个独立实验实例 |
| 草稿编辑 | `src/pages/draft_editor` | 校验、类型化 HTTP echo、返回 | 返回原页面；直接进入时回首页 |

路由均为 `pages/<目录名>/<目录名>`。旧的 `capabilities`、
`capability_probe`、`lab`、`details` 路由已迁移，不提供别名。
这不改变 Starter 的 `home`／`details`。

页面不导入另一个页面的生产实现：
`scenes/interaction` 与 `scenes/composition` 组合交互场景，
`components/shared_app` 提供按角色裁剪的共享状态视图，
`src/app` 只定义类型化领域状态和命令。所有页面工厂接收 `Deps`，
但首页、交互、平台和运行实验不显示共享控制台。
草稿编辑只观察共享计数／请求并提供一次计数操作；
请求生命周期只显示 App 请求的启动／清除对照，不复制 HTTP 场景目录。

## 构建与查看

在仓库根目录执行：

```bash
bun run minimoon verify examples/miniapp_conformance_app --candidate
```

将原样生成的 `dist/` 导入微信开发者工具，按[宿主验收清单](../../docs/operations/miniapp_devtools_validation.md)验证。
当前候选产物的自动化状态在 `generated/verify_report.json`，它不是微信宿主通过证明。
CI 交付包仍为 `minimoon-devtools-<commit>`，UI 交付包仍为
`minimoon-ui-devtools-<commit>`；见[交付手册](../../docs/operations/release_candidate_handoff.md)。

所有页面共用 `shared/shell`：顶部深蓝固定导航为胶囊和状态栏预留真实像素空间；
下方蓝色 Hero 随内容滚动，以浅弧形底边收尾，文字底部保留留白。
它不改变已使用的导航高度计算、缺失指标时的 88px 回退或底部安全区计算。
资源由 MoonBit 的 `src/resources` 提供；不新增图片依赖、手写 JavaScript 或运行时网络素材。
弧形、长标题、键盘、短窗口和横竖屏均须在 Skyline 中重新检查。

## 三条验收路径

1. **交互 → 状态与渲染实验**
   先体验控件与基础组件，再进入身份／释放实验。交互页不再提供“展开完整 Lab”。
   在 reactive Accordion 中计数后，点击“更新父层”，折叠并重开，计数仍保留。
   实验页的同类控件只用于重排、移除恢复和结构同步，不重复完整组件目录。
2. **平台 → 请求生命周期 → 草稿编辑 → 返回**
   平台的十种 HTTP 场景使用公开 `https://httpbingo.org`：GET 重复／特殊字符查询、
   JSON／form POST、text PUT、DELETE、HEAD、OPTIONS、400、500、超时。
   展开响应详情查看筛选后的合成 echo；非 2xx 为 loaded，超时为 failed。
   生命周期页的约 2 秒页面请求在 NavigateTo 隐藏后仍可完成，返回保留页内标记；
   RedirectTo 卸载页面后请求必须取消，旧响应不得写入。**切 Tab 不是卸载验收。**
3. **应用 → 草稿编辑 → 应用**
   在两个页面对照共享计数。空标题不得发送 HTTP；有效草稿 POST 到公开
   `https://httpbingo.org/post`，编辑页显示提交状态，应用页显示类型化回显。
   这不是持久保存；编辑或卸载会拒绝旧回复。技术区默认折叠，
   可展开查看来源和访问次数。缺失或空 `from` 必须在创建前失败，不能闪现预览数据。
   从应用进入生命周期页，启动 App 请求并替换为编辑页：请求应继续，
   无需再次触摸即可在编辑页或应用页看到结果。清除后旧响应不能覆盖 idle。

平台中的存储值、每项能力的错误和 HTTP 详情互不覆盖。
`bun run check:http-live` 会对生成的**平台页**执行公共 API 测试；
离线回归另外加载生命周期页检查取消、重复回调和旧实例响应。
传输适配模拟不等于真宿主验收；`urlCheck=false` 不证明生产域名或完整 HTTPS 条件。

## 必须保留的回归覆盖

| 行为 | 主要自动化位置 |
| --- | --- |
| 页面内容归属、无重复控制台、Tab 状态保持和 resize 身份 | `src/tests/tabs_test.mbt` |
| 基础组件语义、reactive 子状态 | `src/pages/interaction/page_test.mbt` |
| 请求标记、导航、取消与页面寿命 | `src/pages/request_lifecycle/page_test.mbt`；仓库 `http_probe.mbt` |
| 草稿校验、类型化 echo、编辑／重发／卸载拒绝旧回复 | `src/pages/draft_editor/page_test.mbt` |
| keyed 重排、输入身份、局部组件释放、异步时序和隔离 | `src/pages/runtime_lab/page_test.mbt`、`page_wbtest.mbt` |
| 共享 3000 次更新、隐藏追平、App 请求寿命和旧回复 | 仓库 `src/internal_host_validation/application_smoke.mbt` |
| 实际生成桥接的载荷、导航、set／splice／move／fallback 和异步 | 仓库 `src/internal_host_validation/validation_sources.mbt` |

运行实验还须人工检查原生焦点、光标和选区：点击 `Arm focused reorder (10s)`，
重新聚焦并等待，只有 Item C 移动，输入身份与选区不变；统计增量为一次 move、
两次 host write，无 set／splice／replacement／fallback。
受控重置只有 scalar set；结构同步后 picker 和 swiper 保持同一个逻辑选项。
delay 600ms、perform 250ms、attempt 400ms 无需再次操作即可完成；
启动后立即退出不得产生迟到 UI、错误或警告。

本轮改变核心产物和清单，旧核心指纹的宿主记录不能复用。
按新指纹分别记录模拟器、真机预览和真机调试的真实结果；
未实际执行的模式明确标记未验证。不要手工修改或提交
`generated/devtools.evidence.json`。未改变指纹的 UI 记录仍只对该 UI 产物有效。
