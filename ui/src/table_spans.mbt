///|
/// Native span descriptor: use with table_spanning, not the flex table_row API.
pub struct TableSpanCell {
  content : @minimoon.Node
  colspan : Int
  rowspan : Int
  header : Bool
}

///|
pub fn[C : @minimoon.IsChildren] table_span_cell(
  children : C,
  colspan? : Int = 1,
  rowspan? : Int = 1,
  header? : Bool = false,
) -> TableSpanCell {
  guard colspan > 0 && rowspan > 0 else {
    abort("table spans must be positive")
  }
  {
    content: @minimoon.fragment(children.to_nodes()),
    colspan,
    rowspan,
    header,
  }
}

///|
pub fn[C : @minimoon.IsChildren] table_span_head(
  children : C,
  colspan? : Int = 1,
  rowspan? : Int = 1,
) -> TableSpanCell {
  table_span_cell(children, colspan~, rowspan~, header=true)
}

///|
/// Equal-width columns and explicit row height provide real two-dimensional spans
/// without depending on HTML table or CSS grid behavior in Skyline. Empty rows
/// reserve space for cells carried from previous rows. Children must fit their
/// bounded cell; overflowing content is clipped. Invalid overlap/bounds abort.
pub fn table_spanning(
  rows~ : Array[Array[TableSpanCell]],
  columns~ : Int,
  row_height? : Int = 48,
  min_width? : Int = 0,
  id? : String = "",
) -> @minimoon.Node {
  guard columns > 0 &&
    columns <= 100 &&
    rows.length() <= 10000 &&
    row_height > 0 &&
    row_height <= 10000 &&
    min_width >= 0 else {
    abort("invalid native spanning table dimensions")
  }
  let occupied = Array::make(rows.length() * columns, false)
  let row_nodes : Array[@minimoon.Node] = []
  for row_index, cells in rows {
    let nodes : Array[@minimoon.Node] = []
    let mut column = 0
    for cell in cells {
      while column < columns && occupied[row_index * columns + column] {
        column = column + 1
      }
      guard cell.colspan > 0 &&
        cell.rowspan > 0 &&
        cell.colspan <= columns - column &&
        cell.rowspan <= rows.length() - row_index else {
        abort("table span exceeds table bounds")
      }
      for y = row_index; y < row_index + cell.rowspan; y = y + 1 {
        for x = column; x < column + cell.colspan; x = x + 1 {
          guard !occupied[y * columns + x] else { abort("table spans overlap") }
          occupied[y * columns + x] = true
        }
      }
      let left = column.to_double() * 100.0 / columns.to_double()
      let width = cell.colspan.to_double() * 100.0 / columns.to_double()
      nodes.push(
        ui_container(
          if cell.header {
            "table-head"
          } else {
            "table-cell"
          },
          style="position:absolute;box-sizing:border-box;overflow:hidden;min-width:0;top:0;left:" +
            left.to_string() +
            "%;width:" +
            width.to_string() +
            "%;height:" +
            (cell.rowspan * row_height).to_string() +
            "px;",
          semantics=@minimoon.semantics(
            role=if cell.header {
              @minimoon.ColumnHeaderRole
            } else {
              @minimoon.CellRole
            },
          ),
          [cell.content],
        ),
      )
      column = column + cell.colspan
    }
    row_nodes.push(
      ui_container(
        "table-span-row",
        style="position:relative;height:" + row_height.to_string() + "px;",
        semantics=@minimoon.semantics(role=@minimoon.RowRole),
        nodes,
      ),
    )
  }
  @minimoon.scroll_view(
    scroll_x=true,
    class="mmui-table-scroll",
    ui_container(
      "table-spanning",
      id~,
      style="min-width:" + min_width.to_string() + "px;",
      semantics=@minimoon.semantics(role=@minimoon.TableRole),
      row_nodes,
    ),
  )
}
