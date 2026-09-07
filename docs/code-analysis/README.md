# Minimoon 双语代码分析 / Minimoon Bilingual Code Analysis

[项目文档 / Project docs](../README.md) · [下一篇：系统架构 / Next: System Architecture](01-SYSTEM-ARCHITECTURE.md) · [高清图表 / High-resolution diagrams](assets/diagrams/README.md)

本专题面向准备维护 Minimoon、审查运行时行为或设计下一阶段功能的工程师。它回答三个问题：应用代码如何变成 Skyline 页面，状态与局部组件为何能事务化更新，以及生成的 CommonJS 宿主如何在真实 `setData` acknowledgement 之前保持顺序和一致性。

> **English:**
>
> This suite is for engineers preparing to maintain Minimoon, review runtime behavior, or design the next feature phase. It answers three questions: how application code becomes a Skyline page, why state and local components update transactionally, and how the generated CommonJS host preserves ordering and consistency until a real `setData` acknowledgement arrives.

## 1. 分析边界 / Analysis Boundary

本文档分析当前源码、测试和生成产物。所有源码标记都以当前文件为准。

> **English:**
>
> The analysis covers the current source, tests, and generated artifacts. Every source marker resolves against the current tree.

所有结论都来自当前 Minimoon 源码、测试和生成产物。参考仓库的 MIT 许可双语文档仅提供组织方式和图表交付形式；本专题没有复制其业务内容或实现代码。

> **English:**
>
> Every conclusion comes from the current Minimoon source, tests, and generated artifacts. The MIT-licensed bilingual documentation in the reference repository supplied only an organizational and diagram-delivery pattern; this suite copies neither its domain content nor implementation code.

本专题及高清图是维护者资料，保留在源码仓库中，并通过 `moon.mod` 排除在 250 KiB Moon registry archive 之外；这不会影响应用依赖或生成的小程序字节。

> **English:**
>
> This suite and its high-resolution assets are maintainer material kept in the source repository. `moon.mod` excludes them from the 250 KiB Moon registry archive, so they do not affect application dependencies or generated MiniApp bytes.

## 2. 当前仓库形态 / Current Repository Shape

当前源码按 MoonBit package 划分公开 authoring API、事务图与 `Val` runtime、renderer、驻留 runtime、宿主模板以及生成和验证工具。一个维护中的 Conformance 应用负责发布级覆盖，独立 starter 作为 `minimoon init` 的嵌入输入。

> **English:**
>
> The current source is divided into MoonBit packages for the public authoring API, transactional graph and `Val` runtime, renderer, resident runtime, host templates, and generation and verification tooling. One maintained Conformance application provides release-level coverage, while a separate starter is embedded by `minimoon init`.

仓库形态直接由当前源码描述，产物预算由自动检查从当前生成文件计算；本文不保存会随日常维护失效的文件数、行数、提交数或静态字节快照。

> **English:**
>
> The current source describes the repository shape directly, while automated checks calculate artifact budgets from current generated files. This document does not preserve file counts, line counts, commit counts, or static byte snapshots that would drift during routine maintenance.

## 3. 一页代码图 / One-Page Code Graph

```mermaid
flowchart LR
    App[应用 Model / Msg / update<br/>Application state machine]
    Public[根包公开 API<br/>Root public API]
    Val[Val runtime<br/>增量组合 / incremental composition]
    Graph[Duplix graph<br/>事务与作用域 / transactions and scopes]
    Renderer[MiniApp renderer<br/>规范化与 diff / normalization and diff]
    Runtime[Resident runtime<br/>命令与订阅 / commands and subscriptions]
    Generator[App Contract v8 generator<br/>构建与验证 / build and verify]
    Host[CommonJS host scheduler<br/>队列、ack、COW / queue, ack, COW]
    Skyline[WeChat Skyline<br/>WXML / setData / wx.*]

    App --> Public
    Public --> Val
    Val --> Graph
    Graph --> Renderer
    Renderer --> Runtime
    Runtime --> Generator
    Generator --> Host
    Host --> Skyline
    Skyline -. event payload .-> Host
    Host -. decoded Msg .-> Runtime
```

[SVG](assets/diagrams/svg/README-1.svg) · [PNG 3×](assets/diagrams/png/README-1.png) · [Mermaid](assets/diagrams/source/README-1.mmd)

