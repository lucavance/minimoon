///|
#cfg(target="js")
extern "js" fn capture_shared_wake() -> () -> Unit =
  #|() => typeof globalThis.__minimoonSharedWakeV12 === "function" ? globalThis.__minimoonSharedWakeV12 : () => {}

///|
#cfg(not(target="js"))
fn capture_shared_wake() -> () -> Unit {
  fn() { () }
}

///|
/// Synchronize committed application values through the page transaction.
pub fn PageRuntime::refresh(self : PageRuntime) -> String {
  if self.entry_error() is Some(error) {
    return error
  }
  self.0.refresh()
}
