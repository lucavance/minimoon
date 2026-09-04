# Testing and interactive components

## Normalized-tree testing

Tests may import `lampclaw/minimoon/testing` and mount a public `Page`. The
runtime reads the same normalized snapshot used by the MiniApp renderer; it
does not maintain a parallel test-only VDOM.

```moonbit
let runtime = @testing.mount(program())
let save = @testing.all([
  @testing.by_role("button"),
  @testing.by_text("Save"),
])
let _ = runtime.tap(save)
assert_true(runtime.query(@testing.by_text("Saved")) is Some(_))
```

Selectors cover kind, ID, section, exact/contained text, semantic label, prop,
event, role, and conjunction. `get` and interactive drivers require exactly one
match; `query` and `query_all` remain the explicit optional/multiple forms.
`within` creates a semantic subtree scope. Its selector chain is resolved from
the latest normalized snapshot before every query or interaction, so a scope
does not retain stale nodes across a render. Scoped queries search descendants;
nested scopes and `get` must resolve uniquely.

Drivers cover tap, string input, native change, confirm, focus, input/textarea
blur, scroll, upper/lower boundary events, lifecycle, subscription ticks, and
disposal. `change` writes `detail.current` for a swiper and `detail.value` for
the other value controls. No raw-event escape hatch is exposed. `snapshot()`
remains available for exact structured assertions and lower-level renderer
tests.

## Headless and styled components

`lampclaw/minimoon/components` owns behavior and semantics without classes.
Disclosure, single/multiple Accordion, nullable Tabs, Dialog, four-sided Sheet,
and Dropdown have controlled forms accepting a `Val` plus `Emit` and self-owned
forms backed by page-local state. Menu entries cover action, label,
separator, checkbox, radio, and tap-opened submenu behavior. Keys are non-empty
and globally unique within each component. Accordion and Tabs accept optional
accessible labels for their composite roots; Dropdown derives its menu label
from the stable trigger ID.

Content-bearing components also provide additive `_with_input` variants for
Disclosure, single/multiple Accordion, Tabs, Dialog, and Sheet. Their spec or
item stores a pure slot renderer, while a separate `Val[Input]` drives the
visible panel or content:

```moonbit
let (count, increment) = @minimoon.create_pure_state(
  0,
  update=(current, _ : Unit) => current + 1,
)
let panel = @components.accordion_single_with_input(
  id="counter",
  input=count,
  items=[
    @components.accordion_item_with_input(
      key="value",
      label="Counter",
      panel=value => @minimoon.button(
        on_tap=increment(()),
        value.to_string(),
      ),
    ),
  ],
)
```

Create child state once outside the slot renderer. Passing its `Val` as input
keeps child ownership alive while a panel is hidden; the renderer must only
construct `Node` values. Existing static APIs remain unchanged, and Dropdown
has no input variant because it has no arbitrary `Node` slot.

`lampclaw/minimoon/components/styles` supplies wrappers with `mm-*` classes.
To include their CSS, opt in at the application boundary:

```json
{ "componentTheme": "minimal-v2" }
```

`minimal-v1` remains byte-for-byte stable. `minimal-v2` is scoped below 4 KiB
and adds overlay/menu classes; both are described by ID, version, hash, and
bytes in `generated/manifest.json`. Omitting the field preserves headless
behavior and adds no theme CSS.

Components emit dialog/menu roles, checked/modal state, orientation, popup
ownership, and labelled/described relationships into renderer protocol v7.
Interaction is intentionally platform-faithful: tap opens submenus; there is no
synthetic DOM keydown, focus trap, portal, or collision engine. Behavior tests
should prefer semantic/text selectors; real-host validation must also check
native focus/blur/confirm, controlled values after structural updates, overlay
dismissal, visible selection, Skyline layout, and a clean console.
