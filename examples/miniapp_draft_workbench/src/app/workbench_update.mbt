///|
pub fn update_workbench(
  current : Workbench,
  message : WorkMsg,
  emit : @minimoon.Emit[WorkMsg],
) -> (Workbench, @minimoon.Cmd) {
  match message {
    Reload => {
      if current.storage != ReadFailed {
        return @minimoon.no_cmd(current)
      }
      let token = current.epoch + 1
      @minimoon.with_cmd(
        {
          ..current,
          epoch: token,
          storage: Loading,
          confirm: None,
          notice: "正在重新读取…",
        },
        @minimoon.get_storage(
          storage_key,
          emit.map(result => Restored(token, result)),
        ),
      )
    }
    Restored(token, result) => {
      if current.epoch != token || current.storage != Loading {
        return @minimoon.no_cmd(current)
      }
      let decoded = match result {
        Ok(value) => decode_store(value.data)
        // Fail closed for unknown host errors; only this explicit missing-key result is empty.
        Err(error) if error.message == "getStorage:fail data not found" =>
          Ok(empty_store())
        Err(_) =>
          Err(
            "未能读取本地草稿。已有数据请先重试；首次使用可确认初始化。",
          )
      }
      match decoded {
        Ok(store) => {
          let next = {
            ..current,
            store,
            storage: Ready,
            opening: None,
            notice: "本地草稿已就绪。",
          }
          match current.opening {
            Some(intent) => update_workbench(next, Choose(intent), emit)
            None => @minimoon.no_cmd(next)
          }
        }
        Err(notice) =>
          @minimoon.no_cmd({ ..current, storage: ReadFailed, notice, })
      }
    }
    Title(title) =>
      @minimoon.no_cmd({
        ..current,
        confirm: None,
        notice: "",
        buffer: {
          ..current.buffer,
          draft: { ..current.buffer.draft, title, },
          revision: current.buffer.revision + 1,
        },
      })
    Note(note) =>
      @minimoon.no_cmd({
        ..current,
        confirm: None,
        notice: "",
        buffer: {
          ..current.buffer,
          draft: { ..current.buffer.draft, note, },
          revision: current.buffer.revision + 1,
        },
      })
    Choose(intent) => {
      if current.storage == Loading && intent is (New | Open(_)) {
        return @minimoon.no_cmd({ ..current, opening: Some(intent), })
      }
      if current.storage != Ready &&
        !(current.storage == ReadFailed && intent == Initialize) {
        return @minimoon.no_cmd(current)
      }
      if intent is Open(id) && current.buffer.id == Some(id) {
        return @minimoon.no_cmd(current)
      }
      if intent is (Delete(_) | ClearAll | Initialize) || dirty(current.buffer) {
        @minimoon.no_cmd({ ..current, confirm: Some(intent), })
      } else {
        choose_now(current, intent, emit)
      }
    }
    Confirm =>
      match current.confirm {
        Some(intent) if current.storage == Ready ||
          (current.storage == ReadFailed && intent == Initialize) =>
          choose_now(current, intent, emit)
        _ => @minimoon.no_cmd(current)
      }
    Cancel => @minimoon.no_cmd({ ..current, confirm: None, })
    Save => {
      if current.storage != Ready {
        return @minimoon.no_cmd(current)
      }
      let draft = match validate(current.buffer.draft) {
        Ok(draft) => draft
        Err(notice) => return @minimoon.no_cmd({ ..current, notice, })
      }
      if current.buffer.id is None && current.store.records.length() >= 50 {
        return @minimoon.no_cmd({
          ..current,
          notice: "最多保存 50 条，请先删除不需要的草稿。",
        })
      }
      if current.buffer.id is None && current.store.next_id == 2147483647 {
        return @minimoon.no_cmd({
          ..current,
          notice: "标识空间已满，无法保存。",
        })
      }
      let id = current.buffer.id.unwrap_or(current.store.next_id)
      let store = {
        ..current.store,
        next_id: if current.buffer.id is None {
          id + 1
        } else {
          current.store.next_id
        },
        records: [
          { id, draft, },
          ..current.store.records.filter(record => record.id != id),
        ],
      }
      write_store(current, store, None, Some(id), emit)
    }
    Written(token, result) => {
      guard current.pending is Some(pending) &&
        pending.token == token &&
        current.storage == Writing else {
        return @minimoon.no_cmd(current)
      }
      match result {
        Err(_) =>
          @minimoon.no_cmd({
            ..current,
            storage: if pending.intent == Some(Initialize) {
              ReadFailed
            } else {
              Ready
            },
            pending: None,
            notice: "本地写入失败，未确认保存或删除。内容已保留，请重试。",
          })
        Ok(_) => {
          let buffer = match pending.saved_id {
            Some(id) => {
              let saved = pending.store.records[0].draft
              {
                ..current.buffer,
                id: Some(id),
                saved,
                draft: if current.buffer.revision == pending.buffer.revision {
                  saved
                } else {
                  current.buffer.draft
                },
              }
            }
            None =>
              if pending.intent is Some(ClearAll | Initialize) ||
                (
                  pending.intent is Some(Delete(id)) &&
                  current.buffer.id == Some(id)
                ) {
                {
                  id: None,
                  draft: if current.buffer.revision == pending.buffer.revision {
                    empty_draft()
                  } else {
                    current.buffer.draft
                  },
                  saved: empty_draft(),
                  revision: current.buffer.revision + 1,
                }
              } else {
                current.buffer
              }
          }
          @minimoon.no_cmd({
            ..current,
            store: pending.store,
            buffer,
            echo: if buffer.revision != current.buffer.revision {
              {
                ..current.echo,
                revision: -1,
                submitted: empty_draft(),
                status: if current.echo.status == EchoLoading {
                  EchoLoading
                } else {
                  EchoIdle
                },
              }
            } else {
              current.echo
            },
            pending: None,
            opening: None,
            storage: Ready,
            notice: "本地写入成功。",
          })
        }
      }
    }
    Send => {
      if current.echo.status == EchoLoading {
        return @minimoon.no_cmd(current)
      }
      let draft = match validate(current.buffer.draft) {
        Ok(draft) => draft
        Err(notice) => return @minimoon.no_cmd({ ..current, notice, })
      }
      let token = current.echo.token + 1
      let echo = {
        token,
        revision: current.buffer.revision,
        submitted: draft,
        status: EchoLoading,
      }
      @minimoon.with_cmd(
        { ..current, echo, notice: "", },
        echo_request(draft, emit.map(result => EchoFinished(token, result))),
      )
    }
    EchoFinished(token, result) =>
      @minimoon.no_cmd({
        ..current,
        echo: finish_echo(current.echo, token, current.buffer.revision, result),
      })
  }
}
