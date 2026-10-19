///|
priv struct Model[Q, T, Cursor] {
  state : QueryState[Q, T]
  cursor : Cursor?
  active : Ref[Unit]?
  failed : QueryPhase
  revision : Ref[Unit]
}

///|
impl[Q, T, Cursor] Eq for Model[Q, T, Cursor] with fn equal(a, b) {
  physical_equal(a.revision, b.revision)
}

///|
priv enum Message[Q, T, Cursor] {
  Action(QueryAction[Q])
  Completed(Ref[Unit], Result[(@vector.Vector[T], Cursor?), Error])
}

///|
fn[Q, T, Cursor] start(
  model : Model[Q, T, Cursor],
  phase : QueryPhase,
  emit : @minimoon.Emit[Message[Q, T, Cursor]],
  load : (Q, Cursor?, @minimoon.Emit[Result[QueryPage[T, Cursor], Error]]) -> @minimoon.Cmd,
) -> (Model[Q, T, Cursor], @minimoon.Cmd) {
  // Immutable identity keeps request acceptance transactional.
  let token = Ref(())
  let next = {
    ..model,
    state: { ..model.state, phase, can_load_more: false, error: None, },
    active: Some(token),
    failed: Idle,
    revision: token,
  }
  let cursor = if phase == LoadingMore { model.cursor } else { None }
  let done = emit.map((result : Result[QueryPage[T, Cursor], Error]) => {
    Completed(
      token,
      match result {
        Ok(page) => Ok((@vector.from_array(page.items), page.next_cursor))
        Err(error) => Err(error)
      },
    )
  })
  (next, load(next.state.query, cursor, done))
}

///|
fn[Q : Eq, T, Cursor] update(
  model : Model[Q, T, Cursor],
  message : Message[Q, T, Cursor],
  emit : @minimoon.Emit[Message[Q, T, Cursor]],
  load : (Q, Cursor?, @minimoon.Emit[Result[QueryPage[T, Cursor], Error]]) -> @minimoon.Cmd,
) -> (Model[Q, T, Cursor], @minimoon.Cmd) {
  match message {
    Action(SetQuery(query)) => {
      if query == model.state.query {
        return @minimoon.no_cmd(model)
      }
      start(
        {
          ..model,
          state: {
            ..model.state,
            query,
            items: @vector.new(),
            has_loaded: false,
            has_more: false,
          },
          cursor: None,
        },
        Loading,
        emit,
        load,
      )
    }
    Action(Refresh) => {
      if model.state.phase == Loading || model.state.phase == Refreshing {
        return @minimoon.no_cmd(model)
      }
      start(
        model,
        if model.state.has_loaded {
          Refreshing
        } else {
          Loading
        },
        emit,
        load,
      )
    }
    Action(LoadMore) => {
      if !model.state.can_load_more {
        return @minimoon.no_cmd(model)
      }
      start(model, LoadingMore, emit, load)
    }
    Action(Retry) => {
      if model.failed == Idle || model.active is Some(_) {
        return @minimoon.no_cmd(model)
      }
      start(model, model.failed, emit, load)
    }
    Completed(token, result) => {
      guard model.active is Some(active) && physical_equal(active, token) else {
        return @minimoon.no_cmd(model)
      }
      let (state, cursor, failed) = match result {
        Ok((items, cursor)) => {
          let items = if model.state.phase == LoadingMore {
            items.fold(init=model.state.items, (rows, item) => rows.push(item))
          } else {
            items
          }
          (
            {
              ..model.state,
              items,
              phase: Idle,
              has_loaded: true,
              has_more: cursor is Some(_),
              can_load_more: cursor is Some(_),
              error: None,
            },
            cursor,
            Idle,
          )
        }
        Err(error) =>
          (
            {
              ..model.state,
              phase: Idle,
              can_load_more: model.state.phase == LoadingMore,
              error: Some(error),
            },
            model.cursor,
            model.state.phase,
          )
      }
      @minimoon.no_cmd({
        state,
        cursor,
        failed,
        active: None,
        revision: Ref(()),
      })
    }
  }
}

///|
/// Creates a scope-owned query. The loader returns a commit-gated Cmd.
/// Refresh retains rows; SetQuery clears them. Stale completions are ignored.
///
/// ```moonbit nocheck
/// let (state, emit) = @query.create_infinite_query("", (query, _cursor : Int?, done) => {
///   done(Ok({ items: [query], next_cursor: None }))
/// })
/// state.view(state => @minimoon.button(on_tap=emit(@query.Refresh), state.query))
/// ```
pub fn[Q : Eq, T, Cursor] create_infinite_query(
  initial_query : Q,
  load : (Q, Cursor?, @minimoon.Emit[Result[QueryPage[T, Cursor], Error]]) -> @minimoon.Cmd,
) -> (@minimoon.Val[QueryState[Q, T]], @minimoon.Emit[QueryAction[Q]]) {
  let (model, emit) = @minimoon.create_state_with_init(
    init=emit => {
      start(
        {
          state: {
            query: initial_query,
            items: @vector.new(),
            phase: Idle,
            has_loaded: false,
            has_more: false,
            can_load_more: false,
            error: None,
          },
          cursor: None,
          active: None,
          failed: Idle,
          revision: Ref(()),
        },
        Loading,
        emit,
        load,
      )
    },
    update=(model, message, emit) => update(model, message, emit, load),
  )
  (model.map(model => model.state), emit.map(action => Action(action)))
}
