///|
pub fn[Msg] string_page_input(
  name : String,
  to_msg : (String) -> Msg,
) -> PageInput[Msg] {
  page_input(name, value => Ok(to_msg(value)))
}

///|
pub fn[Msg] PageInput::name(self : PageInput[Msg]) -> String {
  self.name
}

///|
pub fn[Msg] PageInput::decode(
  self : PageInput[Msg],
  value : String,
) -> Result[Msg, MiniappDecodeError] {
  (self.decode)(value)
}

///|
pub enum PageLifecycleHook {
  Load
  Show
  Hide
  Unload
  PullDownRefresh
  ReachBottom
} derive(Eq)

///|
pub fn page_lifecycle_hook(name : String) -> PageLifecycleHook {
  match name {
    "onLoad" => Load
    "onShow" => Show
    "onHide" => Hide
    "onUnload" => Unload
    "onPullDownRefresh" => PullDownRefresh
    "onReachBottom" => ReachBottom
    name => abort("unsupported page lifecycle hook: " + name)
  }
}

///|
pub fn PageLifecycleHook::host_name(self : PageLifecycleHook) -> String {
  match self {
    Load => "onLoad"
    Show => "onShow"
    Hide => "onHide"
    Unload => "onUnload"
    PullDownRefresh => "onPullDownRefresh"
    ReachBottom => "onReachBottom"
  }
}

///|
pub struct PageLifecycleEvent[Msg] {
  hook : PageLifecycleHook
  decode : (Json) -> Result[Msg, MiniappDecodeError]
}

///|
pub fn[Msg] lifecycle_event(
  hook : PageLifecycleHook,
  decode : (Json) -> Result[Msg, MiniappDecodeError],
) -> PageLifecycleEvent[Msg] {
  { hook, decode, }
}

///|
pub fn[Msg] lifecycle_message(
  hook : PageLifecycleHook,
  msg : Msg,
) -> PageLifecycleEvent[Msg] {
  lifecycle_event(hook, _ => Ok(msg))
}

///|
pub fn[Msg] PageLifecycleEvent::hook(
  self : PageLifecycleEvent[Msg],
) -> PageLifecycleHook {
  self.hook
}

///|
pub fn[Msg] PageLifecycleEvent::decode(
  self : PageLifecycleEvent[Msg],
  payload : Json,
) -> Result[Msg, MiniappDecodeError] {
  (self.decode)(payload)
}
