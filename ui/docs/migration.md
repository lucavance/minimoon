# RUI → Minimoon UI migration

The native package is `lampclaw/minimoon_ui` (import as `@ui`), with `headless`, `theme` and `resources` subpackages. It depends on `lampclaw/minimoon`; applications do not need Rabbita, a DOM runtime, mutable signals, or handwritten bridge JavaScript.

## Scope and provenance

The baseline is Rabbita **0.15.6**, RUI **0.1.1**, commit `b1291945fd0201a0b5b39513b88585d6122db7bc`. The audit includes every declaration in upstream `rui/pkg.generated.mbti`: **428 public functions (including methods), 89 public types, 517 symbols**. The 64 component-family inventory is only a navigation aid, not proof of capability parity.

[The machine-readable API map](rui_api_map.json) records each symbol, original interface line, local implementation path, migration classification, and any unresolved capability. `adapted` means a native equivalent, `consolidated` means shared builders/types or explicit state replace several upstream parts, `native_substitution` means a deliberately different host mechanism, and `partial` means a known substantive gap. Classification never promises identical signatures, pixels, or browser behavior.

RUI is MIT-licensed; the pinned source and its third-party notices were reviewed before implementation. The repository’s [third-party notice](../THIRD_PARTY_NOTICES.md) records the retained Rabbita/RUI, shadcn/ui, and React DayPicker attribution. Vega-v1 is a locally owned native theme adaptation, not runtime-loaded upstream CSS.

## Application model

Create UI components inside a `Page` builder. Stateful components either own local state or accept `Val` and `Emit` through their `*_controlled` forms. Use `@ui.stack` to combine independently allocated component values; do not allocate local state inside a changing render callback.

Input and textarea deliberately use the simpler RUI-style controlled shape:
`input(value~, on_input~, ...) -> Node` and `textarea(...) -> Node` are pure
builders and can run inside `Val.view`. Use `input_stateful` or
`textarea_stateful` only when the widget should own its value. The former
`input_controlled`/`textarea_controlled` names are removed in this unpublished
candidate. `text_field(state, value, on_input, ...) -> Val[Node]` combines
application-owned text, reactive validation/options, semantic associations and
one local focus state. Create it once in the page/component builder, not in
`view`. `focused` controls native theme presentation; `InputOptions.focus` is
the separate programmatic focus request. No browser `:focus` selector is assumed.

This scoped authoring adjustment references RUI 0.1.2 source at
`eccae7507360aec8465469bafb7fb4da5b260a2a` (2026-09-08); the complete migration
inventory above remains pinned to 0.1.1. It does not claim full 0.1.2 parity.

Wrap pages that use floating content or toasts in `@ui.root(page, context => ...)`. The root owns the layer viewport, visibility lifetime, and toast queue. Declare the core `MeasureNodes` page capability when using measured surfaces, custom/multiple sliders, resize handles, or scroll-anchor measurement. Measurement requires rendered host nodes and participates in render-acknowledgement ordering; closing/disposal rejects obsolete replies.

| Upstream mechanism | Native replacement |
| --- | --- |
| Rabbita HTML and mutable scope stores | Minimoon `Node`, `Val`, `Cmd`, `Emit`, and page-owned local state |
| DOM portals / global popup ID registry | Transactional `layer` / `layer_root`; explicit controlled open values |
| CSS anchors / bounding-client-rect | Typed `measure_nodes` + headless placement with viewport bounds |
| Pointer/keyboard-driven range controls | Native slider or measured touch multi-thumb implementation |
| Browser dialog, hover, contextmenu events | Native layers and touch/tap/long-press interaction policies |
| DOM input/paste/IME handling | Native input, textarea, picker, radio/checkbox group, switch |
| CSS scrollbars / ResizeObserver | Native scroll-view and typed scroll/measurement events |
| Anchor `href`, target/download, raw DOM attrs | Typed `Route` / application `Cmd`, native semantics, class/style |
| OKLCH, color-mix, browser-global styles | Hex theme tokens, scoped `mmui-*` WXSS and explicit light/dark assets |

Browser-only focus selectors, arbitrary document mutation, keyboard shortcuts, mouse hover, and downloadable anchors are not silently simulated. A native edit-locked input uses the native disabled editing behavior for `read_only`; it is not a selectable browser readonly input. Platform-owned native-picker choices intentionally do not reproduce browser optgroup appearance. A displayed keyboard hint (`kbd` or command shortcut) is presentation, not a registered system keyboard handler.

Native Carousel uses the platform swiper’s fixed slide extent; arbitrary DOM flex-basis and measured multi-visible snapping are not part of this adaptation. MessageScroller uses keyed height-delta anchoring instead of per-element browser `overflow-anchor`; increment `content_revision` for streamed edits or asynchronous resizing without key changes. Its jump buttons can be hidden or rendered through `render_button(direction, command, disabled)`. Chart provides the same category of legend/tooltip/palette primitives as upstream, not a plotting engine.

## Component capability mapping

The JSON map is the exhaustive symbol-level reference. The important consolidations are:

