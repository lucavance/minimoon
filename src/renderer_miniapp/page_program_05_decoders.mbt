///|
pub fn[Msg] Events::change_bool(
  self : Events[Msg],
  key : String,
  to_msg : (Bool) -> Msg,
) -> PageEvent[Msg] {
  self.custom(key, Change, payload => {
    match event_detail(payload) {
      Ok(detail) =>
        match detail.get("value") {
          Some(True) => Ok(to_msg(true))
          Some(False) => Ok(to_msg(false))
          _ => Err(decode_error("event detail.value must be a boolean"))
        }
      Err(error) => Err(error)
    }
  })
}

///|
pub fn[Msg] Events::change_string(
  self : Events[Msg],
  key : String,
  to_msg : (String) -> Msg,
) -> PageEvent[Msg] {
  self.custom(key, Change, payload => {
    match event_detail(payload) {
      Ok(detail) =>
        match detail.get("value") {
          Some(String(value)) => Ok(to_msg(value))
          _ => Err(decode_error("event detail.value must be a string"))
        }
      Err(error) => Err(error)
    }
  })
}

///|
pub fn[Msg] Events::change_strings(
  self : Events[Msg],
  key : String,
  to_msg : (Array[String]) -> Msg,
) -> PageEvent[Msg] {
  self.custom(key, Change, payload => {
    match event_detail(payload) {
      Ok(detail) =>
        match detail.get("value") {
          Some(Array(values)) => {
            let output : Array[String] = []
            for value in values {
              match value {
                String(item) => output.push(item)
                _ =>
                  return Err(
                    decode_error("event detail.value must contain strings"),
                  )
              }
            }
            Ok(to_msg(output))
          }
          _ => Err(decode_error("event detail.value must be an array"))
        }
      Err(error) => Err(error)
    }
  })
}

///|
pub fn[Msg] Events::change_index(
  self : Events[Msg],
  key : String,
  to_msg : (Int) -> Msg,
) -> PageEvent[Msg] {
  self.custom(key, Change, payload => {
    match event_detail(payload) {
      Ok(detail) =>
        match detail.get("value") {
          Some(String(value)) =>
            match decimal_index(value) {
              Some(index) => Ok(to_msg(index))
              None => Err(decode_error("event detail.value must be an index"))
            }
          Some(Number(value, ..)) =>
            match event_int32(value) {
              Some(index) => Ok(to_msg(index))
              None => Err(decode_error("event detail.value must be an index"))
            }
          _ => Err(decode_error("event detail.value must be an index"))
        }
      Err(error) => Err(error)
    }
  })
}

///|
pub fn[Msg] Events::change_current(
  self : Events[Msg],
  key : String,
  to_msg : (Int) -> Msg,
) -> PageEvent[Msg] {
  self.custom(key, Change, payload => {
    match event_detail(payload) {
      Ok(detail) =>
        match detail.get("current") {
          Some(Number(current, ..)) =>
            match event_int32(current) {
              Some(index) => Ok(to_msg(index))
              None =>
                Err(
                  decode_error(
                    "event detail.current must be a non-negative index",
                  ),
                )
            }
          _ =>
            Err(
              decode_error("event detail.current must be a non-negative index"),
            )
        }
      Err(error) => Err(error)
    }
  })
}

///|
fn decimal_index(value : String) -> Int? {
  if value == "" {
    return None
  }
  let result = Ref(0)
  for ch in value.iter() {
    if ch < '0' || ch > '9' {
      return None
    }
    let digit = ch.to_int() - '0'.to_int()
    if result.val > (2147483647 - digit) / 10 {
      return None
    }
    result.val = result.val * 10 + digit
  }
  Some(result.val)
}

///|
pub fn[Msg] Events::scroll(
  self : Events[Msg],
  key : String,
  to_msg : (MiniappScrollDetail) -> Msg,
) -> PageEvent[Msg] {
  self.custom(key, page_event_kind("scroll"), payload => {
    match event_detail(payload) {
      Ok(detail) => {
        let scroll_left = match detail_number(detail, "scrollLeft") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let scroll_top = match detail_number(detail, "scrollTop") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let scroll_height = match detail_number(detail, "scrollHeight") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let scroll_width = match detail_number(detail, "scrollWidth") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let delta_x = match detail_number(detail, "deltaX") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        let delta_y = match detail_number(detail, "deltaY") {
          Ok(value) => value
          Err(error) => return Err(error)
        }
        Ok(
          to_msg({
            scroll_left,
            scroll_top,
            scroll_height,
            scroll_width,
            delta_x,
            delta_y,
          }),
        )
      }
      Err(error) => Err(error)
    }
  })
}

