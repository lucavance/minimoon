///|
/// A heading independent of the parser AST. `id` is namespaced for this document.
pub(all) struct Heading {
  level : Int32
  id : String
  text : String
}

///|
priv struct Context {
  id : String
  doc : @cmark.Doc
  on_link : @minimoon.Emit[String]?
  on_anchor : @minimoon.Emit[String]?
  transform_link : (String) -> String
  render_heading : ((Heading, @minimoon.Node) -> @minimoon.Node)?
  render_codeblock : ((String, String) -> @minimoon.Node)?
  heading_anchors : Bool
  heading_labels : Set[String]
}

///|
/// Render CommonMark plus tables, tasks, strikethrough and footnotes. Links
/// emit callbacks; raw HTML and math/Mermaid source are displayed as text.
/// Import this package explicitly; the root UI package does not import cmark.
pub fn markdown(
  source : String,
  id~ : String,
  on_link? : @minimoon.Emit[String],
  on_anchor? : @minimoon.Emit[String],
  transform_link~ : (String) -> String = value => value,
  render_heading? : (Heading, @minimoon.Node) -> @minimoon.Node,
  render_codeblock? : (String, String) -> @minimoon.Node,
  heading_anchors~ : Bool = true,
) -> @minimoon.Node {
  guard id != "" &&
    id
    .iter()
    .all(ch => {
      ch.is_ascii_alphabetic() || ch.is_ascii_digit() || ch == '-' || ch == '_'
    }) else {
    abort("markdown id must be a nonempty MiniApp identifier")
  }
  let doc = @cmark.Doc::from_string(source, strict=false, heading_auto_ids=true)
  let context = {
    id,
    doc,
    on_link,
    on_anchor,
    transform_link,
    render_heading,
    render_codeblock,
    heading_anchors,
    heading_labels: Set([]),
  }
  let children = render_block(context, doc.block)
  let footnotes : Array[@minimoon.Node] = []
  // Definitions live in the parser's definition map, not at the source location.
  // Sort keys so output is stable across backends and map implementations.
  let keys = doc.defs.keys().collect()
  keys.sort()
  for key in keys {
    if doc.defs.get(key) is Some(FootnoteDef(note)) {
      footnotes.push(
        @minimoon.div(id=footnote_id(id, key), [
          @minimoon.inline([@minimoon.inline_text(key + ". ")]),
          @minimoon.div(render_block(context, note.v.block)),
        ]),
      )
    }
  }
  if !footnotes.is_empty() {
    children.push(@minimoon.div(class="mmui-markdown-footnotes", footnotes))
  }
  @minimoon.div(id~, class="mmui-markdown", children)
}

///|
fn anchor_id(document_id : String, label : String) -> String {
  namespaced_id(document_id, "h", label)
}

///|
fn footnote_id(document_id : String, label : String) -> String {
  namespaced_id(document_id, "f", label)
}

///|
fn namespaced_id(document_id : String, kind : String, label : String) -> String {
  let output = StringBuilder()
  output.write_string(document_id + "-md-" + kind + "-")
  for ch in label.iter() {
    // Encode every character, including separators, to avoid collisions.
    output.write_string(ch.to_int().to_string(radix=16) + "-")
  }
  output.to_string()
}

///|
fn plain(value : @cmark.Inline) -> String {
  value
  .to_plain_text(break_on_soft=false)
  .iter()
  .map(line => line.iter().join(""))
  .join("\n")
}

///|
fn safe_url(value : String, image : Bool) -> Bool {
  if value == "" ||
    value.has_prefix("//") ||
    value
    .iter()
    .any(ch => ch.to_int() <= 32 || ch.to_int() == 127 || ch == '\\') {
    return false
  }
  // Accept only explicit safe schemes or local paths. Sanitization is applied
  // after application rewriting, including entity-decoded parser destinations.
  if value.has_prefix("https://") {
    return true
  }
  if !image && (value.has_prefix("#") || value.has_prefix("mailto:")) {
    return true
  }
  !value.contains(":") && !value.has_prefix("#")
}

///|
fn link_command(context : Context, target : String) -> @minimoon.Cmd? {
  if target.has_prefix("#") {
    context.on_anchor.map(emit => {
      emit(anchor_id(context.id, target[1:].to_owned()))
    })
  } else {
    context.on_link.map(emit => emit(target))
  }
}
