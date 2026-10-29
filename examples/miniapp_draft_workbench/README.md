# Minimoon Draft Workbench

[中文](README.zh-CN.md)

Minimoon Draft Workbench uses the public core `lampclaw/minimoon 0.3.2` API:
**four native Tabs, one editor and four capability laboratories, nine routes in total**.
It also provides core conformance coverage; it is not an account system or cloud notes service.

The former `miniapp_conformance_app` project is now `miniapp_draft_workbench`,
with module `lampclaw/miniapp_draft_workbench`; old directories and routes have no aliases.
The independent [UI Showcase](../../ui/examples/showcase/README.md) and Starter are separate.

## Import and try

<!-- minimoon:preview:start -->
Download or clone this repository and import **`examples/miniapp_draft_workbench/dist/`**
directly into WeChat Developer Tools. Import the output directory, not the source.
The committed output needs no MoonBit, Node or build step to open.
<!-- minimoon:preview:end -->

Use Skyline, base library **3.17.0** or newer, and `setting.es6=true`,
`setting.enhance=true`, `setting.minified=true`. Configure your AppID only in the
ignored private file using the [host settings](../../docs/guides/miniapp_quickstart.md#open-in-wechat-developer-tools).
Alternatively, download the matching commit's CI `minimoon-devtools-<commit>`
bundle, verify its checksums, and import its unchanged `dist/`.

The interface uses a fixed deep-blue navigation bar, safe-area calculations and a
shallow curved hero. It uses core components and MoonBit-owned resources without
the UI module, remote visual assets or handwritten JavaScript.

## Pages

| Page | Source package, relative to src | Responsibility |
| --- | --- | --- |
| 工作台 / Workbench | pages/workbench | Counts, summary, create and resume editing |
| 草稿 / Drafts | pages/drafts | Saved drafts, reopen and confirmed deletion |
| 联机 / Online | pages/online | App request state, typed echo and retry |
| 更多 / More | pages/more | Data management, demo guide and laboratories |
| 草稿编辑 / Draft editor | pages/draft_editor | Create, edit by ID, resume, manual save and page-owned echo |
| 交互与组件 / Interaction | pages/interaction | Native controls, local components, Disclosure/Accordion/Tabs, layers and menus |
| 平台与 HTTP / Platform | pages/platform | Login, isolated storage, location, media, prompts and ten public HTTP scenarios |
| 请求生命周期 / Request lifecycle | pages/request_lifecycle | Shared counts, delayed requests, hide and unload comparisons |
| 状态与渲染 / Runtime Lab | pages/runtime_lab | Keyed identity, focus, structure synchronization, async work, disposal and isolation |

Every page receives App `Deps`; pages do not import other pages' production
implementations. `app` owns typed business state, `components/workbench` composes
public views, and `shared/shell` owns layout. Routes use `pages/<name>/<name>`.
The editor requires a nonempty `from`; `mode` is new/edit/resume, and edit also
requires a positive integer id.

## Three complete flows

1. **Local drafts**: create → validate → save → list → edit/delete → restart and restore.
   Trimmed titles are required, up to 80 Unicode characters; bodies allow 2000,
   with at most 50 drafts. Storage uses the isolated `minimoon-draft-workbench-v1`
   key and sorts the most recently saved first. Only a successful write updates
   saved state. Saving blocks duplicate saves, deletion and clearing, while new
   input remains editable and unsaved. Unknown read errors or corrupt/unknown
   versions are retryable and never overwritten automatically; initialization
   requires confirmation before replacing existing data.
2. **Online echo**: edit → send in background → loading → typed echo → retry on failure.
   The default is public `https://echo.apifox.com/post`, with a ten-second timeout.
   Send only non-sensitive demo content. **Echo is not cloud storage** and changes
   neither editor nor local data. Requests carry a content version; an old response
   cannot replace new content after edits, switches, deletion or clearing.
3. **Cross-page state and lifetime**: App holds one editing buffer for this run;
   all four Tabs share its state. Creating or switching drafts confirms discarding
   unsaved changes. The editor's background send belongs to App, so the Online
   page receives its result after navigation. The page-owned send under 技术说明
   is canceled on editor unload. **Hide is not unload**: switching Tabs cannot
   validate unloading, and App lifetime does not continue after process exit.

Unsaved input lasts only for this App run; restart restores saved drafts only.
Clearing affects the workbench key, not Platform laboratory storage. There are no
accounts, cloud storage, autosave, collaboration or persistent request histories.

`echo_base_url()` in `src/app/workbench_echo.mbt` provides the shared default for
draft requests, lifecycle requests, the initial Platform address and business-page
hints. Platform's editable address affects only its own requests, not background
draft sends or UI Showcase. There is no automatic endpoint switching or hidden
retry; public-service failures are displayed without pretending a save succeeded.

## Three-minute demonstration

- Start offline. Create “周末计划” with body “去公园走走”, save it and reopen it
  from Drafts. Edit and save, then restart to confirm persistence. Create another
  draft, delete it and restart to confirm deletion.
- Go online, open the retained draft, send in background and immediately switch
  to Online to observe the result. A fast request may already be complete; use
  the laboratory's public delayed endpoint for slow-request ownership comparisons.
- Send again and immediately change the title; echo must not overwrite input.
  Expand 技术说明, send the page-owned request and return; inspect Network for
  cancellation and absence of late updates. Send offline to check failure feedback,
  then reconnect and retry.

Report public-service failures honestly; local flows can still be demonstrated
independently. See the [host checklist](../../docs/operations/miniapp_devtools_validation.md).

## Modify and rebuild

Prepare the [development environment](../../docs/guides/miniapp_quickstart.md#prerequisites),
edit `src/`, then run from the repository root:

<!-- minimoon:rebuild:start -->
```bash
vp run minimoon verify examples/miniapp_draft_workbench --candidate
```
<!-- minimoon:rebuild:end -->

This builds release-mode output before automated candidate verification. Reimport
or recompile the same directory afterwards. Source development uses
`moon 0.1.20261023` / `moonc v0.10.17+d971670cd`, global `vp 1.4.0`,
Node `>=26.12.1`, managed Bun `1.4.4` and `moonbitlang/async 0.22.5`.
Use a matching CLI rather than mixing old generated files; registry availability
is recorded in [project status](../../docs/project_status.md).

## Maintainer validation and boundaries

Runtime Lab's 列表查询（本地模拟） demonstrates the optional query package using
23 simulated drafts, confirmed search, refresh, appending and retry. Search for
“慢速” to check old-response isolation; 下一次响应失败 exercises refresh and
append failures, and closing/reopening checks local component disposal. This demo
ships with the core query package; registry availability belongs in project status.

Automation covers storage corruption/failure/duplicate operations, cross-page
buffers, out-of-order/duplicate callbacks, decoding failures, App/Page ownership,
and the existing control/render laboratories. Input regressions check successive
title/body edits, Chinese text, deletion and actual host writes. In the simulator
and on devices, check continuous English input, Chinese composition, paste,
deletion, middle insertion and switching fields: the cursor must remain stable,
and title text/placeholders must not be vertically clipped.

`vp run check:http-live` covers ten Platform HTTP scenarios, the App draft echo
after editor unload, and UI Showcase's form echo: 12 public-API cases using a
transport shim, rather than real WeChat host evidence.

`generated/verify_report.json` and `release_summary.json` are public candidate
records; `devtools.evidence.json` is private and Git-ignored. Evidence applies only
to its exact artifact fingerprint. Changed generated bytes require revalidation
of affected fixtures; core and UI evidence remain independent. Source core is
`0.3.2`; candidate output, host acceptance and registry availability are checked
separately. This does not establish production request-domain or complete
HTTPS/TLS validation, and verification commands do not publish packages.
