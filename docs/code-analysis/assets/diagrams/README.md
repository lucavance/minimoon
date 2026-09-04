# 高清图表资源 / High-Resolution Diagram Assets

本目录包含 Minimoon 双语代码分析专题的 21 张图表。SVG 可无损缩放，PNG 以 3× 比例导出。

> **English:**
>
> This directory contains the 21 diagrams used by the bilingual Minimoon code-analysis suite. SVG is losslessly scalable; PNG is exported at 3×.

## 重新生成 / Regeneration

```bash
bun run docs:diagrams
bun run docs:diagrams:check
```

默认使用固定的 Mermaid CLI 11.16.0 和仓库内受控的无沙箱渲染配置；也可以通过 `MMDC_BIN` 和 `PUPPETEER_EXECUTABLE_PATH` 指定本地工具。

> **English:**
>
> The command defaults to pinned Mermaid CLI 11.16.0 and the repository's controlled no-sandbox rendering configuration. `MMDC_BIN` and `PUPPETEER_EXECUTABLE_PATH` may select local tools.

## 图表索引 / Diagram Index

清单按正文出现顺序列出每张图的可缩放版本、高清位图和可审查源文件。

> **English:**
>
> The inventory follows document order and links each diagram's scalable export, high-resolution bitmap, and reviewable source.

