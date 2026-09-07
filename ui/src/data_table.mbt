///|
struct DataColumn[T] {
  key : String
  label : String
  text : (T) -> String
  render : (T) -> @minimoon.Node
  sortable : Bool
  searchable : Bool
  hideable : Bool
  compare : (T, T) -> Int
}

///|
pub fn[T] data_column(
  key~ : String,
  label~ : String,
  text~ : (T) -> String,
  render? : (T) -> @minimoon.Node,
  sortable? : Bool = true,
  searchable? : Bool = true,
  hideable? : Bool = true,
  compare? : (T, T) -> Int,
  numeric_value? : (T) -> Double,
) -> DataColumn[T] {
  {
    key,
    label,
    text,
    render: render.unwrap_or(row => @minimoon.text(text(row))),
    sortable,
    searchable,
    hideable,
    compare: compare.unwrap_or((a, b) => {
      match numeric_value {
        Some(value) => value(a).compare(value(b))
        None => compare_text(text(a), text(b))
      }
    }),
  }
}

///|
pub(all) struct TableState {
  query : String
  page : Int
  page_size : Int
  sort_key : String
  descending : Bool
  selected_keys : Array[String]
  hidden_columns : Array[String]
} derive(Eq, Debug)

///|
pub fn table_state(page_size? : Int = 10) -> TableState {
  {
    query: "",
    page: 0,
    page_size: page_size.max(1),
    sort_key: "",
    descending: false,
    selected_keys: [],
    hidden_columns: [],
  }
}

///|
pub fn[C : @minimoon.IsChildren] table(
  children : C,
  id? : String = "",
  class? : String = "",
) -> @minimoon.Node {
  @minimoon.scroll_view(
    scroll_x=true,
    id~,
    class="mmui-table-scroll " + class,
    ui_container(
      "table",
      semantics=@minimoon.semantics(role=@minimoon.TableRole),
      children.to_nodes(),
    ),
  )
}

