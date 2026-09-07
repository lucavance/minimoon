///|
pub(all) enum ToastVariant {
  ToastDefault
  ToastDestructive
  ToastSuccess
} derive(Eq, Debug)

///|
pub(all) enum ToastPosition {
  ToastTopLeft
  ToastTopCenter
  ToastTopRight
  ToastBottomLeft
  ToastBottomCenter
  ToastBottomRight
} derive(Eq, Debug)

///|
struct Toast {
  id : String
  title : String
  description : String
  duration_ms : Int
  variant : ToastVariant
  action_label : String
  action : @minimoon.Cmd
  on_close : @minimoon.Cmd
  stamp : @minimoon.Node
}

///|
pub impl Eq for Toast with fn equal(a, b) {
  a.stamp == b.stamp
}

///|
pub fn toast_notice(
  id~ : String,
  title~ : String,
  description? : String = "",
  duration_ms? : Int = 5000,
  variant? : ToastVariant = ToastDefault,
  action_label? : String = "",
  action? : @minimoon.Cmd = @minimoon.none,
  on_close? : @minimoon.Cmd = @minimoon.none,
) -> Toast {
  guard id != "" && duration_ms >= 0 else {
    abort("toast requires an ID and nonnegative duration")
  }
  {
    id,
    title,
    description,
    duration_ms,
    variant,
    action_label,
    action,
    on_close,
    stamp: @minimoon.nothing(),
  }
}

///|
priv struct ToastEntry {
  notice : Toast
  remaining : Int
  swipe : (Int, Double, Double, Double)?
} derive(Eq)

///|
priv enum ToastMsg {
  Push(Toast)
  Dismiss(String)
  Activate(String)
  Tick
  Clear
  SwipeStart(String, @minimoon.TouchDetail)
  SwipeMove(String, @minimoon.TouchDetail)
  SwipeEnd(String, @minimoon.TouchDetail)
  SwipeCancel(String, @minimoon.TouchDetail)
  CancelGestures
}

///|
priv struct ToastQueue {
  entries : @minimoon.Val[Array[ToastEntry]]
  emit : @minimoon.Emit[ToastMsg]
}

///|
fn create_toast_queue(
  context : @minimoon.PageContext,
  visible : @minimoon.Val[Bool],
  limit : Int,
) -> ToastQueue {
  let initial : Array[ToastEntry] = []
  let (entries, emit) = @minimoon.create_state_with_input(
    input=visible,
    init=(_, _) => (initial, @minimoon.none),
    update=(entries, visible, message, _) => {
      match message {
        Activate(id) => {
          if !visible {
            return @minimoon.no_cmd(entries)
          }
          let active = entries.filter(entry => entry.notice.id == id)
          @minimoon.with_cmds(
            entries.filter(entry => entry.notice.id != id),
            active.map(entry => {
              @minimoon.batch([entry.notice.action, entry.notice.on_close])
            }),
          )
        }
        Push(notice) => {
          let next = entries.filter(entry => entry.notice.id != notice.id)
          let removed : Array[@minimoon.Cmd] = []
          while next.length() >= limit {
            let oldest = next.remove(0)
            removed.push(oldest.notice.on_close)
          }
          next.push({ notice, remaining: notice.duration_ms, swipe: None, })
          @minimoon.with_cmds(next, removed)
        }
        Dismiss(id) =>
          @minimoon.with_cmds(
            entries.filter(entry => entry.notice.id != id),
            entries
            .filter(entry => entry.notice.id == id)
            .map(entry => entry.notice.on_close),
          )
        Tick => {
          if !visible {
            return @minimoon.no_cmd(entries)
          }
          let next : Array[ToastEntry] = []
          let commands : Array[@minimoon.Cmd] = []
          for entry in entries {
            if entry.notice.duration_ms == 0 || entry.swipe is Some(_) {
              next.push(entry)
            } else if entry.remaining <= 250 {
              commands.push(entry.notice.on_close)
            } else {
              next.push({ ..entry, remaining: entry.remaining - 250, })
            }
          }
          @minimoon.with_cmds(next, commands)
        }
        Clear =>
          @minimoon.with_cmds([], entries.map(entry => entry.notice.on_close))
        SwipeStart(id, detail) =>
          @minimoon.no_cmd(
            entries.map(entry => {
              if entry.notice.id == id &&
                entry.swipe is None &&
                detail.touches.length() == 1 {
                let point = detail.touches[0]
                {
                  ..entry,
                  swipe: Some(
                    (point.identifier, point.client_x, point.client_y, 0.0),
                  ),
                }
              } else {
                entry
              }
            }),
          )
        SwipeMove(id, detail) =>
          @minimoon.no_cmd(
            entries.map(entry => {
              if entry.notice.id == id &&
                entry.swipe is Some((identifier, x, y, _)) {
                match
                  detail.touches
                  .filter(point => point.identifier == identifier)
                  .get(0) {
                  Some(point) =>
                    {
                      ..entry,
                      swipe: Some((identifier, x, y, point.client_x - x)),
                    }
                  None => entry
                }
              } else {
                entry
              }
            }),
          )
        SwipeEnd(id, detail) => {
          let next : Array[ToastEntry] = []
          let commands : Array[@minimoon.Cmd] = []
          for entry in entries {
            if entry.notice.id == id &&
              entry.swipe is Some((identifier, x, y, _)) {
              match
                detail.changed_touches
                .filter(point => point.identifier == identifier)
                .get(0) {
                Some(point) => {
                  let dx = (point.client_x - x).abs()
                  if dx >= 64.0 && dx > (point.client_y - y).abs() {
                    commands.push(entry.notice.on_close)
                  } else {
                    next.push({ ..entry, swipe: None, })
                  }
                }
                None => next.push(entry)
              }
            } else {
              next.push(entry)
            }
          }
          @minimoon.with_cmds(next, commands)
        }
        SwipeCancel(id, detail) =>
          @minimoon.no_cmd(
            entries.map(entry => {
              if entry.notice.id == id &&
                entry.swipe is Some((identifier, _, _, _)) &&
                detail.changed_touches.any(point => {
                  point.identifier == identifier
                }) {
                { ..entry, swipe: None, }
              } else {
                entry
              }
            }),
          )
        CancelGestures =>
          @minimoon.no_cmd(entries.map(entry => { ..entry, swipe: None, }))
      }
    },
    subscriptions=(entries, visible, emit) => {
      @minimoon.Sub::batch([
        context.on_unload(emit(Clear)),
        context.on_hide(emit(CancelGestures)),
        if visible && entries.any(entry => entry.notice.duration_ms > 0) {
          context.every(
            key="mmui-toast-clock",
            interval_ms=250,
            command=emit(Tick),
          )
        } else {
          @minimoon.Sub::none()
        },
      ])
    },
  )
  { entries, emit, }
}