| 文档 / Document | # | 章节 / Section | SVG | PNG | Mermaid |
| --- | ---: | --- | --- | --- | --- |
| [README.md](../../README.md) | 1 | 3. 一页代码图 / One-Page Code Graph | [SVG](svg/README-1.svg) | [PNG 3×](png/README-1.png) | [Source](source/README-1.mmd) |
| [01-SYSTEM-ARCHITECTURE.md](../../01-SYSTEM-ARCHITECTURE.md) | 1 | 2. 分层与所有权 / Layers and Ownership | [SVG](svg/01-SYSTEM-ARCHITECTURE-1.svg) | [PNG 3×](png/01-SYSTEM-ARCHITECTURE-1.png) | [Source](source/01-SYSTEM-ARCHITECTURE-1.mmd) |
| [01-SYSTEM-ARCHITECTURE.md](../../01-SYSTEM-ARCHITECTURE.md) | 2 | 3. 一次事件的端到端路径 / End-to-End Event Path | [SVG](svg/01-SYSTEM-ARCHITECTURE-2.svg) | [PNG 3×](png/01-SYSTEM-ARCHITECTURE-2.png) | [Source](source/01-SYSTEM-ARCHITECTURE-2.mmd) |
| [01-SYSTEM-ARCHITECTURE.md](../../01-SYSTEM-ARCHITECTURE.md) | 3 | 4. 源码、生成物与外部宿主 / Source, Generated, and External Boundaries | [SVG](svg/01-SYSTEM-ARCHITECTURE-3.svg) | [PNG 3×](png/01-SYSTEM-ARCHITECTURE-3.png) | [Source](source/01-SYSTEM-ARCHITECTURE-3.mmd) |
| [02-AUTHORING-MODEL.md](../../02-AUTHORING-MODEL.md) | 1 | 1. Model、Msg 与 update / Model, Msg, and update | [SVG](svg/02-AUTHORING-MODEL-1.svg) | [PNG 3×](png/02-AUTHORING-MODEL-1.png) | [Source](source/02-AUTHORING-MODEL-1.mmd) |
| [02-AUTHORING-MODEL.md](../../02-AUTHORING-MODEL.md) | 2 | 3. Val 是增量值，不是 Signal / Val Is an Incremental Value, Not a Signal | [SVG](svg/02-AUTHORING-MODEL-2.svg) | [PNG 3×](png/02-AUTHORING-MODEL-2.png) | [Source](source/02-AUTHORING-MODEL-2.mmd) |
| [02-AUTHORING-MODEL.md](../../02-AUTHORING-MODEL.md) | 3 | 4. Cmd 与 Sub 的生命周期 / Cmd and Sub Lifecycle | [SVG](svg/02-AUTHORING-MODEL-3.svg) | [PNG 3×](png/02-AUTHORING-MODEL-3.png) | [Source](source/02-AUTHORING-MODEL-3.mmd) |
| [03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md](../../03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md) | 1 | 1. 为什么需要页面级事务 / Why Page-Level Transactions Exist | [SVG](svg/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS-1.svg) | [PNG 3×](png/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS-1.png) | [Source](source/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS-1.mmd) |
| [03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md](../../03-INCREMENTAL-GRAPH-AND-TRANSACTIONS.md) | 2 | 4. Scope、可见性与释放 / Scope, Visibility, and Disposal | [SVG](svg/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS-2.svg) | [PNG 3×](png/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS-2.png) | [Source](source/03-INCREMENTAL-GRAPH-AND-TRANSACTIONS-2.mmd) |
| [04-RENDERER-AND-DIFF.md](../../04-RENDERER-AND-DIFF.md) | 1 | 1. Renderer 的责任 / Renderer Responsibilities | [SVG](svg/04-RENDERER-AND-DIFF-1.svg) | [PNG 3×](png/04-RENDERER-AND-DIFF-1.png) | [Source](source/04-RENDERER-AND-DIFF-1.mmd) |
| [04-RENDERER-AND-DIFF.md](../../04-RENDERER-AND-DIFF.md) | 2 | 4. Patch 操作与选择策略 / Patch Operations and Selection Policy | [SVG](svg/04-RENDERER-AND-DIFF-2.svg) | [PNG 3×](png/04-RENDERER-AND-DIFF-2.png) | [Source](source/04-RENDERER-AND-DIFF-2.mmd) |
| [04-RENDERER-AND-DIFF.md](../../04-RENDERER-AND-DIFF.md) | 3 | 5. Revision 与 snapshot / Revision and Snapshot | [SVG](svg/04-RENDERER-AND-DIFF-3.svg) | [PNG 3×](png/04-RENDERER-AND-DIFF-3.png) | [Source](source/04-RENDERER-AND-DIFF-3.mmd) |
| [05-RUNTIME-AND-HOST-SCHEDULER.md](../../05-RUNTIME-AND-HOST-SCHEDULER.md) | 1 | 1. 两个运行时层次 / Two Runtime Layers | [SVG](svg/05-RUNTIME-AND-HOST-SCHEDULER-1.svg) | [PNG 3×](png/05-RUNTIME-AND-HOST-SCHEDULER-1.png) | [Source](source/05-RUNTIME-AND-HOST-SCHEDULER-1.mmd) |
| [05-RUNTIME-AND-HOST-SCHEDULER.md](../../05-RUNTIME-AND-HOST-SCHEDULER.md) | 2 | 3. Host 队列与 scroll 合并 / Host Queue and Scroll Coalescing | [SVG](svg/05-RUNTIME-AND-HOST-SCHEDULER-2.svg) | [PNG 3×](png/05-RUNTIME-AND-HOST-SCHEDULER-2.png) | [Source](source/05-RUNTIME-AND-HOST-SCHEDULER-2.mmd) |
| [05-RUNTIME-AND-HOST-SCHEDULER.md](../../05-RUNTIME-AND-HOST-SCHEDULER.md) | 3 | 4. acknowledgement 是提交点 / Acknowledgement Is the Commit Point | [SVG](svg/05-RUNTIME-AND-HOST-SCHEDULER-3.svg) | [PNG 3×](png/05-RUNTIME-AND-HOST-SCHEDULER-3.png) | [Source](source/05-RUNTIME-AND-HOST-SCHEDULER-3.mmd) |
| [05-RUNTIME-AND-HOST-SCHEDULER.md](../../05-RUNTIME-AND-HOST-SCHEDULER.md) | 4 | 5. COW shadow 为什么必要 / Why the COW Shadow Is Necessary | [SVG](svg/05-RUNTIME-AND-HOST-SCHEDULER-4.svg) | [PNG 3×](png/05-RUNTIME-AND-HOST-SCHEDULER-4.png) | [Source](source/05-RUNTIME-AND-HOST-SCHEDULER-4.mmd) |
| [06-BUILD-VERIFY-AND-RELEASE.md](../../06-BUILD-VERIFY-AND-RELEASE.md) | 1 | 1. App Contract 是构建输入 / App Contract Is the Build Input | [SVG](svg/06-BUILD-VERIFY-AND-RELEASE-1.svg) | [PNG 3×](png/06-BUILD-VERIFY-AND-RELEASE-1.png) | [Source](source/06-BUILD-VERIFY-AND-RELEASE-1.mmd) |
| [06-BUILD-VERIFY-AND-RELEASE.md](../../06-BUILD-VERIFY-AND-RELEASE.md) | 2 | 4. 自动验证与人工证据 / Automated Verification and Manual Evidence | [SVG](svg/06-BUILD-VERIFY-AND-RELEASE-2.svg) | [PNG 3×](png/06-BUILD-VERIFY-AND-RELEASE-2.png) | [Source](source/06-BUILD-VERIFY-AND-RELEASE-2.mmd) |
| [07-SYMBOL-INDEX.md](../../07-SYMBOL-INDEX.md) | 1 | 4. 高扩散修改点 / High-Propagation Change Points | [SVG](svg/07-SYMBOL-INDEX-1.svg) | [PNG 3×](png/07-SYMBOL-INDEX-1.png) | [Source](source/07-SYMBOL-INDEX-1.mmd) |
| [08-RISKS-TESTING-AND-PERFORMANCE.md](../../08-RISKS-TESTING-AND-PERFORMANCE.md) | 1 | 1. 当前质量结论 / Current Quality Conclusion | [SVG](svg/08-RISKS-TESTING-AND-PERFORMANCE-1.svg) | [PNG 3×](png/08-RISKS-TESTING-AND-PERFORMANCE-1.png) | [Source](source/08-RISKS-TESTING-AND-PERFORMANCE-1.mmd) |
| [08-RISKS-TESTING-AND-PERFORMANCE.md](../../08-RISKS-TESTING-AND-PERFORMANCE.md) | 2 | 7. 风险地图 / Risk Map | [SVG](svg/08-RISKS-TESTING-AND-PERFORMANCE-2.svg) | [PNG 3×](png/08-RISKS-TESTING-AND-PERFORMANCE-2.png) | [Source](source/08-RISKS-TESTING-AND-PERFORMANCE-2.mmd) |