///|
pub fn[C : @minimoon.IsChildren] table_header(children : C) -> @minimoon.Node {
  ui_container("table-header", children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] table_body(children : C) -> @minimoon.Node {
  ui_container("table-body", children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] table_footer(children : C) -> @minimoon.Node {
  ui_container("table-footer", children.to_nodes())
}

///|
pub fn[C : @minimoon.IsChildren] table_row(
  children : C,
  selected? : Bool = false,
) -> @minimoon.Node {
  ui_container(
    "table-row",
    semantics=@minimoon.semantics(role=@minimoon.RowRole, selected~),
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] table_cell(children : C) -> @minimoon.Node {
  ui_container(
    "table-cell",
    semantics=@minimoon.semantics(role=@minimoon.CellRole),
    children.to_nodes(),
  )
}

///|
pub fn[C : @minimoon.IsChildren] table_head(children : C) -> @minimoon.Node {
  ui_container(
    "table-head",
    semantics=@minimoon.semantics(role=@minimoon.ColumnHeaderRole),
    children.to_nodes(),
  )
}

///|
pub fn table_caption(text : String) -> @minimoon.Node {
  ui_container("table-caption", [@minimoon.text(text)])
}

///|
pub fn pagination_controlled(
  id~ : String,
  page~ : @minimoon.Val[Int],
  total~ : @minimoon.Val[Int],
  on_change~ : @minimoon.Emit[Int],
  page_size? : Int = 10,
) -> @minimoon.Val[@minimoon.Node] {
  let dispatch = form_dispatch(
    @minimoon.Val::map2(page, total, (page, total) => (page, total)),
    (input, request : PaginationRequest) => {
      let (page, total) = input
      let maximum = @headless.page_count(total, page_size) - 1
      let current = page.clamp(min=0, max=maximum)
      let next = match request {
        Target(index) => index.clamp(min=0, max=maximum)
        Step(delta) => (current + delta).clamp(min=0, max=maximum)
      }
      if next == current {
        @minimoon.none
      } else {
        on_change(next)
      }
    },
  )
  @minimoon.Val::view2(page, total, (page, total) => {
    let count = @headless.page_count(total, page_size)
    let current = page.clamp(min=0, max=count - 1)
    let nodes : Array[@minimoon.Node] = [
      @minimoon.button(
        disabled=current == 0,
        event_key=id + "/previous",
        on_tap=if current == 0 { @minimoon.none } else { dispatch(Step(-1)) },
        "Previous",
      ),
    ]
    for index = (current - 2).max(0)
        index <= (current + 2).min(count - 1)
        index = index + 1 {
      nodes.push(
        @minimoon.button(
          event_key=id + "/" + index.to_string(),
          on_tap=dispatch(Target(index)),
          semantics=@minimoon.semantics(selected=index == current),
          (index + 1).to_string(),
        ),
      )
    }
    nodes.push(
      @minimoon.button(
        disabled=current + 1 == count,
        event_key=id + "/next",
        on_tap=if current + 1 == count {
          @minimoon.none
        } else {
          dispatch(Step(1))
        },
        "Next",
      ),
    )
    ui_container("pagination", id~, nodes)
  })
}

///|
pub fn pagination(
  id~ : String,
  total~ : @minimoon.Val[Int],
  page_size? : Int = 10,
) -> @minimoon.Val[@minimoon.Node] {
  let (page, emit) = @minimoon.create_variable(0)
  pagination_controlled(
    id~,
    page~,
    total~,
    on_change=emit.map(value => _ => value),
    page_size~,
  )
}

///|
fn compare_text(a : String, b : String) -> Int {
  let aa = a.iter().collect()
  let bb = b.iter().collect()
  for i = 0; i < aa.length().min(bb.length()); i = i + 1 {
    if aa[i] < bb[i] {
      return -1
    }
    if aa[i] > bb[i] {
      return 1
    }
  }
  aa.length().compare(bb.length())
}

///|
pub fn[T : Eq] data_table_controlled(
  id~ : String,
  rows~ : @minimoon.Val[Array[T]],
  columns~ : Array[DataColumn[T]],
  row_key~ : (T) -> String,
  state~ : @minimoon.Val[TableState],
  on_change~ : @minimoon.Emit[TableState],
  selectable? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let column_keys : Map[String, Bool] = Map([])
  for column in columns {
    guard column.key != "" && !column_keys.contains(column.key) else {
      abort("data table requires unique nonempty column keys")
    }
    column_keys[column.key] = true
  }
  let dispatch = data_table_dispatch(
    rows, state, columns, row_key, on_change, selectable,
  )
  @minimoon.Val::view2(rows, state, (rows, state) => {
    let keys : Map[String, Bool] = Map([])
    for row in rows {
      let key = row_key(row)
      guard key != "" && !keys.contains(key) else {
        abort("data table requires unique nonempty row keys")
      }
      keys[key] = true
    }
    let filtered = rows.filter(row => {
      state.query == "" ||
      columns.any(column => {
        column.searchable && (column.text)(row).contains(state.query)
      })
    })
    for column in columns {
      if column.key == state.sort_key && column.sortable {
        filtered.sort_by((a, b) => {
          // Normalize user comparators before reversal, including Int minimum.
          let order = (column.compare)(a, b).compare(0)
          if state.descending {
            -order
          } else {
            order
          }
        })
      }
    }
    let page_size = state.page_size.max(1)
    let page_count = @headless.page_count(filtered.length(), page_size)
    let page = state.page.clamp(min=0, max=page_count - 1)
    let visible_columns = columns.filter(column => {
      !column.hideable || !state.hidden_columns.contains(column.key)
    })
    let header : Array[@minimoon.Node] = []
    if selectable {
      header.push(table_head("Selected"))
    }
    for column in visible_columns {
      header.push(
        table_head(
          @minimoon.button(
            disabled=!column.sortable,
            event_key=id + "/sort/" + column.key,
            on_tap=if column.sortable {
              dispatch(Sort(column.key))
            } else {
              @minimoon.none
            },
            column.label,
          ),
        ),
      )
    }
    let body : Array[@minimoon.KeyedNode] = []
    for index = page * page_size
        index < ((page + 1) * page_size).min(filtered.length())
        index = index + 1 {
      let row = filtered[index]
      let key = row_key(row)
      let selected = state.selected_keys.contains(key)
      let cells : Array[@minimoon.Node] = []
      if selectable {
        cells.push(
          table_cell(
            @minimoon.button(
              event_key=id + "/select/" + key,
              on_tap=dispatch(Select(key)),
              semantics=@minimoon.semantics(checked=selected),
              if selected {
                "✓"
              } else {
                "○"
              },
            ),
          ),
        )
      }
      for column in visible_columns {
        cells.push(table_cell((column.render)(row)))
      }
      body.push(@minimoon.keyed(key, table_row(cells, selected~)))
    }
    ui_container("data-table", id~, [
      @minimoon.input(
        value=state.query,
        on_input=dispatch.map(query => Query(query)),
        event_key=id + "/filter",
        placeholder="Filter rows",
      ),
      ui_container(
        "data-table-columns",
        columns.filter_map(column => {
          if !column.hideable {
            return None
          }
          let hidden = state.hidden_columns.contains(column.key)
          Some(
            @minimoon.button(
              event_key=id + "/column/" + column.key,
              on_tap=dispatch(Column(column.key)),
              semantics=@minimoon.semantics(checked=!hidden),
              column.label,
            ),
          )
        }),
      ),
      table([
        table_header(table_row(header)),
        table_body(@minimoon.keyed_fragment(body)),
      ]),
      ui_container("pagination", [
        @minimoon.button(
          event_key=id + "/previous",
          disabled=page == 0,
          on_tap=if page == 0 { @minimoon.none } else { dispatch(PageStep(-1)) },
          "Previous",
        ),
        @minimoon.text((page + 1).to_string() + " / " + page_count.to_string()),
        @minimoon.button(
          event_key=id + "/next",
          disabled=page + 1 == page_count,
          on_tap=if page + 1 == page_count {
            @minimoon.none
          } else {
            dispatch(PageStep(1))
          },
          "Next",
        ),
      ]),
    ])
  })
}

///|
pub fn[T : Eq] data_table(
  id~ : String,
  rows~ : @minimoon.Val[Array[T]],
  columns~ : Array[DataColumn[T]],
  row_key~ : (T) -> String,
  page_size? : Int = 10,
  selectable? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  let (state, emit) = @minimoon.create_variable(table_state(page_size~))
  data_table_controlled(
    id~,
    rows~,
    columns~,
    row_key~,
    state~,
    on_change=emit.map(value => _ => value),
    selectable~,
  )
}
