# Rabbita and RUI reference audit

Reviewed on 2026-09-07 against Minimoon `030b93a` (0.1.1). This is a reference
and migration-gap assessment; the accompanying dependency refresh adds no
component API. RUI-inspired component development belongs to the
[next iteration](../roadmap.md#next-iteration-rui-inspired-miniapp-components).

## Compared sources and provenance

| Source | Pinned reference | Relationship to Minimoon |
| --- | --- | --- |
| Rabbita 0.13.1 | [`6392a57a1401257adaa1eb74fc44397a21daaa04`](https://github.com/moonbit-community/rabbita/tree/6392a57a1401257adaa1eb74fc44397a21daaa04) | Original adapted Duplix and slotmap source |
| Rabbita private erased-value wrapper | [`b6cbf52902574f56895c218a43ee072dbf758f39`](https://github.com/moonbit-community/rabbita/tree/b6cbf52902574f56895c218a43ee072dbf758f39) | Original review point for `internal_any` |
| Rabbita 0.15.6 | [`b1291945fd0201a0b5b39513b88585d6122db7bc`](https://github.com/moonbit-community/rabbita/tree/b1291945fd0201a0b5b39513b88585d6122db7bc), tag `rabbita-v0.15.6` | Latest release comparison point for this audit |
| RUI 0.1.1 (`Yoorkin/rui`) | [Module within the same Rabbita tree](https://github.com/moonbit-community/rabbita/blob/b1291945fd0201a0b5b39513b88585d6122db7bc/rui/moon.mod) | Component design and capability comparison only |

Rabbita and RUI are not declared dependencies in Minimoon's `moon.mod`.
Updating the comparison point does not update the source attribution pins in
[THIRD_PARTY_NOTICES.md](../../THIRD_PARTY_NOTICES.md). The existing adapted
Rabbita source is Apache-2.0; Minimoon owns its subsequent changes.

RUI is separately MIT-licensed and experimental. Its
[notices](https://github.com/moonbit-community/rabbita/blob/b1291945fd0201a0b5b39513b88585d6122db7bc/rui/THIRD_PARTY_NOTICES.md)
attribute visual recipes and public conventions to shadcn/ui Vega and calendar
focus behavior to React DayPicker. This change imports none of those sources
or recipes. Any later adaptation must record the exact files and revision and
carry the applicable upstream notices. Component-name overlap alone is not
evidence that source was copied.

The comparison uses upstream source and generated interfaces, Minimoon's root
and optional-package interfaces, behavior tests, and its real-host checklist.
It does not claim browser/MiniApp visual parity or a fresh real-host pass.

## Rabbita: adopted, extended, and outstanding

| Capability or upstream change | Current Minimoon assessment | Decision |
| --- | --- | --- |
| Incremental Duplix graph and generational slotmap | Adapted source lives in `internal_duplix` and `internal_slotmap` | Preserve provenance; review future fixes against local transaction semantics |
| Private erased values | `internal_any` supports graph-owned, generation-checked message storage | Already adapted; keep the erasure boundary private |
| `(Val, Emit)` and model-first state updates | Root state/page constructors use this authoring shape | Conceptual influence already reflected in the public API |
| Scope identity and cleanup | Upstream added the `ScopeId` wrapper/scoped cleanup after the original baseline; Minimoon has page-owned `RootScope`, rollback, visibility, and disposal | No missing drop-in migration; retain the local ownership model |
| Retained subscription tagger refresh | Accepted renders refresh messages while retaining one host timer per key/interval | Already covered by the retained-host-subscription regression test |
| Keyed child position and focus preservation | Normalized keyed move/LIS behavior is tested; the DevTools checklist covers focused reorder | Already addressed for MiniApp; DOM implementation is not portable |
| Generic command extensions and `EffectKind` scheduling | Minimoon exposes opaque `Cmd` and typed MiniApp capabilities with a fixed ordered scheduler | Intentionally absent; require a concrete host capability before expanding the boundary |
| Generic HTML/SVG/DOM/JavaScript facade and extracted web VDOM | Minimoon owns its normalized MiniApp tree, protocol, renderer, and CommonJS host | Outside the product target |
| Browser history, global browser subscriptions, browser HTTP/WebSocket/clipboard/dialog adapters | Page lifecycle, navigation, subscriptions, and declared `wx.*` commands are the local equivalents where supported | Do not import browser adapters; evaluate additional MiniApp capabilities individually |
| Native web rendering, SSR, hydration, full-stack server, Warren and Vite integration | No matching MiniApp deployment requirement | Outside the product target |

The local graph is a maintained adaptation, not a vendored subtree that can
be replaced with the latest Rabbita directory. In particular, global upstream
scope storage cannot substitute for page ownership and transactional rollback.
The relevant subscription regression is in
`src/renderer_miniapp/page_program_test.mbt`; focused keyed moves are covered by
the [real-host checklist](../operations/miniapp_devtools_validation.md).

## RUI: complete showcase mapping

The pinned [showcase registry](https://github.com/moonbit-community/rabbita/blob/b1291945fd0201a0b5b39513b88585d6122db7bc/website/homepage/components/showcase_registry.mbt)
contains 64 entries. Six have a direct conceptual equivalent in Minimoon's
optional components. The other 58 lack exact optional-component parity; this
does not mean that all 58 are absent user capabilities or useful migration
targets.

The current classification is 6 Covered, 12 Native/partial, 19 Gap, 20 Recipe,
and 7 Browser entries. Only the behavior gaps and demonstrated reuse needs
feed component planning; the 58 non-equivalent entries are not a migration
quota.

Statuses below describe current capability, not source provenance:

- **Covered**: an existing optional component serves the same core purpose;
  browser behavior and API parity are not implied.
- **Native/partial**: root MiniApp controls or commands cover a useful subset.
- **Gap**: reusable behavior is absent and can enter the next-iteration backlog.
- **Recipe**: primarily application composition or styling with current nodes.
- **Browser**: the upstream interaction needs a separate MiniApp design before
  it could be useful.

| RUI showcase entry | Status | Minimoon counterpart or remaining work |
| --- | --- | --- |
| Accordion | Covered | Single/multiple Accordion, controlled/self-owned and reactive slots |
| Alert | Recipe | Text, semantic labels, and status styling; no dedicated wrapper |
| Alert Dialog | Gap | Specialize Dialog with explicit confirm/cancel and dismissal policy |
| Aspect Ratio | Recipe | Bounded Skyline layout/style recipe |
| Attachment | Gap | Media preview/removal composition; `choose_media` supplies selection only |
| Avatar | Recipe | Image/text composition; fallback behavior needs its own design |
| Badge | Recipe | Styled text/status composition |
| Breadcrumb | Recipe | Route-aware `navigator` and text composition |
| Bubble | Recipe | Message-bubble layout and styling |
| Button | Native/partial | Root `button`; no RUI variant/style API |
| Button Group | Recipe | Group existing buttons with shared layout |
| Calendar | Gap | Calendar selection, disabled-date rules, and optional ranges |
| Card | Recipe | Container, heading, content, and action layout |
| Carousel | Native/partial | `swiper` and `swiper_item`; no RUI compound API |
| Chart | Gap | Chart semantics/rendering require a separate renderer/capability review |
| Checkbox | Native/partial | `checkbox` and `checkbox_group` |
| Collapsible | Covered | Disclosure with controlled/self-owned state and reactive content |
| Combobox | Gap | Search/filter/selection over typed input and a MiniApp selection surface |
| Command | Gap | Searchable action list; unrelated to Minimoon's effect type `Cmd` |
| Context Menu | Browser | Right-click interaction requires a long-press/tap product design |
| Data Table | Gap | Sorting, filtering, selection, and bounded mobile data layout |
| Date Picker | Native/partial | `picker_date`; inline calendar and range selection remain absent |
| Dialog | Covered | Dialog semantics and controlled/self-owned overlays |
| Direction | Recipe | Application direction/layout policy; no direction provider |
| Drawer | Gap | Four-sided Sheet exists; drawer drag/snap behavior is absent |
| Dropdown Menu | Covered | Dropdown actions, checkbox/radio items, and tap-opened submenus |
| Empty | Recipe | Empty-state content and actions |
| Field | Gap | Shared label/help/error/validation composition around native controls |
| Hover Card | Browser | Hover-driven preview and browser positioning |
| Input | Native/partial | Typed controlled `input` with focus/blur/confirm |
| Input Group | Recipe | Input, leading/trailing text, and action layout |
| Input OTP | Gap | Segmented entry, paste/confirm policy, and mobile focus coordination |
| Item | Recipe | List-row content and actions |
| Kbd | Browser | Desktop shortcut hints have no current MiniApp requirement |
| Label | Recipe | Text and existing semantic label/description relationships |
| Marker | Recipe | Status indicator and positioning styles |
| Menubar | Browser | Desktop keyboard navigation and focus restoration |
| Message | Recipe | Message content/avatar/action layout; useful alongside a future scroller |
| Message Scroller | Gap | `scroll_view` exists; pinned-end, new-message, and history behavior do not |
| Native Select | Native/partial | `picker_selector` provides native selection |
| Navigation Menu | Gap | `navigator` supplies navigation; reusable menu state/layout is absent |
| Pagination | Gap | Page-selection model and mobile controls |
| Popover | Browser | Browser portal/collision/focus behavior needs a MiniApp overlay design |
| Progress | Gap | Reusable bounded progress/indeterminate state and semantics |
| Radio Group | Native/partial | `radio` and `radio_group` |
| Resizable | Browser | Pointer-driven pane resizing and DOM measurements |
| Scroll Area | Native/partial | `scroll_view` and typed boundary/scroll events |
| Select | Native/partial | `picker_selector` covers basic selection; custom filtering/menu behavior absent |
| Separator | Recipe | Layout divider styling |
| Sheet | Covered | Four-sided controlled/self-owned Sheet with reactive slots |
| Sidebar | Gap | Responsive navigation/collapse ownership; drawer/resizing require MiniApp design |
| Skeleton | Recipe | Loading placeholders within the existing style pipeline |
| Slider | Gap | No root slider node/event API; requires a compatibility review first |
| Sonner | Gap | Notification queue, dismissal, and action policy above host feedback |
| Spinner | Recipe | Bounded loading indicator styling |
| Switch | Native/partial | Root controlled `switch` |
| Table | Recipe | Static mobile row/cell layout; no generic HTML table renderer |
| Tabs | Covered | Nullable controlled/self-owned Tabs and reactive panels |
| Textarea | Native/partial | Typed controlled `textarea` with focus/blur/confirm |
| Toast | Native/partial | `show_toast`; custom content/actions/queue remain absent |
| Toggle | Gap | Reusable pressed-state button behavior |
| Toggle Group | Gap | Single/multiple pressed-state selection and grouping |
| Tooltip | Browser | Hover/focus timing and anchoring need a touch-first design |
| Typography | Recipe | Text/heading nodes and application styles |

RUI 0.1.0, present at the original Rabbita reference, and RUI 0.1.1 have the
same production component file set. Their generated interfaces show one added
public function, `sidebar_provider_with_input`. Minimoon already has reactive
`_with_input` forms for all content-bearing optional components; this is a
matching composition pattern, not an unimplemented Sidebar API. Upstream also
changed browser interaction tests and fixed focus/measurement behavior; a stable
component list does not mean unchanged implementation.

RUI uses browser HTML/ARIA, inline styles, and JavaScript interaction helpers.
Minimoon's components use typed MiniApp nodes, page-owned state, optional class
wrappers, and versioned generated WXSS. The existing implementation and
[component guide](../guides/testing_and_components.md) therefore establish
behavioral correspondence, not source/API/visual equivalence.

## Next-iteration priorities and entry criteria

1. **First design batch: Field and Alert Dialog.** Define required/help/error
   presentation, typed control integration, confirm/cancel ownership, and
   dismissal behavior. Reuse existing controls and Dialog where possible.
2. **Then Progress/Slider and searchable selection.** Establish the missing
   native events/semantics before choosing APIs; build Combobox/Searchable
   Select once those requirements fit the supported host boundary.
3. **Then message and feedback behavior.** Evaluate Message Scroller with
   message recipes, followed by custom Toast/Sonner only where native
   `show_toast` is insufficient. Specify scroll retention and scope-owned
   timers/queue cleanup from application cases.
4. **Later, demand-driven candidates.** Calendar/ranges, Attachment, Input OTP,
   Pagination, Data Table, Navigation Menu/Sidebar, Drawer, and Toggle/Toggle
   Group need concrete application use. Promote recipes such as Avatar/Card
   only when recurring behavior justifies a reusable package API. Chart needs
   its own renderer decision.

This orders evaluation and implementation; it is not a promise to ship every
entry in one iteration. Before each component enters implementation, record
its dogfood scenario, native substitute, exact remaining behavior, source and
license decision, and the intended root/protocol compatibility impact.
The 0.1.x root interface is locked: new root controls, semantic variants, or
protocol fields require a separately planned versioned compatibility change.
Optional-package additions must preserve existing APIs and theme contracts.

Each implemented component must pass native/JS normalized-tree behavior tests,
controlled/self-owned and reactive-slot checks where applicable, keyed/hide/
dispose ownership checks, generator/API/size gates, and the affected Conformance
interactions. Changed generated bytes require fresh fingerprint-bound real-host
validation. The [roadmap](../roadmap.md) owns scheduling; this pinned audit owns
the capability comparison and must not describe future components as shipped.
