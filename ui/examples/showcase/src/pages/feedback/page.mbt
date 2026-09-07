///|
struct Messages {
  next : Int
  oldest : Int
  rows : Array[(String, String)]
} derive(Eq)

///|
pub fn program() -> @minimoon.Page {
  @gallery.page("feedback", "消息与反馈 / Feedback — 3 components", context => {
    let initial = Messages::{
      next: 10,
      oldest: -1,
      rows: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9].map(index => {
        ("message-" + index.to_string(), "Message " + index.to_string())
      }),
    }
    let (messages, update_messages) = @minimoon.create_variable(initial)
    let (actions, update_actions) = @minimoon.create_variable(0)
    let (use_sonner, toggle_presenter) = @minimoon.create_variable(true)
    let items = messages.map(state => {
      state.rows.map(row => {
        @ui.message_item(
          key=row.0,
          content=@ui.message(@ui.message_content(@ui.typography_p(row.1))),
        )
      })
    })
    let scroller = @ui.message_scroller(
      context,
      id="feedback-messages",
      items~,
      content_revision=messages.map(state => state.next - state.oldest),
      height="240px",
    )
    let append = update_messages(state => {
      let rows = state.rows.copy()
      rows.push(
        (
          "message-" + state.next.to_string(),
          "New message " + state.next.to_string(),
        ),
      )
      { ..state, next: state.next + 1, rows, }
    })
    let prepend = update_messages(state => {
      let rows = [
        (
          "history-" + (-state.oldest).to_string(),
          "Older message " + state.oldest.to_string(),
        ),
      ]
      rows.append(state.rows)
      { ..state, oldest: state.oldest - 1, rows, }
    })
    let toast_host = @ui.toaster(context)
    let sonner_host = @ui.sonner(context)
    let presenter = @minimoon.Val::view3(use_sonner, toast_host, sonner_host, (
      sonner,
      toast,
      styled,
    ) => if sonner { styled } else { toast })
    @ui.stack([
      @gallery.sample(
        "Message Scroller",
        scroller.map(scroller => {
          @minimoon.div([
            @ui.button_group([
              @ui.button(
                on_tap=append,
                event_key="feedback/append",
                "Append message",
              ),
              @ui.button(
                on_tap=prepend,
                event_key="feedback/prepend",
                "Prepend history",
              ),
            ]),
            scroller,
          ])
        }),
      ),
      @gallery.sample(
        "Toast",
        actions.map(count => {
          @minimoon.div([
            @ui.button(
              on_tap=@ui.toast(
                context,
                @ui.toast_notice(
                  id="feedback-toast",
                  title="Saved",
                  description="Expires after five seconds of visible time",
                  action_label="Undo",
                  action=update_actions(value => value + 1),
                ),
              ),
              event_key="feedback/toast",
              "Show actionable Toast",
            ),
            @ui.typography_p("Undo actions: " + count.to_string()),
          ])
        }),
      ),
      @gallery.sample(
        "Sonner",
        @minimoon.Val::view2(use_sonner, presenter, (sonner, presenter) => {
          @minimoon.div([
            @ui.button(
              on_tap=toggle_presenter(value => !value),
              event_key="feedback/presenter",
              if sonner {
                "Switch to Toaster"
              } else {
                "Switch to Sonner"
              },
            ),
            @ui.button(
              on_tap=@ui.toast(
                context,
                @ui.toast_notice(
                  id="feedback-persistent",
                  title="Persistent notice",
                  duration_ms=0,
                  description="Close explicitly; shares the page queue",
                ),
              ),
              event_key="feedback/persistent",
              "Show persistent notice",
            ),
            presenter,
          ])
        }),
      ),
    ])
  })
}
