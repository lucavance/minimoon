# Native Nova recipes

The [64-family ledger](nova_recipe_map.json) records the RUI 0.3.6 source path,
source hash and style declaration locations reviewed at commit
`7d5940fed9b1ba795c84582394024233997ec267`. Each row links the native component
implementation, the applied recipe selector and the adaptation decision.
The [MIT notice](../THIRD_PARTY_NOTICES.md) covers this reference.

Nova converts the neutral/destructive palette to hexadecimal colors, uses
compact control sizes and adjusts component spacing, type and radii. Compound
families reuse their native primitives: date picker uses calendar, trigger and
popover; data table uses table, filters, selection and pagination; Sonner uses
the toast surface. Direction, ratio and scroll containers retain native layout
and inherit the preset tokens. The existing `Tokens` record and application
overrides remain supported. Explicit `VegaV1` keeps the previous recipes.

Native overlays carry surface-kind classes so both controlled and parts-based
composition select the same recipes. Browser hover, DOM selectors, CSS color
functions and keyboard mechanics are outside this adaptation. Native checkbox,
radio, switch and picker rendering remains platform owned. Drawer handles
retain a 44px interaction area even when surrounding controls are compact.

The offline API gate checks complete family coverage, duplicates and local
source/selector/test references. Runtime tests mount all six showcase pages
under both presets and verify that switching preserves state. These checks do
not establish visual or real-host equivalence. Inspect both palettes, presets,
directions, control states and overlays in WeChat Developer Tools using the
current showcase fingerprint; tracked host status remains `pending`.
