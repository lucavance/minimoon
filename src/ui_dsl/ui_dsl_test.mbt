///|
test "concrete nodes render deterministically" {
  let tree = div(id="root", class="panel", [
    h1("Title"),
    input(attrs=[value_attr("MoonBit")]),
  ])
  inspect(
    render_to_string(tree),
    content="<div id=\"root\" class=\"panel\"><h1>Title</h1><input value=\"MoonBit\"></input></div>",
  )
}

///|
test "event keys map recursively through fragments and keyed children" {
  let tree = fragment([
    button(on_click="save", "Save"),
    keyed_fragment([keyed("a", input(attrs=[attr("on_input", "rename")]))]),
  ])
  let mapped = map_event_keys(tree, key => "card/" + key)
  inspect(
    render_to_string(mapped),
    content="<button on_click=\"card/save\">Save</button><input on_input=\"card/rename\"></input>",
  )
}

///|
test "keyed nodes preserve key and node" {
  let item = keyed("stable", text("value"))
  assert_eq(item.key(), "stable")
  inspect(render_to_string(item.node()), content="value")
  assert_eq(keyed_nodes(keyed_fragment([item])).length(), 1)
}
