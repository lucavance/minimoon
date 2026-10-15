# Native Markdown

Import `lampclaw/minimoon_ui/markdown` explicitly in `moon.pkg`; the UI root
package and build-resource provider do not import the parser. Add `markdown`
to the resource features, or use the full bundle. Core remains parser-free.

```mbt check
///|
test "render a document" {
  let _node = @markdown.markdown(
    "# Hello\n\nEnglish 与中文 **strong** and *emphasis*.",
    id="article",
  )
}
```

Give every mounted document a unique, nonempty identifier containing ASCII
letters, digits, `_` or `-`. Heading and footnote target IDs include this
namespace. `on_link : Emit[String]` receives a sanitized destination;
`on_anchor : Emit[String]` receives the namespaced node ID for application-owned
scrolling. The renderer does not navigate or scroll automatically.

`transform_link` runs before URL validation for links and images. HTTPS,
relative paths and document anchors are supported; mailto is link-only.
Network paths, control characters, backslashes and other schemes are rejected.
Unsafe links remain readable text and unsafe images show their alternate text.
Raw HTML displays as text and never creates host markup.

CommonMark, tables, nested task lists, strikethrough and footnotes are enabled.
Tables and code blocks use horizontal native scrolling. Images are native
inline image runs; the default recipe supplies a bounded line image size.
`render_heading(Heading, Node)` and `render_codeblock(source, info)` may return
application-owned native nodes. No cmark AST appears in this public API.
Math and Mermaid are source text. Reading/callback support does not request a
clipboard capability or provide built-in code copying.

The parser is `moonbit-community/cmark@0.4.12` (Apache-2.0), a MoonBit parser
with casefold/charclass dependencies. Its character-entity build step invokes
`python3`; fresh development and CI environments need Python 3. Generated
MiniApps do not execute Python or load a browser Markdown runtime.
