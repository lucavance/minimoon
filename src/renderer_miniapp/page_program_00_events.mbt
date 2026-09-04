///|
/// A host capability used by a page. Declaring capabilities on the page keeps
/// generated bridge code auditable and lets verification reject undeclared
/// `wx.*` calls.
pub enum MiniappCapability {
  Login
  GetStorage
  SetStorage
  Request
  ShowToast
  GetLocation
  ChooseMedia
  RequestPayment
  NavigateTo
  RedirectTo
  NavigateBack
  Custom(String)
} derive(Eq)

///|
pub fn miniapp_capability(name : String) -> MiniappCapability {
  match name {
    "wx.login" => Login
    "wx.getStorage" => GetStorage
    "wx.setStorage" => SetStorage
    "wx.request" => Request
    "wx.showToast" => ShowToast
    "wx.getLocation" => GetLocation
    "wx.chooseMedia" => ChooseMedia
    "wx.requestPayment" => RequestPayment
    "wx.navigateTo" => NavigateTo
    "wx.redirectTo" => RedirectTo
    "wx.navigateBack" => NavigateBack
    name => Custom(name)
  }
}

///|
pub fn MiniappCapability::name(self : MiniappCapability) -> String {
  match self {
    Login => "wx.login"
    GetStorage => "wx.getStorage"
    SetStorage => "wx.setStorage"
    Request => "wx.request"
    ShowToast => "wx.showToast"
    GetLocation => "wx.getLocation"
    ChooseMedia => "wx.chooseMedia"
    RequestPayment => "wx.requestPayment"
    NavigateTo => "wx.navigateTo"
    RedirectTo => "wx.redirectTo"
    NavigateBack => "wx.navigateBack"
    Custom(name) => name
  }
}

///|
pub enum PageEventKind {
  Tap
  Input
  Change
  Confirm
  Focus
  Blur
  Submit
  CustomEvent(String)
} derive(Eq)

///|
/// A decoding failure at the MiniApp host boundary. Decoders run before an
/// application message is dispatched, so a failure never commits Model or Cmd.
pub struct MiniappDecodeError {
  message : String
}

///|
pub fn decode_error(message : String) -> MiniappDecodeError {
  guard message != "" else { abort("MiniApp decode error must not be empty") }
  { message, }
}

///|
pub fn MiniappDecodeError::message(self : MiniappDecodeError) -> String {
  self.message
}

///|
pub fn page_event_kind(name : String) -> PageEventKind {
  match name {
    "tap" => Tap
    "input" => Input
    "change" => Change
    "confirm" => Confirm
    "focus" => Focus
    "blur" => Blur
    "submit" => Submit
    name => CustomEvent(name)
  }
}

///|
pub fn PageEventKind::host_name(self : PageEventKind) -> String {
  match self {
    Tap => "tap"
    Input => "input"
    Change => "change"
    Confirm => "confirm"
    Focus => "focus"
    Blur => "blur"
    Submit => "submit"
    CustomEvent(name) => name
  }
}

///|
/// A page event owns the host-payload decoder. Application messages therefore
/// stay typed and never need to inspect a JavaScript event object.
pub struct PageEvent[Msg] {
  key : String
  kind : PageEventKind
  decode : (Json) -> Result[Msg, MiniappDecodeError]
}

///|
pub struct HostSubscription[Msg] {
  key : String
  interval_ms : Int
  msg : Msg
}

///|
pub struct Subscriptions[Msg] {
  entries : Array[HostSubscription[Msg]]
}

///|
pub fn[Msg] no_subscriptions() -> Subscriptions[Msg] {
  { entries: [], }
}

///|
pub fn[Msg] every(
  key~ : String,
  interval_ms~ : Int,
  msg~ : Msg,
) -> HostSubscription[Msg] {
  guard key != "" else { abort("subscription key must not be empty") }
  guard interval_ms > 0 else { abort("subscription interval must be positive") }
  { key, interval_ms, msg, }
}

///|
pub fn[Msg] subscriptions(
  entries : Array[HostSubscription[Msg]],
) -> Subscriptions[Msg] {
  { entries, }
}

///|
/// A render-scoped event registry. A fresh registry is created for every
/// candidate view, so dynamic branches expose only the handlers that are
/// present in the candidate tree.
pub struct Events[Msg] {
  owner_id : Int
  entries : Ref[Array[PageEvent[Msg]]]
  entry_keys : Ref[Set[String]]
  entry_index : Ref[Map[String, PageEvent[Msg]]]
  scopes : Ref[Array[String]]
  scope_keys : Ref[Set[String]]
  issues : Ref[Array[String]]
  subscriptions : Ref[Array[HostSubscription[Msg]]]
  scope_cleanups : Ref[Map[String, () -> Unit]]
  candidate_commits : Ref[Array[() -> Unit]]
  candidate_rollbacks : Ref[Array[() -> Unit]]
}

///|
pub fn[Msg] events() -> Events[Msg] {
  events_for_owner(0)
}

