// Derived from moonbit-community/rabbita b6cbf52, Apache-2.0.
// Kept private to Minimoon's generational state-message runtime.

///|
pub type Any

///|
priv struct Wrapper[T] {
  value : T
}

///|
pub fn[T] erase(value : T) -> Any {
  unsafe_erase({ value, })
}

///|
pub fn[T] Any::into(self : Any) -> T {
  unsafe_downcast(self).value
}

///|
fn[T] unsafe_downcast(value : Any) -> Wrapper[T] = "%identity"

///|
fn[T] unsafe_erase(value : Wrapper[T]) -> Any = "%identity"
