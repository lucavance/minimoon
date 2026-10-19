///|
priv suberror QueryDemoError {
  QueryDemoError
}

///|
fn query_panel(
  load : (
    String,
    Int32?,
    @minimoon.Emit[Result[@query.QueryPage[String, Int32], Error]],
  ) -> @minimoon.Cmd,
  fail_next : @minimoon.Cmd,
) -> @minimoon.Val[@minimoon.Node] {
  let (draft, edit) = @minimoon.create_variable("")
  let (state, emit) = @query.create_infinite_query("", load)
  draft.view2(state, (draft, state) => {
    let status = match state.phase {
      Loading => "正在加载…"
      Refreshing => "正在刷新，保留已有内容…"
      LoadingMore => "正在加载更多…"
      Idle =>
        if state.error is Some(_) {
          "本次请求失败，已有内容已保留，请重试。"
        } else if state.items.is_empty() {
          "没有匹配的草稿"
        } else if state.has_more {
          "已加载 " + state.items.length().to_string() + " 条"
        } else {
          "已加载全部 " + state.items.length().to_string() + " 条"
        }
    }
    @minimoon.div([
      @minimoon.input(
        id="query-search",
        value=draft,
        placeholder="搜索草稿；输入 慢速 测试延迟响应",
        on_input=edit.map(value => _ => value),
        on_confirm=value => {
          @minimoon.batch([
            edit(_ => value),
            emit(@query.SetQuery(value.trim().to_owned())),
          ])
        },
      ),
      @minimoon.button(
        id="query-submit",
        on_tap=emit(@query.SetQuery(draft.trim().to_owned())),
        "搜索",
      ),
      @minimoon.button(
        id="query-refresh",
        on_tap=emit(@query.Refresh),
        "刷新",
      ),
      @minimoon.button(
        id="query-fail",
        on_tap=fail_next,
        "下一次响应失败",
      ),
      @minimoon.p(id="query-status", status),
      @minimoon.div(
        id="query-results",
        state.items.to_array().map(item => @minimoon.p(item)),
      ),
      @minimoon.button(
        id="query-more",
        disabled=!state.can_load_more,
        on_tap=emit(@query.LoadMore),
        "加载更多",
      ),
      if state.error is Some(_) {
        @minimoon.button(id="query-retry", on_tap=emit(@query.Retry), "重试")
      } else {
        @minimoon.nothing()
      },
    ])
  })
}

///|
fn query_probe() -> @minimoon.Val[@minimoon.Node] {
  let (visible, toggle) = @minimoon.create_variable(true)
  let child = visible.switch_by(
    (show, _) => {
      if !show {
        return @minimoon.Val::constant(@minimoon.p("查询已关闭"))
      }
      // This flag belongs to the simulated service. Only committed commands
      // consume it; it never controls the query's request identity or state.
      let fail = Ref(false)
      query_panel(
        (query, cursor, done) => {
          @minimoon.delay(
            @minimoon.perform(done, fn() noraise {
              if fail.val {
                fail.val = false
                return Err(QueryDemoError)
              }
              let all = Array::makei(23, index => {
                "草稿 " + (index + 1).to_string()
              })
              let rows = all.filter(item => {
                query == "慢速" || item.contains(query)
              })
              let start = cursor.unwrap_or(0)
              let end = (start + 5).min(rows.length())
              Ok({
                items: rows[start:end]
                .to_owned()
                .map(item => {
                  if query == "慢速" {
                    "慢速 · " + item
                  } else {
                    item
                  }
                }),
                next_cursor: if end < rows.length() {
                  Some(end)
                } else {
                  None
                },
              })
            }),
            if query == "慢速" {
              1800
            } else {
              300
            },
          )
        },
        @minimoon.effect(fn() noraise { fail.val = true }),
      )
    },
    by=show => show.to_string(),
  )
  visible.view2(child, (visible, child) => {
    @shell.card("列表查询（本地模拟）", section="query-probe", [
      @minimoon.p(
        "23 条草稿，每次加载 5 条；确认后搜索。关闭查询会释放局部状态。",
      ),
      @minimoon.button(
        id="query-toggle",
        on_tap=toggle(show => !show),
        if visible {
          "关闭查询"
        } else {
          "重新打开查询"
        },
      ),
      child,
    ])
  })
}
