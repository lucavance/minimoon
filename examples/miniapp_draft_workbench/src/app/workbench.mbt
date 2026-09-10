///|
pub let storage_key : String = "minimoon-draft-workbench-v1"

///|
fn empty_draft() -> Draft {
  { title: "", note: "", }
}

///|
fn empty_store() -> Store {
  { version: 1, next_id: 1, records: [], }
}

///|
pub fn initial_workbench() -> Workbench {
  {
    store: empty_store(),
    buffer: {
      id: None,
      draft: empty_draft(),
      saved: empty_draft(),
      revision: 0,
    },
    storage: Loading,
    epoch: 1,
    pending: None,
    confirm: None,
    opening: None,
    notice: "正在读取本地草稿…",
    echo: initial_echo(),
  }
}

///|
pub fn dirty(buffer : Buffer) -> Bool {
  buffer.draft != buffer.saved
}

///|
pub fn validate(draft : Draft) -> Result[Draft, String] {
  let draft = { ..draft, title: draft.title.trim().to_owned(), }
  if draft.title == "" {
    Err("标题不能为空。")
  } else if draft.title.iter().count() > 80 {
    Err("标题最多 80 个字符。")
  } else if draft.note.iter().count() > 2000 {
    Err("正文最多 2000 个字符。")
  } else {
    Ok(draft)
  }
}

///|
fn decode_store(data : Json) -> Result[Store, String] {
  let store : Store = @json.from_json(data) catch {
    _ => return Err("本地数据格式错误，未覆盖原数据。")
  }
  guard store.version == 1 && store.next_id > 0 && store.records.length() <= 50 else {
    return Err(
      "本地数据版本或容量不受支持，未覆盖原数据。",
    )
  }
  let ids : Map[Int, Bool] = Map([])
  for record in store.records {
    guard record.id > 0 && record.id < store.next_id && !ids.contains(record.id) else {
      return Err("草稿标识损坏，未覆盖原数据。")
    }
    guard validate(record.draft) is Ok(normalized) && normalized == record.draft else {
      return Err("草稿内容损坏，未覆盖原数据。")
    }
    ids[record.id] = true
  }
  Ok(store)
}

///|
fn write_store(
  current : Workbench,
  store : Store,
  intent : Intent?,
  saved_id : Int?,
  emit : @minimoon.Emit[WorkMsg],
) -> (Workbench, @minimoon.Cmd) {
  let token = current.epoch + 1
  let pending = { token, store, intent, buffer: current.buffer, saved_id, }
  @minimoon.with_cmd(
    {
      ..current,
      storage: Writing,
      epoch: token,
      pending: Some(pending),
      confirm: None,
      notice: "正在写入本地…",
    },
    @minimoon.set_storage(
      storage_key,
      store.to_json(),
      emit.map(result => Written(token, result)),
    ),
  )
}

///|
fn choose_now(
  current : Workbench,
  intent : Intent,
  emit : @minimoon.Emit[WorkMsg],
) -> (Workbench, @minimoon.Cmd) {
  match intent {
    New | Open(_) => {
      let (id, draft) = match intent {
        Open(id) =>
          match current.store.records.filter(record => record.id == id).get(0) {
            Some(record) => (Some(id), record.draft)
            None =>
              return @minimoon.no_cmd({
                ..current,
                confirm: None,
                notice: "草稿不存在或已删除。",
              })
          }
        _ => (None, empty_draft())
      }
      @minimoon.no_cmd({
        ..current,
        confirm: None,
        notice: "",
        buffer: {
          id,
          draft,
          saved: draft,
          revision: current.buffer.revision + 1,
        },
      })
    }
    Delete(id) =>
      write_store(
        current,
        {
          ..current.store,
          records: current.store.records.filter(record => record.id != id),
        },
        Some(intent),
        None,
        emit,
      )
    ClearAll | Initialize =>
      write_store(
        current,
        { ..current.store, version: 1, records: [], },
        Some(intent),
        None,
        emit,
      )
  }
}