///|
pub fn toast(context : UiContext, notice : Toast) -> @minimoon.Cmd {
  (context.toasts.emit)(Push(notice))
}

///|
pub fn dismiss_toast(context : UiContext, id : String) -> @minimoon.Cmd {
  (context.toasts.emit)(Dismiss(id))
}

///|
pub fn toaster(
  context : UiContext,
  position? : ToastPosition = ToastBottomRight,
  rich_colors? : Bool = false,
) -> @minimoon.Val[@minimoon.Node] {
  @minimoon.Val::view2(context.toasts.entries, context.visible, (
    entries,
    visible,
  ) => {
    if !visible || entries.is_empty() {
      return @minimoon.nothing()
    }
    @minimoon.layer(
      id="mmui-toast-layer",
      ui_container(
        "toaster",
        style=toast_position_style(position),
        entries.map(entry => {
          let notice = entry.notice
          @minimoon.touch_view(
            id=notice.id,
            class="mmui-toast",
            event_key="toast/" + notice.id + "/swipe",
            style=toast_variant_style(notice.variant, rich_colors) +
              (match entry.swipe {
                Some((_, _, _, delta)) =>
                  "transform:translateX(" + delta.to_string() + "px);"
                None => ""
              }),
            on_touch_start=@minimoon.Emit(detail => {
              (context.toasts.emit)(SwipeStart(notice.id, detail))
            }),
            on_touch_move=@minimoon.Emit(detail => {
              (context.toasts.emit)(SwipeMove(notice.id, detail))
            }),
            on_touch_end=@minimoon.Emit(detail => {
              (context.toasts.emit)(SwipeEnd(notice.id, detail))
            }),
            on_touch_cancel=@minimoon.Emit(detail => {
              (context.toasts.emit)(SwipeCancel(notice.id, detail))
            }),
            semantics=@minimoon.semantics(
              role=@minimoon.StatusRole,
              live="polite",
            ),
            [
              @minimoon.text(notice.title),
              @minimoon.text(notice.description),
              if notice.action_label == "" {
                @minimoon.nothing()
              } else {
                @minimoon.button(
                  event_key="toast/" + notice.id + "/action",
                  on_tap=(context.toasts.emit)(Activate(notice.id)),
                  notice.action_label,
                )
              },
              @minimoon.button(
                event_key="toast/" + notice.id + "/dismiss",
                on_tap=dismiss_toast(context, notice.id),
                "Dismiss",
              ),
            ],
          )
        }),
      ),
    )
  })
}

///|
pub fn sonner(
  context : UiContext,
  position? : ToastPosition = ToastBottomRight,
  rich_colors? : Bool = true,
) -> @minimoon.Val[@minimoon.Node] {
  toaster(context, position~, rich_colors~)
}
