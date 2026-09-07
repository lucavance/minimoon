///|
#cfg(target="js")
extern "js" fn capture_shared_wake() -> () -> Unit =
  #|() => typeof globalThis.__minimoonSharedWakeV11 === "function" ? globalThis.__minimoonSharedWakeV11 : () => {}

///|
#cfg(not(target="js"))
fn capture_shared_wake() -> () -> Unit {
  fn() { () }
}

///|
/// Synchronize committed application values through the page transaction.
pub fn PageRuntime::refresh(self : PageRuntime) -> String {
  self.0.refresh()
}