///|
pub fn[ParentMsg, ChildMsg] Events::include_scoped(
  self : Events[ParentMsg],
  scope : String,
  child : Events[ChildMsg],
  lift : (ChildMsg) -> ParentMsg,
) -> Unit {
  if scope == "" {
    self.issues.val.push("component event scope must not be empty")
    return
  }
  if scope.contains("/") {
    self.issues.val.push("component event scope must not contain '/': " + scope)
    return
  }
  if self.scope_keys.val.contains(scope) {
    self.issues.val.push("duplicate component event scope: " + scope)
    return
  }
  self.scopes.val.push(scope)
  self.scope_keys.val.add(scope)
  for event in child.entries() {
    let child_event = event
    let scoped = page_event(
      key=scope + "/" + child_event.key,
      kind=child_event.kind,
      decode=payload => {
        match (child_event.decode)(payload) {
          Ok(msg) => Ok(lift(msg))
          Err(error) => Err(error)
        }
      },
    )
    let _ = self.register(scoped)
  }
}

///|
pub fn[ParentMsg, ChildMsg] Events::include_scoped_subscriptions(
  self : Events[ParentMsg],
  scope : String,
  child : Subscriptions[ChildMsg],
  lift : (ChildMsg) -> ParentMsg,
) -> Unit {
  for entry in child.entries {
    self.subscriptions.val.push({
      key: scope + "/" + entry.key,
      interval_ms: entry.interval_ms,
      msg: lift(entry.msg),
    })
  }
}

///|
pub fn[Msg] page_event(
  key~ : String,
  kind~ : PageEventKind,
  decode~ : (Json) -> Result[Msg, MiniappDecodeError],
) -> PageEvent[Msg] {
  guard key != "" else { abort("page event key must not be empty") }
  { key, kind, decode, }
}

///|
pub fn[Msg] tap_event(key : String, msg : Msg) -> PageEvent[Msg] {
  page_event(key~, kind=Tap, decode=_ => Ok(msg))
}

///|
pub fn[Msg] input_value_event(
  key : String,
  to_msg : (String) -> Msg,
) -> PageEvent[Msg] {
  page_event(key~, kind=Input, decode=payload => {
    match event_detail_value_checked(payload) {
      Ok(value) => Ok(to_msg(value))
      Err(error) => Err(error)
    }
  })
}

///|
fn event_detail_value_checked(
  payload : Json,
) -> Result[String, MiniappDecodeError] {
  match payload {
    Object(root) =>
      match root.get("detail") {
        Some(Object(detail)) =>
          match detail.get("value") {
            Some(String(value)) => Ok(value)
            Some(_) => Err(decode_error("event detail.value must be a string"))
            None => Err(decode_error("event detail.value is missing"))
          }
        Some(_) => Err(decode_error("event detail must be an object"))
        None => Err(decode_error("event detail is missing"))
      }
    _ => Err(decode_error("event payload must be an object"))
  }
}

///|
pub fn event_detail_value(payload : Json) -> String {
  match payload {
    Object(root) =>
      match root.get("detail") {
        Some(Object(detail)) =>
          match detail.get("value") {
            Some(String(value)) => value
            Some(value) => value.stringify()
            None => ""
          }
        _ => ""
      }
    _ => ""
  }
}

///|
pub fn[Msg] PageEvent::key(self : PageEvent[Msg]) -> String {
  self.key
}

///|
pub fn[Msg] PageEvent::kind(self : PageEvent[Msg]) -> PageEventKind {
  self.kind
}

///|
pub fn[Msg] PageEvent::decode(
  self : PageEvent[Msg],
  payload : Json,
) -> Result[Msg, MiniappDecodeError] {
  (self.decode)(payload)
}

///|
pub struct PageInput[Msg] {
  name : String
  decode : (String) -> Result[Msg, MiniappDecodeError]
}

///|
pub fn[Msg] page_input(
  name : String,
  decode : (String) -> Result[Msg, MiniappDecodeError],
) -> PageInput[Msg] {
  guard name != "" else { abort("page input name must not be empty") }
  { name, decode, }
}