///|
/// Internal component renders inherit the owning PageProgram instance.
pub fn[Msg] events_for_owner(owner_id : Int) -> Events[Msg] {
  {
    owner_id,
    entries: Ref([]),
    entry_keys: Ref(Set([])),
    entry_index: Ref(Map([])),
    scopes: Ref([]),
    scope_keys: Ref(Set([])),
    issues: Ref([]),
    subscriptions: Ref([]),
    scope_cleanups: Ref(Map([])),
    candidate_commits: Ref([]),
    candidate_rollbacks: Ref([]),
  }
}

///|
pub fn[Msg] Events::owner_id(self : Events[Msg]) -> Int {
  self.owner_id
}

///|
pub fn[Msg] Events::reject(self : Events[Msg], message : String) -> Unit {
  self.issues.val.push(message)
}

///|
/// Cache writes are committed only after the complete candidate is valid.
pub fn[Msg] Events::on_candidate_commit(
  self : Events[Msg],
  commit : () -> Unit,
) -> Unit {
  if self.owner_id == 0 {
    commit()
  } else {
    self.candidate_commits.val.push(commit)
  }
}

///|
/// Candidate-local mutations are reverted if normalization or projection fails.
pub fn[Msg] Events::on_candidate_rollback(
  self : Events[Msg],
  rollback : () -> Unit,
) -> Unit {
  self.candidate_rollbacks.val.push(rollback)
}

///|
pub fn[Msg] Events::on_scope_cleanup(
  self : Events[Msg],
  scope : String,
  cleanup : () -> Unit,
) -> Unit {
  self.scope_cleanups.val[scope] = cleanup
}

///|
fn[Msg] Events::cleanups(self : Events[Msg]) -> Map[String, () -> Unit] {
  self.scope_cleanups.val
}

///|
fn[Msg] Events::commits(self : Events[Msg]) -> Array[() -> Unit] {
  self.candidate_commits.val.copy()
}

///|
fn[Msg] Events::rollback(self : Events[Msg]) -> Unit {
  for rollback in self.candidate_rollbacks.val.rev() {
    rollback()
  }
}

///|
fn[Msg] Events::validation_error(self : Events[Msg]) -> String? {
  self.issues.val.get(0)
}

///|
fn[Msg] Events::subscription_entries(
  self : Events[Msg],
) -> Array[HostSubscription[Msg]] {
  self.subscriptions.val.copy()
}

///|
pub fn[Msg] Events::entries(self : Events[Msg]) -> Array[PageEvent[Msg]] {
  self.entries.val.copy()
}

///|
fn[Msg] Events::event_index(self : Events[Msg]) -> Map[String, PageEvent[Msg]] {
  self.entry_index.val
}

///|
fn[Msg] Events::register(
  self : Events[Msg],
  event : PageEvent[Msg],
) -> PageEvent[Msg] {
  if self.entry_keys.val.contains(event.key) {
    self.issues.val.push("duplicate page event key: " + event.key)
  } else {
    self.entry_keys.val.add(event.key)
    self.entry_index.val[event.key] = event
  }
  self.entries.val.push(event)
  event
}

///|
pub fn[Msg] Events::tap(
  self : Events[Msg],
  key : String,
  msg : Msg,
) -> PageEvent[Msg] {
  self.register(tap_event(key, msg))
}

///|
pub fn[Msg] Events::input_value(
  self : Events[Msg],
  key : String,
  to_msg : (String) -> Msg,
) -> PageEvent[Msg] {
  self.register(input_value_event(key, to_msg))
}

///|
pub fn[Msg] Events::custom(
  self : Events[Msg],
  key : String,
  kind : PageEventKind,
  decode : (Json) -> Result[Msg, MiniappDecodeError],
) -> PageEvent[Msg] {
  self.register(page_event(key~, kind~, decode~))
}

///|
pub struct MiniappScrollDetail {
  scroll_left : Double
  scroll_top : Double
  scroll_height : Double
  scroll_width : Double
  delta_x : Double
  delta_y : Double
}

///|
fn event_detail(
  payload : Json,
) -> Result[Map[String, Json], MiniappDecodeError] {
  match payload {
    Object(root) =>
      match root.get("detail") {
        Some(Object(detail)) => Ok(detail)
        Some(_) => Err(decode_error("event detail must be an object"))
        None => Err(decode_error("event detail is missing"))
      }
    _ => Err(decode_error("event payload must be an object"))
  }
}

///|
fn event_int32(value : Double) -> Int? {
  if value < 0.0 || value > 2147483647.0 {
    return None
  }
  let integer = value.to_int()
  if integer.to_double() == value {
    Some(integer)
  } else {
    None
  }
}

///|
fn detail_number(
  detail : Map[String, Json],
  name : String,
) -> Result[Double, MiniappDecodeError] {
  match detail.get(name) {
    Some(Number(value, ..)) => Ok(value)
    _ => Err(decode_error("event detail." + name + " must be a number"))
  }
}
