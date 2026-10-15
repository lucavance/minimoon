///|
fn render_block(
  context : Context,
  block : @cmark.Block,
) -> Array[@minimoon.Node] {
  match block {
    BlankLine(_) | LinkRefDefinition(_) | ExtFootnoteDefinition(_) => []
    Blocks(nodes) =>
      nodes.v
      .iter()
      .flat_map(node => render_block(context, node).iter())
      .collect()
    Paragraph(node) =>
      [
        @minimoon.div(class="mmui-markdown-p", [
          @minimoon.inline(render_inline(context, node.v.inline)),
        ]),
      ]
    Heading(node) => {
      let label = match node.v.id {
        Some(Auto(id)) | Some(Id(id)) => id
        None => node.v.inline.id()
      }
      // cmark supplies a slug but does not deduplicate repeated headings.
      let mut unique = label
      let mut suffix = 1
      while context.heading_labels.contains(unique) {
        unique = label + "-" + suffix.to_string()
        suffix += 1
      }
      context.heading_labels.add(unique)
      let id = anchor_id(context.id, unique)
      let heading = Heading::{
        level: node.v.level,
        id,
        text: plain(node.v.inline),
      }
      let content = @minimoon.inline(render_inline(context, node.v.inline))
      let content = match context.render_heading {
        Some(render) => render(heading, content)
        None => content
      }
      [
        @minimoon.div(
          id=if context.heading_anchors { id } else { "" },
          class="mmui-markdown-h" + node.v.level.to_string(),
          semantics=@minimoon.semantics(role=HeadingRole),
          [content],
        ),
      ]
    }
    BlockQuote(node) =>
      [
        @minimoon.div(
          class="mmui-markdown-quote",
          render_block(context, node.v.block),
        ),
      ]
    HtmlBlock(node) => {
      let @cmark.HtmlBlock(lines) = node.v
      [
        @minimoon.div(
          class="mmui-markdown-html",
          lines.iter().map(line => line.v).join("\n"),
        ),
      ]
    }
    ThematicBreak(_) =>
      [@minimoon.div(class="mmui-markdown-rule", @minimoon.nothing())]
    CodeBlock(node) | ExtMathBlock(node) => {
      let code = node.v.code.iter().map(line => line.v).join("\n")
      let info = if block is ExtMathBlock(_) {
        "math"
      } else {
        node.v.info_string.map(info => info.v).unwrap_or("")
      }
      let content = match context.render_codeblock {
        Some(render) => render(code, info)
        None => @minimoon.div(class="mmui-markdown-codeblock", code)
      }
      [
        @minimoon.scroll_view(scroll_x=true, class="mmui-markdown-scroll", [
          content,
        ]),
      ]
    }
    List(node) => {
      let start = match node.v.ty {
        @base.Ordered(start, _) => Some(start)
        @base.Unordered(_) => None
      }
      let items : Array[@minimoon.Node] = []
      for item in node.v.items.iter() {
        let marker = match item.v.ext_task_marker {
          Some(marker) => if marker.v == ' ' { "☐" } else { "☑" }
          None =>
            if start is Some(number) {
              (number + items.length()).to_string() + "."
            } else {
              "•"
            }
        }
        items.push(
          @minimoon.div(class="mmui-markdown-list-item", [
            @minimoon.text(marker),
            @minimoon.div(
              class="mmui-markdown-list-content",
              render_block(context, item.v.block),
            ),
          ]),
        )
      }
      [@minimoon.div(items)]
    }
    ExtTable(node) => render_table(context, node.v)
  }
}

///|
fn render_table(
  context : Context,
  table : @cmark.Table,
) -> Array[@minimoon.Node] {
  let align : Array[String] = []
  for (row, _) in table.rows.iter() {
    if row.v is Sep(cells) {
      for cell in cells.iter() {
        let @cmark.TableSep((value, _)) = cell.v
        align.push(
          match value {
            Some(Center) => "center"
            Some(Right) => "right"
            _ => "left"
          },
        )
      }
    }
  }
  let rows : Array[@minimoon.Node] = []
  for (row, _) in table.rows.iter() {
    let header = row.v is Header(_)
    match row.v {
      Sep(_) => ()
      Header(cells) | Data(cells) => {
        let nodes : Array[@minimoon.Node] = []
        for (cell, _) in cells.iter() {
          let alignment = align.get(nodes.length()).unwrap_or("left")
          nodes.push(
            @minimoon.div(
              class="mmui-markdown-cell" +
                (if header { " mmui-markdown-header" } else { "" }),
              style="text-align:" + alignment + ";",
              semantics=@minimoon.semantics(
                role=if header { ColumnHeaderRole } else { CellRole },
              ),
              [@minimoon.inline(render_inline(context, cell))],
            ),
          )
        }
        rows.push(
          @minimoon.div(
            class="mmui-markdown-row",
            semantics=@minimoon.semantics(role=RowRole),
            nodes,
          ),
        )
      }
    }
  }
  [
    @minimoon.scroll_view(scroll_x=true, class="mmui-markdown-scroll", [
      @minimoon.div(
        class="mmui-markdown-table",
        semantics=@minimoon.semantics(role=TableRole),
        rows,
      ),
    ]),
  ]
}
