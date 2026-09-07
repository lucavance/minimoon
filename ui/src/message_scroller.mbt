///|
/// Native message viewport adapted from RUI b1291945 (MIT), with explicit keyed updates.
pub(all) struct MessageItem {
  key : String
  content : @minimoon.Node
} derive(Eq)

///|
pub fn message_item(key~ : String, content~ : @minimoon.Node) -> MessageItem {
  guard key != "" else { abort("message item requires a stable key") }
  { key, content, }
}

///|
pub(all) enum MessageScrollDirection {
  ScrollStart
  ScrollEnd
} derive(Eq, Debug)

///|
priv struct MessageScrollState {
  token : Int
  keys : Array[String]
  top : Double
  content_height : Double
  viewport_height : Double
  at_start : Bool
  at_end : Bool
  scroll_target : String
  prepend : Bool
} derive(Eq)

///|
priv enum MessageScrollMsg {
  ItemsChanged(Array[String])
  Scrolled(@minimoon.ScrollDetail)
  Jump(MessageScrollDirection)
  Reached(MessageScrollDirection)
  Pause
  Refresh
  MeasuredScroll(Int, Result[Array[@minimoon.NodeRect?], @minimoon.HostError])
}

///|
fn messages_prepended(
  previous : Array[String],
  current : Array[String],
) -> Bool {
  if previous.is_empty() || current.length() <= previous.length() {
    return false
  }
  let offset = current.length() - previous.length()
  for index, key in previous {
    if current[index + offset] != key {
      return false
    }
  }
  true
}

///|
fn message_signature(items : Array[MessageItem], revision : Int) -> String {
  let seen : Set[String] = Set([])
  let parts = [revision.to_string()]
  for item in items {
    guard item.key != "" && !seen.contains(item.key) else {
      abort("message scroller requires unique stable item keys")
    }
    seen.add(item.key)
    parts.push(item.key.length().to_string() + ":" + item.key)
  }
  parts.join("|")
}

