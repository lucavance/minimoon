///|
test "concrete nodes render deterministically" {
  let tree = @ui_dsl.div(id="root", class="panel", [
    @ui_dsl.h1("Title"),
    @ui_dsl.input(attrs=[@ui_dsl.value_attr("MoonBit")]),
  ])
  inspect(
    @ui_dsl.render_to_string(tree),
    content="<div id=\"root\" class=\"panel\"><h1>Title</h1><input value=\"MoonBit\"></input></div>",
  )
}

///|
test "event keys map recursively through fragments and keyed children" {
  let tree = @ui_dsl.fragment([
    @ui_dsl.button(on_click="save", "Save"),
    @ui_dsl.keyed_fragment([
      @ui_dsl.keyed(
        "a",
        @ui_dsl.input(attrs=[@ui_dsl.attr("on_input", "rename")]),
      ),
    ]),
  ])
  let mapped = @ui_dsl.map_event_keys(tree, key => "card/" + key)
  inspect(
    @ui_dsl.render_to_string(mapped),
    content="<button on_click=\"card/save\">Save</button><input on_input=\"card/rename\"></input>",
  )
}

///|
test "keyed nodes preserve key and node" {
  let item = @ui_dsl.keyed("stable", @ui_dsl.text("value"))
  assert_eq(item.key(), "stable")
  inspect(@ui_dsl.render_to_string(item.node()), content="value")
  assert_eq(@ui_dsl.keyed_nodes(@ui_dsl.keyed_fragment([item])).length(), 1)
}