| Families | Native capabilities / consolidation |
| --- | --- |
| Foundation, typography, card, item, marker, message, bubble | Native semantic content slots, typed tones/sizes/orientation/alignment, rich content and command-based actions |
| Avatar | Source-keyed loading/error state, fallback, image load/error notifications, group/badge slots |
| Field, Form, Input, Textarea | Label/error/description associations, native form events, focus/blur, input options and application validation |
| Checkbox, RadioGroup, Switch, NativeSelect | Controlled/local native controls; mixed checkbox state; disabled/read-only/invalid state; keyed options |
| Toggle, ToggleGroup | Controlled pressed/selection state, canonical single/multiple values, custom content, typed size/variant/spacing |
| InputGroup, InputOTP | Typed addons/actions; one native IME/paste input with custom OTP slots and completion transition |
| Progress, Slider | Bound normalization; native progress; range snapping, multi-thumb distance, vertical/RTL touch and cancellation |
| Accordion, Collapsible, Tabs | Shared `Panel`; key validation, enabled fallback, icon/custom trigger, forced mount and controlled state |
| Select, Combobox, Command | Keyed options, measured floating surfaces; select custom value/item/content; combobox state/chips; command filter/query provider |
| Dialog, AlertDialog, Sheet, Drawer, Popover, Tooltip, HoverCard | Shared native surfaces/layers; touch policy, placement and explicit open/close state replace browser scopes |
| ContextMenu, DropdownMenu, Menubar | Shared action/check/radio/submenu item tree instead of duplicate browser scope types |
| NavigationMenu, Sidebar | Provider state and rich slots; selected submenu viewport; separate mobile-open/collapse state and native navigation |
| Calendar, DatePicker | Validated `CalendarDate`, `DateSelection` single/multiple/range and preset selection; fields replace date getters |
| Table, DataTable, Pagination | Native table slots/spans, explicit row/column state, numeric sorting/search/visibility/selection/pagination |
| Carousel, ScrollArea, Resizable, MessageScroller | Native swiper/scroll-view, controlled sizes, typed touch gestures and keyed message anchoring |
| Chart | Styled legend/tooltip/data presentation primitives; not a plotting engine, matching upstream scope |
| Toast, Sonner | One page-owned queue, explicit show/dismiss/dismiss-all, actions/duration/variants/positions |
| Theme, Direction, resources | Local Vega-v1 light/dark + LTR/RTL, validated feature IDs/dependency closure and generated WXSS/assets |

## Forms and custom widgets

Set `name` on actual native form controls. Native submission yields a `Map[String, Json]`. For custom widgets (for example a multi-thumb slider, Select, or ToggleGroup), render `form(values=...)` with the current controlled values; those explicit values override same-named native values. This is an intentional data-flow boundary, not hidden HTML input emulation.

Handle `on_reset` to reset controlled/local application state. Native reset cannot mutate a `Val` owned by the application. Validation remains in Elm-style model/update logic and is rendered through `FieldState`/semantics; there is no implicit browser constraint-validation or third-party schema engine.

## Theme and resources

Use `@theme.theme(mode=Dark, direction=Rtl)` or the light/LTR defaults, with typed token overrides. Theme state is passed to `@ui.root` or the smaller theme/direction wrapper; no process-global theme mutation occurs.

The native resource provider accepts an array of feature IDs. An empty array selects all; unknown IDs fail; duplicates are removed and transitive dependencies are included in canonical order. The bundle contains scoped WXSS and explicit light/dark SVG variants under `assets/mmui/`. The app build fingerprints these resources with its generated artifacts. CSS and asset selection do not import a browser Tailwind runtime.

Selection is group-based, not per-component CSS tree shaking. Base, foundation, compound and attachment rules plus six theme icons are shared; form rules are added when required. The feature inventory describes the canonical request/dependency closure, not an exact selector-to-component export boundary.

## Verification and remaining work

The API map’s `capability_gaps` retains the implementation audit trail: the five identified extension groups have been resolved through implementation inspection and relevant tests, not merely by adding exported names. Only real-host evidence remains pending. The final symbol inventory contains no missing/extra entries, and every local replacement was checked against the generated public interfaces; no private implementation symbol is advertised as an application API.

Automated coverage includes native and JavaScript component tests for mixed/readonly controls, Unicode OTP/paste/completion, disabled choice guards, reactive select behavior, avatar stale-source events, disclosure forced mounting/key recovery, and gesture measurement/release/cancel/lifecycle boundaries. Same-frame event batches are covered explicitly: semantic toggle/selection requests reduce against current state, obsolete choices are rejected, and OTP completion observes earlier inputs in the batch. Theme/resource tests verify deterministic feature resolution and native-safe assets. The showcase contains all 64 families and generated-host validation checks class/resource/host parity.

**Real WeChat Developer Tools / Skyline validation remains pending.** No test snapshot, generated report, or API status is real-host evidence. Follow the repository’s Developer Tools procedure with the exact generated artifact fingerprint before claiming a host pass or release readiness.
