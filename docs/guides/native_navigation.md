# Native tabs and page layout

Core `0.2.0` uses Contract 11 and runtime ABI 13 for native bottom navigation
and synchronous page layout. Renderer protocol remains 8. Regenerate the entire
application after migrating; these are unpublished candidate interfaces.

## Native bottom tabs

Declare 2–5 tabs in `miniapp.minimoon.json`. Each `package` references a page
already listed in `pages`; the generator resolves its route, so source config
does not duplicate `pagePath`.

```json
{
  "schemaVersion": 11,
  "name": "my_app",
  "pages": [
    { "package": "src/pages/home", "navigationBarTextStyle": "white" },
    { "package": "src/pages/activity", "navigationBarTextStyle": "white" },
    { "package": "src/pages/details" }
  ],
  "tabBar": {
    "color": "#67758B",
    "selectedColor": "#356AE6",
    "backgroundColor": "#FFFFFF",
    "borderStyle": "white",
    "list": [
      { "package": "src/pages/home", "text": "首页" },
      { "package": "src/pages/activity", "text": "动态" }
    ]
  }
}
```

Optional `iconPath` and `selectedIconPath` must be supplied together and name
validated PNG assets provided through build resources. The native configuration
is identical in the manifest and `dist/app.json`. Without `tabBar`, no tab
configuration is emitted; the starter and independent UI fixture stay opt-in.

Declare `SwitchTab` in a page's capabilities and return
`@minimoon.switch_tab(@minimoon.route("pages/activity/activity"))` from its
update or bind it directly to a button. Tab routes cannot carry query input.
`navigate_to` and `redirect_to` target ordinary pages, not tabs. A native tab
switch hides the previous tab and retains its page-local state; it is not a
page-unload test. Secondary routes still provide a real navigation stack.

`navigate_back_or(fallback=...)` first goes back when the stack permits. At a
direct entry it switches to a tab fallback or redirects to an ordinary route.
Declare the capabilities that the application may actually execute. There is
no mutable global navigation store and no implicit conversion of other commands.

## Layout before the first business tree

Inside an ordinary page builder, `context.layout()` returns `Val[PageLayout]`.
It is read-only, owned by the page graph, and independent of route input.
Window dimensions, status bar, safe-area and menu-button rectangle use logical
pixels. Rectangles are screen-relative; subtract the window's screen-top offset
before using vertical coordinates in window content.

The generated host reads window and capsule information synchronously before
runtime creation. The empty boot tree remains intentional; the first Load tree
already uses measured layout. `onResize` enters the ordered host queue. Hidden
pages retain the newest layout and apply it together with shared-state refresh
on Show. Identical values do not create a new render revision, and disposal
rejects late work. Tests can inject layout at mount and update it explicitly.

Missing measurements are represented as unavailable, not fabricated device
facts. The example reserves a conservative 44 px top band, 44 px navigation row
and 96 px right-hand capsule area when needed. A failed subsequent reading keeps
the last valid value. Dynamic dimensions belong in `style`, not constructed
Tailwind class names. Intersect the safe area with the actual window; native
TabBar may already have reduced its height, so do not add bottom padding twice.

Custom headers may configure `navigationBarTextStyle` as `black` or `white`.
Pair white foreground with a dark `page` background in build-resource WXSS,
including the empty boot phase. The field does not add a native title bar.
No dynamic navigation-color command is provided.

## Build-only PNG resources

`ResourceAsset.content` is typed as `Text(String)` or `Binary(Bytes)`.
Text resources retain SVG/text support; binary resources currently support PNG.
The native resource probe serializes binary bytes as Base64 and the generator
validates and writes the decoded bytes. Paths, conflicts, format, dimensions
and size are checked before replacing output. Resources join manifests and
artifact fingerprints but are not implicitly linked into application JavaScript.

Draft Workbench supplies its own four icon pairs and visual shell without importing
Minimoon UI. Its nine routes consist of Workbench, Drafts, Online and More tabs,
a Draft Editor and four capability laboratories. See the [fixture matrix](../reference/miniapp_fixture_matrix.md)
and [real-host checklist](../operations/miniapp_devtools_validation.md).
