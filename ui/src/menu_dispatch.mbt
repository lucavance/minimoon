///|
fn find_menu_item(
  id : String,
  items : Array[MenuItem],
  key : String,
) -> MenuItem? {
  for item in items {
    let path = id + "/" + item.key
    if path == key {
      return Some(item)
    }
    if !item.disabled {
      match item.kind {
        Branch(children) | Group(children) =>
          if find_menu_item(path, children, key) is Some(found) {
            return Some(found)
          }
        _ => ()
      }
    }
  }
  None
}

///|
fn menu_dispatch(
  id : String,
  items : @minimoon.Val[Array[MenuItem]],
  close : @minimoon.Cmd,
  open? : @minimoon.Val[Bool] = @minimoon.Val::constant(true),
) -> (@minimoon.Val[Array[String]], @minimoon.Emit[String]) {
  @minimoon.create_state_with_input(
    input=@minimoon.Val::map2(items, open, (items, open) => (items, open)),
    init=(_, _) => @minimoon.no_cmd(([] : Array[String])),
    update=(expanded, input, key : String, _) => {
      let (items, open) = input
      if !open {
        return @minimoon.no_cmd(expanded)
      }
      guard find_menu_item(id, items, key) is Some(item) && !item.disabled else {
        return @minimoon.no_cmd(expanded)
      }
      match item.kind {
        Branch(_) => {
          let next = expanded.copy()
          if next.contains(key) {
            @minimoon.no_cmd(next.filter(value => value != key))
          } else {
            next.push(key)
            @minimoon.no_cmd(next)
          }
        }
        Heading | Divider | Group(_) => @minimoon.no_cmd(expanded)
        _ => {
          let command = match item.kind {
            Action(command) => command
            Check(checked, emit) => emit(!checked)
            Radio(_, command) => command
            _ => @minimoon.none
          }
          let should_close = item.presentation.unwrap_or(
            default_menu_presentation(item.label),
          ).close_on_select.unwrap_or(item.kind is Action(_))
          (
            expanded,
            @minimoon.batch([
              command,
              if should_close {
                close
              } else {
                @minimoon.none
              },
            ]),
          )
        }
      }
    },
  )
}
