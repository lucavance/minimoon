///|
fn render_inline(
  context : Context,
  value : @cmark.Inline,
  style~ : String = "",
  command? : @minimoon.Cmd,
  class~ : String = "",
) -> Array[@minimoon.Inline] {
  let text = value => {
    [@minimoon.inline_text(value, style~, class~, on_tap?=command)]
  }
  match value {
    Text(node) => text(node.v)
    Break(node) => text(if node.v.ty is Soft { " " } else { "\n" })
    Inlines(nodes) =>
      nodes.v
      .iter()
      .flat_map(node => {
        render_inline(context, node, style~, command?, class~).iter()
      })
      .collect()
    Emphasis(node) =>
      render_inline(
        context,
        node.v.inline,
        style=style + "font-style:italic;",
        command?,
        class~,
      )
    StrongEmphasis(node) =>
      render_inline(
        context,
        node.v.inline,
        style=style + "font-weight:700;",
        command?,
        class~,
      )
    ExtStrikethrough(node) => {
      let @cmark.InlineStrikethrough(child) = node.v
      render_inline(
        context,
        child,
        style=style + "text-decoration:line-through;",
        command?,
        class~,
      )
    }
    CodeSpan(node) =>
      [
        @minimoon.inline_text(
          node.v.code(),
          style~,
          class="mmui-markdown-code",
          on_tap?=command,
        ),
      ]
    RawHtml(node) => {
      let @cmark.InlineRawHtml(parts) = node.v
      text(parts.iter().map(part => part.to_string()).join("\n"))
    }
    ExtMathSpan(node) =>
      text(
        (if node.v.display { "$$" } else { "$" }) +
        node.v.tex() +
        (if node.v.display { "$$" } else { "$" }),
      )
    Autolink(node) => {
      let target = (context.transform_link)(
        (if node.v.is_email { "mailto:" } else { "" }) + node.v.link.v,
      )
      let command = if safe_url(target, false) {
        link_command(context, target)
      } else {
        None
      }
      [
        @minimoon.inline_text(
          node.v.link.v,
          style~,
          class="mmui-markdown-link",
          on_tap?=command,
        ),
      ]
    }
    Link(node) | Image(node) => {
      let image = value is Image(_)
      match node.v.reference_definition(context.doc.defs) {
        Some(LinkDef(definition)) => {
          let target = (context.transform_link)(
            definition.v.dest.map(dest => dest.v).unwrap_or(""),
          )
          if !safe_url(target, image) {
            return text(plain(node.v.text))
          }
          if image {
            [
              @minimoon.inline_image(
                src=target,
                alt=plain(node.v.text),
                class="mmui-markdown-image",
              ),
            ]
          } else {
            render_inline(
              context,
              node.v.text,
              style~,
              command?=link_command(context, target),
              class="mmui-markdown-link",
            )
          }
        }
        Some(FootnoteDef(note)) => {
          let target = footnote_id(context.id, note.v.label.key)
          let command = context.on_anchor.map(emit => emit(target))
          [
            @minimoon.inline_text(
              "[" + note.v.label.key + "]",
              class="mmui-markdown-link",
              style="font-size:12px;",
              on_tap?=command,
            ),
          ]
        }
        None => text(plain(node.v.text))
      }
    }
  }
}
