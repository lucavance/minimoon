///|
priv enum CalendarRequest {
  Choose(@headless.CalendarDate)
  ShiftMonth(Int)
}

///|
priv enum PaginationRequest {
  Target(Int)
  Step(Int)
}

///|
priv enum DataTableRequest {
  Sort(String)
  Select(String)
  Column(String)
  Query(String)
  PageStep(Int)
}

///|
fn data_toggle_key(keys : Array[String], key : String) -> Array[String] {
  if keys.contains(key) {
    keys.filter(value => value != key)
  } else {
    let next = keys.copy()
    next.push(key)
    next
  }
}

///|
fn[T : Eq] data_table_dispatch(
  rows : @minimoon.Val[Array[T]],
  state : @minimoon.Val[TableState],
  columns : Array[DataColumn[T]],
  row_key : (T) -> String,
  change : @minimoon.Emit[TableState],
  selectable : Bool,
) -> @minimoon.Emit[DataTableRequest] {
  form_dispatch(
    @minimoon.Val::map2(rows, state, (rows, state) => (rows, state)),
    (input, request : DataTableRequest) => {
      let (rows, state) = input
      let next = match request {
        Sort(key) => {
          guard columns.any(column => column.key == key && column.sortable) else {
            return @minimoon.none
          }
          {
            ..state,
            page: 0,
            sort_key: key,
            descending: key == state.sort_key && !state.descending,
          }
        }
        Select(key) => {
          guard selectable && rows.any(row => row_key(row) == key) else {
            return @minimoon.none
          }
          { ..state, selected_keys: data_toggle_key(state.selected_keys, key), }
        }
        Column(key) => {
          guard columns.any(column => column.key == key && column.hideable) else {
            return @minimoon.none
          }
          {
            ..state,
            hidden_columns: data_toggle_key(state.hidden_columns, key),
          }
        }
        Query(query) => { ..state, query, page: 0, }
        PageStep(delta) => {
          let total = rows
            .filter(row => {
              state.query == "" ||
              columns.any(column => {
                column.searchable && (column.text)(row).contains(state.query)
              })
            })
            .length()
          let count = @headless.page_count(total, state.page_size.max(1))
          let current = state.page.clamp(min=0, max=count - 1)
          { ..state, page: (current + delta).clamp(min=0, max=count - 1), }
        }
      }
      if next == state {
        @minimoon.none
      } else {
        change(next)
      }
    },
  )
}