///|
/// Increment content_revision for streamed edits or asynchronously resized content
/// without a key change. Appending/prepending keyed items is observed automatically.
/// render_button receives direction, guarded jump command, and disabled state.
/// Keyed height-delta anchoring replaces browser per-element overflow-anchor.
pub fn message_scroller(
  context : UiContext,
  id~ : String,
  items~ : @minimoon.Val[Array[MessageItem]],
  content_revision? : @minimoon.Val[Int] = @minimoon.Val::constant(0),
  initially_at_end? : Bool = true,
  height? : String = "320px",
  show_buttons? : Bool = true,
  render_button? : (MessageScrollDirection, @minimoon.Cmd, Bool) -> @minimoon.Node,
) -> @minimoon.Val[@minimoon.Node] {
  let input = @minimoon.Val::map2(items, content_revision, (items, revision) => {
    (items, revision)
  })
  let initial = MessageScrollState::{
    token: 0,
    keys: [],
    top: 0.0,
    content_height: 0.0,
    viewport_height: 0.0,
    at_start: !initially_at_end,
    at_end: initially_at_end,
    scroll_target: "",
    prepend: false,
  }
  let (state, emit) = @minimoon.create_state_with_input(
    input~,
    init=(_, _) => @minimoon.no_cmd(initial),
    update=(state, input, msg : MessageScrollMsg, emit) => {
      match msg {
        Pause =>
          @minimoon.no_cmd({
            ..state,
            token: state.token + 1,
            prepend: false,
            scroll_target: "",
          })
        ItemsChanged(_) | Refresh => {
          let keys = match msg {
            ItemsChanged(keys) => keys
            _ => input.0.map(item => item.key)
          }
          let token = state.token + 1
          (
            {
              ..state,
              token,
              keys,
              prepend: !state.at_end && messages_prepended(state.keys, keys),
              scroll_target: if state.at_end {
                id + "-end-" + token.to_string()
              } else {
                ""
              },
            },
            @minimoon.measure_nodes(
              [id + "-viewport", id + "-content"],
              emit.map(result => MeasuredScroll(token, result)),
            ),
          )
        }
        MeasuredScroll(token, result) => {
          guard token == state.token &&
            result is Ok([Some(viewport), Some(content)]) else {
            return @minimoon.no_cmd(state)
          }
          let limit = (content.height - viewport.height).max(0.0)
          let top = if state.at_end {
            limit
          } else if state.prepend {
            (state.top + content.height - state.content_height).clamp(
              min=0.0,
              max=limit,
            )
          } else {
            state.top.min(limit)
          }
          @minimoon.no_cmd({
            ..state,
            top,
            content_height: content.height,
            viewport_height: viewport.height,
            at_start: top <= 2.0,
            at_end: top >= limit - 2.0,
            prepend: false,
          })
        }
        Scrolled(detail) => {
          let top = detail.scroll_top.max(0.0)
          @minimoon.no_cmd({
            ..state,
            top,
            content_height: detail.scroll_height,
            at_start: top <= 2.0,
            at_end: if state.viewport_height > 0.0 {
              top + state.viewport_height >= detail.scroll_height - 2.0
            } else {
              state.at_end
            },
            scroll_target: "",
          })
        }
        Jump(direction) => {
          let token = state.token + 1
          let end = direction == ScrollEnd
          @minimoon.no_cmd({
            ..state,
            token,
            top: if end {
              (state.content_height - state.viewport_height).max(0.0)
            } else {
              0.0
            },
            at_start: !end,
            at_end: end,
            prepend: false,
            scroll_target: if end {
              id + "-end-" + token.to_string()
            } else {
              id + "-start"
            },
          })
        }
        Reached(direction) =>
          @minimoon.no_cmd(
            if direction == ScrollEnd {
              { ..state, at_end: true, }
            } else {
              { ..state, at_start: true, }
            },
          )
      }
    },
    subscriptions=(_, _, emit) => {
      @minimoon.Sub::batch([
        context.page.on_hide(emit(Pause)),
        context.page.on_show(emit(Refresh)),
      ])
    },
  )
  // A keyed dynamic scope owns the one-shot update command. No effects run from a view.
  let watcher = input.switch_by(
    (input, _) => {
      let (_, _) = @minimoon.create_state_with_init(
        init=_ => ((), emit(ItemsChanged(input.0.map(item => item.key)))),
        update=(_, _ : Unit, _) => @minimoon.no_cmd(()),
      )
      @minimoon.Val::constant(@minimoon.nothing())
    },
    by=input => message_signature(input.0, input.1),
  )
  let view = @minimoon.Val::view2(items, state, (items, state) => {
    let messages = items.map(item => {
      @minimoon.keyed(
        item.key,
        ui_container(
          "message-scroller-item",
          [item.content],
          style="flex-shrink:0;min-width:0;",
        ),
      )
    })
    ui_container(
      "message-scroller",
      id~,
      style="position:relative;height:" + height + ";",
      [
        @minimoon.scroll_view(
          id=id + "-viewport",
          class="mmui-message-scroller-viewport",
          style="height:100%;",
          scroll_y=true,
          scroll_top_px=state.top,
          scroll_into_view=state.scroll_target,
          upper_threshold=2,
          lower_threshold=2,
          on_scroll=emit.map(detail => Scrolled(detail)),
          scroll_key=id + "/scroll",
          on_upper=emit(Reached(ScrollStart)),
          upper_key=id + "/upper",
          on_lower=emit(Reached(ScrollEnd)),
          lower_key=id + "/lower",
          [
            ui_container(
              "message-scroller-content",
              id=id + "-content",
              style="display:flex;flex-direction:column;min-height:100%;",
              [
                @minimoon.div(id=id + "-start", @minimoon.nothing()),
                @minimoon.keyed_fragment(messages),
                @minimoon.div(
                  id=id + "-end-" + state.token.to_string(),
                  @minimoon.nothing(),
                ),
              ],
            ),
          ],
        ),
        if show_buttons {
          message_scroll_control(
            id,
            ScrollStart,
            state.at_start,
            emit(Jump(ScrollStart)),
            render_button,
          )
        } else {
          @minimoon.nothing()
        },
        if show_buttons {
          message_scroll_control(
            id,
            ScrollEnd,
            state.at_end,
            emit(Jump(ScrollEnd)),
            render_button,
          )
        } else {
          @minimoon.nothing()
        },
      ],
    )
  })
  @minimoon.Val::view2(view, watcher, (view, watcher) => {
    @minimoon.fragment([view, watcher])
  })
}

///|
fn message_scroll_control(
  id : String,
  direction : MessageScrollDirection,
  disabled : Bool,
  command : @minimoon.Cmd,
  render : ((MessageScrollDirection, @minimoon.Cmd, Bool) -> @minimoon.Node)?,
) -> @minimoon.Node {
  let start = direction == ScrollStart
  let class = "mmui-message-scroller-" + (if start { "start" } else { "end" })
  let style = "position:absolute;" +
    (if start { "top" } else { "bottom" }) +
    ":8px;right:8px;"
  let command = if disabled { @minimoon.none } else { command }
  match render {
    Some(render) =>
      @minimoon.div(class~, style~, render(direction, command, disabled))
    None =>
      @minimoon.button(
        class~,
        style~,
        disabled~,
        on_tap=command,
        event_key=id + (if start { "/start" } else { "/end" }),
        if start {
          "Oldest messages"
        } else {
          "Latest messages"
        },
      )
  }
}
