///|
#cfg(target="js")
fn async_run(f : async () -> Unit noraise) -> Unit = "%async.run"

///|
#cfg(target="js")
pub fn effect(f : async () -> Unit noraise) -> Cmd {
  CmdEffect((_emit, finish) => {
    let continuation = Ref(Some(finish))
    async_run(async fn() noraise {
      f()
      match continuation.val {
        Some(finish) => {
          continuation.val = None
          finish()
        }
        None => ()
      }
    })
    fn() { continuation.val = None }
  })
}

///|
#cfg(not(target="js"))
pub fn effect(f : async () -> Unit noraise) -> Cmd {
  let _ = f
  CmdNone
}

///|
#cfg(target="js")
pub fn[A] perform(to_cmd : (A) -> Cmd, f : async () -> A noraise) -> Cmd {
  CmdEffect((emit, finish) => {
    let continuation = Ref(Some((to_cmd, emit, finish)))
    async_run(async fn() noraise {
      let value = f()
      match continuation.val {
        Some((to_cmd, emit, finish)) => {
          continuation.val = None
          emit(to_cmd(value))
          finish()
        }
        None => ()
      }
    })
    fn() { continuation.val = None }
  })
}

///|
#cfg(not(target="js"))
pub fn[A] perform(to_cmd : (A) -> Cmd, f : async () -> A noraise) -> Cmd {
  let _ = (to_cmd, f)
  CmdNone
}

///|
#cfg(target="js")
pub fn[A, E : Error] attempt(
  to_cmd : (Result[A, E]) -> Cmd,
  f : async () -> A raise E,
) -> Cmd {
  CmdEffect((emit, finish) => {
    let continuation = Ref(Some((to_cmd, emit, finish)))
    async_run(async fn() noraise {
      let result = try f() catch {
        error => Err(error)
      } noraise {
        value => Ok(value)
      }
      match continuation.val {
        Some((to_cmd, emit, finish)) => {
          continuation.val = None
          emit(to_cmd(result))
          finish()
        }
        None => ()
      }
    })
    fn() { continuation.val = None }
  })
}

///|
#cfg(not(target="js"))
pub fn[A, E : Error] attempt(
  to_cmd : (Result[A, E]) -> Cmd,
  f : async () -> A raise E,
) -> Cmd {
  let _ = (to_cmd, f)
  CmdNone
}

///|
#cfg(target="js")
pub fn delay(command : Cmd, milliseconds : Int) -> Cmd {
  guard milliseconds >= 0 else { abort("delay must not be negative") }
  CmdHostEffect(
    "minimoon.timeout",
    "{\"ms\":" + milliseconds.to_string() + "}",
    _ => command,
  )
}

///|
#cfg(not(target="js"))
pub fn delay(command : Cmd, milliseconds : Int) -> Cmd {
  guard milliseconds >= 0 else { abort("delay must not be negative") }
  CmdEffect((emit, finish) => {
    emit(command)
    finish()
    fn() {  }
  })
}
