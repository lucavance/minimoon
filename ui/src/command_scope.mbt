///|
struct CommandScope {
  id : String
  query : String
  update_query : @minimoon.Emit[String]
  select : @minimoon.Emit[(String, @minimoon.Cmd)]
  filter : (String, String, Array[String]) -> Bool
  should_filter : Bool
  open : Bool
  show : @minimoon.Cmd
  close : @minimoon.Cmd
}

///|
pub fn command_query(scope : CommandScope) -> String {
  scope.query
}

///|
pub fn command_is_open(scope : CommandScope) -> Bool {
  scope.open
}

///|
pub fn command_open(scope : CommandScope) -> @minimoon.Cmd {
  scope.show
}

///|
pub fn command_close(scope : CommandScope) -> @minimoon.Cmd {
  scope.close
}

///|
pub fn command_input(
  scope : CommandScope,
  placeholder? : String = "Search commands",
  disabled? : Bool = false,
) -> @minimoon.Node {
  @minimoon.input(
    event_key=scope.id + "/query",
    value=scope.query,
    disabled~,
    on_input=@minimoon.Emit(value => {
      if disabled {
        @minimoon.none
      } else {
        (scope.update_query)(value)
      }
    }),
    placeholder~,
  )
}

///|
pub fn[C : @minimoon.IsChildren] command_item(
  scope : CommandScope,
  value~ : String,
  children : C,
  keywords? : Array[String] = [],
  disabled? : Bool = false,
  force_mount? : Bool = false,
  on_select? : @minimoon.Emit[String],
  on_click? : @minimoon.Cmd,
) -> @minimoon.Node {
  if !force_mount &&
    scope.should_filter &&
    !(scope.filter)(value, scope.query, keywords) {
    return @minimoon.nothing()
  }
  @minimoon.button_children(
    event_key=scope.id + "/item/" + value,
    disabled~,
    on_tap=if disabled {
      @minimoon.none
    } else {
      (scope.select)(
        (
          value,
          @minimoon.batch([
            on_select.map(emit => emit(value)).unwrap_or(@minimoon.none),
            on_click.unwrap_or(@minimoon.none),
          ]),
        ),
      )
    },
    children,
  )
}

///|
fn default_command_filter(
  value : String,
  query : String,
  keywords : Array[String],
) -> Bool {
  value.to_lower().contains(query.to_lower()) ||
  keywords.any(keyword => keyword.to_lower().contains(query.to_lower()))
}

///|
pub fn command_provider_controlled(
  id~ : String,
  query~ : @minimoon.Val[String],
  on_query_change~ : @minimoon.Emit[String],
  render~ : (CommandScope) -> @minimoon.Node,
  on_value_select? : @minimoon.Emit[String],
  should_filter? : Bool = true,
  filter? : (String, String, Array[String]) -> Bool = default_command_filter,
) -> @minimoon.Val[@minimoon.Node] {
  query.map(query => {
    let scope = CommandScope::{
      id,
      query,
      update_query: on_query_change,
      select: @minimoon.Emit(request => {
        let (value, command) = request
        @minimoon.batch([
          on_value_select.map(emit => emit(value)).unwrap_or(@minimoon.none),
          command,
        ])
      }),
      should_filter,
      filter,
      open: true,
      show: @minimoon.none,
      close: @minimoon.none,
    }
    ui_container("command", id~, [render(scope)])
  })
}

///|
pub fn command_provider(
  id~ : String,
  render~ : (CommandScope) -> @minimoon.Node,
  initial_query? : String = "",
  on_value_select? : @minimoon.Emit[String],
  on_query_change? : @minimoon.Emit[String],
  should_filter? : Bool = true,
  filter? : (String, String, Array[String]) -> Bool = default_command_filter,
) -> @minimoon.Val[@minimoon.Node] {
  let (query, emit) = @minimoon.create_variable(initial_query)
  command_provider_controlled(
    id~,
    query~,
    on_query_change=@minimoon.Emit(query => {
      @minimoon.batch([
        emit(_ => query),
        on_query_change.map(emit => emit(query)).unwrap_or(@minimoon.none),
      ])
    }),
    render~,
    on_value_select?,
    should_filter~,
    filter~,
  )
}

///|
pub fn command_dialog(
  context : UiContext,
  id~ : String,
  title~ : String,
  trigger_label~ : String,
  render~ : (CommandScope) -> @minimoon.Node,
  initial_query? : String = "",
  initially_open? : Bool = false,
  should_filter? : Bool = true,
  filter? : (String, String, Array[String]) -> Bool = default_command_filter,
  close_on_select? : Bool = true,
  close_on_overlay? : Bool = true,
  on_query_change? : @minimoon.Emit[String],
  on_value_select? : @minimoon.Emit[String],
  on_open_change? : @minimoon.Emit[Bool],
) -> @minimoon.Val[@minimoon.Node] {
  let (query, set_query) = @minimoon.create_variable(initial_query)
  let (open, set_open) = @minimoon.create_variable(initially_open)
  let change_open = @minimoon.Emit(open => {
    @minimoon.batch([
      set_open(_ => open),
      on_open_change.map(emit => emit(open)).unwrap_or(@minimoon.none),
    ])
  })
  let select = form_dispatch(
    @minimoon.Val::map2(open, context.visible, (open, visible) => {
      open && visible
    }),
    (active, request : (String, @minimoon.Cmd)) => {
      if !active {
        return @minimoon.none
      }
      let (value, command) = request
      @minimoon.batch([
        on_value_select.map(emit => emit(value)).unwrap_or(@minimoon.none),
        command,
        if close_on_select {
          change_open(false)
        } else {
          @minimoon.none
        },
      ])
    },
  )
  let content = @minimoon.Val::view2(query, open, (query, open) => {
    render(CommandScope::{
      id,
      query,
      update_query: @minimoon.Emit(query => {
        @minimoon.batch([
          set_query(_ => query),
          on_query_change.map(emit => emit(query)).unwrap_or(@minimoon.none),
        ])
      }),
      select,
      filter,
      should_filter,
      open,
      show: change_open(true),
      close: change_open(false),
    })
  })
  overlay_controlled(
    context,
    id~,
    title~,
    trigger_label~,
    content~,
    open~,
    on_change=change_open,
    close_on_overlay~,
  )
}