图中箭头不是九个独立进程。前六层主要是编译进应用 runtime 的 MoonBit 代码；generator 和 verifier 是 native 工具；host、protocol、WXML/WXSS 与页面 stub 是生成产物；Skyline 才是外部运行环境。理解“编译期所有权”和“运行期边界”的区别，是阅读本仓库最重要的起点。

> **English:**
>
> The arrows do not represent nine independent processes. The first six layers are primarily MoonBit compiled into the application runtime; the generator and verifier are native tools; the host, protocol, WXML/WXSS, and page stubs are generated artifacts; Skyline is the external runtime. Distinguishing compile-time ownership from runtime boundaries is the most important starting point for reading this repository.

## 4. 建议阅读路线 / Recommended Reading Paths

第一次接触项目时，依次阅读系统架构、authoring model、事务图、renderer 和 host scheduler；这条路线先建立不变量，再进入实现细节。准备修改 API 时，再查符号索引和生成发布章节。

> **English:**
>
> For a first pass, read system architecture, the authoring model, the transactional graph, the renderer, and the host scheduler in that order. This establishes invariants before implementation details. When changing APIs, follow with the symbol index and the generation/release chapter.

- [01 系统架构 / System Architecture](01-SYSTEM-ARCHITECTURE.md)
- [02 Authoring Model](02-AUTHORING-MODEL.md)
- [03 增量图与事务 / Incremental Graph and Transactions](03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md)
- [04 Renderer 与 Diff / Renderer and Diff](04-RENDERER-AND-DIFF.md)
- [05 Runtime 与 Host Scheduler](05-RUNTIME-AND-HOST-SCHEDULER.md)
- [06 构建、验证与发布 / Build, Verify, and Release](06-BUILD-VERIFY-AND-RELEASE.md)
- [07 符号索引 / Symbol Index](07-SYMBOL-INDEX.md)
- [08 风险、测试与性能 / Risks, Testing, and Performance](08-RISKS-TESTING-AND-PERFORMANCE.md)

> **English:**
>
> - Read chapters 01–05 for the execution model.
> - Use chapter 06 for artifact and release ownership.
> - Use chapter 07 as a change-impact lookup.
> - Use chapter 08 before accepting architectural or performance claims.

## 5. 证据标记 / Evidence Markers

每个源码片段前都有 `源码 / Source` 标记，包含仓库相对路径和关键符号。默认使用连续摘录；为突出控制流而压缩分支或省略瞬时标识时，会显式标为缩短摘录。文档验证器会在当前源码树中解析路径并核对符号，使过期引用直接导致检查失败。

> **English:**
>
> Every source excerpt has a `源码 / Source` marker containing a repository-relative path and key symbol. Excerpts are contiguous by default; branch compression or omitted transient identifiers are explicitly labeled as shortened excerpts. The documentation validator resolves each path and checks each symbol against the current source tree so stale references fail validation directly.

生成 JavaScript 片段使用 `生成产物 / Generated artifact` 标记，并同时指明拥有该逻辑的 MoonBit 模板。应用作者不应把生成片段当成扩展接口，也不应直接修改 `dist/` 来修复框架行为。

> **English:**
>
> Generated JavaScript excerpts use a `生成产物 / Generated artifact` marker and identify the MoonBit template that owns the logic. Application authors must not treat generated snippets as extension interfaces or patch framework behavior directly in `dist/`.

## 6. 与现有文档的关系 / Relationship to Existing Documentation

本专题解释“代码为何这样工作”，而现有 [Architecture](../architecture.md)、[MVP](../mvp.md)、[renderer reference](https://github.com/lucavance/minimoon/blob/main/docs/reference/miniapp_renderer.md) 和 [Developer Tools validation](../operations/miniapp_devtools_validation.md) 仍然是行为约束与操作流程的规范来源。发生冲突时，应以源码、生成报告和现有规范文档为准，并更新本专题。

> **English:**
>
> This suite explains why the code works as it does. The existing [Architecture](../architecture.md), [MVP](../mvp.md), [renderer reference](https://github.com/lucavance/minimoon/blob/main/docs/reference/miniapp_renderer.md), and [Developer Tools validation](../operations/miniapp_devtools_validation.md) remain normative for behavior and operations. If a conflict appears, source code, generated reports, and normative documents win, and this suite must be updated.
