///|
using @vector {type Vector}

///|
struct Cmd(@val.Cmd)

///|
pub(all) struct Emit[Msg]((Msg) -> Cmd)

///|
pub fn[A, B] Emit::map(self : Emit[A], map : (B) -> A) -> Emit[B] {
  Emit(value => (self.0)(map(value)))
}

///|
pub struct DecodeError {
  message : String
}

///|
pub enum Status[T] {
  Pending
  Loaded(T)
  Failed(Error)
}

///|
pub impl[T : Eq] Eq for Status[T] with fn equal(left, right) {
  match (left, right) {
    (Pending, Pending) | (Failed(_), Failed(_)) => true
    (Loaded(a), Loaded(b)) => a == b
    _ => false
  }
}

///|
pub let none : Cmd = Cmd(@val.none)

///|
pub fn batch(commands : Array[Cmd]) -> Cmd {
  Cmd(@val.batch(commands.map(command => command.0)))
}

///|
pub fn delay(command : Cmd, milliseconds : Int) -> Cmd {
  Cmd(@val.delay(command.0, milliseconds))
}

///|
pub fn effect(f : async () -> Unit noraise) -> Cmd {
  Cmd(@val.effect(f))
}

///|
pub fn[A] perform(to_cmd : Emit[A], f : async () -> A noraise) -> Cmd {
  Cmd(@val.perform(value => to_cmd(value).0, f))
}

///|
pub fn[A, E : Error] attempt(
  to_cmd : Emit[Result[A, E]],
  f : async () -> A raise E,
) -> Cmd {
  Cmd(@val.attempt(result => to_cmd(result).0, f))
}

///|
pub fn decode_error(message : String) -> DecodeError {
  guard message != "" else { abort("decode error must not be empty") }
  { message, }
}

///|
pub fn DecodeError::message(self : DecodeError) -> String {
  self.message
}

///|
pub fn[Model] no_cmd(model : Model) -> (Model, Cmd) {
  (model, none)
}

///|
pub fn[Model] with_cmd(model : Model, command : Cmd) -> (Model, Cmd) {
  (model, command)
}

///|
pub fn[Model] with_cmds(model : Model, commands : Array[Cmd]) -> (Model, Cmd) {
  (model, batch(commands))
}

///|
struct Val[A](@val.Val[A])

///|
pub fn[A] Val::constant(value : A) -> Val[A] {
  Val(@val.Val::constant(value))
}

///|
pub fn[A : Eq, B] Val::map(self : Val[A], map : (A) -> B) -> Val[B] {
  Val(self.0.map(map))
}

///|
pub fn[A : Eq, B : Eq, C] Val::map2(
  a : Val[A],
  b : Val[B],
  map : (A, B) -> C,
) -> Val[C] {
  Val(@val.Val::map2(a.0, b.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D] Val::map3(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  map : (A, B, C) -> D,
) -> Val[D] {
  Val(@val.Val::map3(a.0, b.0, c.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E] Val::map4(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  map : (A, B, C, D) -> E,
) -> Val[E] {
  Val(@val.Val::map4(a.0, b.0, c.0, d.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F] Val::map5(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  map : (A, B, C, D, E) -> F,
) -> Val[F] {
  Val(@val.Val::map5(a.0, b.0, c.0, d.0, e.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G] Val::map6(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  map : (A, B, C, D, E, F) -> G,
) -> Val[G] {
  Val(@val.Val::map6(a.0, b.0, c.0, d.0, e.0, f.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H] Val::map7(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  map : (A, B, C, D, E, F, G) -> H,
) -> Val[H] {
  Val(@val.Val::map7(a.0, b.0, c.0, d.0, e.0, f.0, g.0, map))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H : Eq, I] Val::map8(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  h : Val[H],
  map : (A, B, C, D, E, F, G, H) -> I,
) -> Val[I] {
  Val(@val.Val::map8(a.0, b.0, c.0, d.0, e.0, f.0, g.0, h.0, map))
}

///|
pub fn[
  A : Eq,
  B : Eq,
  C : Eq,
  D : Eq,
  E : Eq,
  F : Eq,
  G : Eq,
  H : Eq,
  I : Eq,
  J,
] Val::map9(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  h : Val[H],
  i : Val[I],
  map : (A, B, C, D, E, F, G, H, I) -> J,
) -> Val[J] {
  Val(@val.Val::map9(a.0, b.0, c.0, d.0, e.0, f.0, g.0, h.0, i.0, map))
}

///|
pub fn[A : Eq] Val::view(self : Val[A], render : (A) -> Node) -> Val[Node] {
  self.map(render)
}

///|
pub fn[A : Eq, B : Eq] Val::view2(
  a : Val[A],
  b : Val[B],
  render : (A, B) -> Node,
) -> Val[Node] {
  Val::map2(a, b, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq] Val::view3(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  render : (A, B, C) -> Node,
) -> Val[Node] {
  Val::map3(a, b, c, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq] Val::view4(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  render : (A, B, C, D) -> Node,
) -> Val[Node] {
  Val::map4(a, b, c, d, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq] Val::view5(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  render : (A, B, C, D, E) -> Node,
) -> Val[Node] {
  Val::map5(a, b, c, d, e, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq] Val::view6(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  render : (A, B, C, D, E, F) -> Node,
) -> Val[Node] {
  Val::map6(a, b, c, d, e, f, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq] Val::view7(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  render : (A, B, C, D, E, F, G) -> Node,
) -> Val[Node] {
  Val::map7(a, b, c, d, e, f, g, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H : Eq] Val::view8(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  h : Val[H],
  render : (A, B, C, D, E, F, G, H) -> Node,
) -> Val[Node] {
  Val::map8(a, b, c, d, e, f, g, h, render)
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H : Eq, I : Eq] Val::view9(
  a : Val[A],
  b : Val[B],
  c : Val[C],
  d : Val[D],
  e : Val[E],
  f : Val[F],
  g : Val[G],
  h : Val[H],
  i : Val[I],
  render : (A, B, C, D, E, F, G, H, I) -> Node,
) -> Val[Node] {
  Val::map9(a, b, c, d, e, f, g, h, i, render)
}

///|
pub fn[K : Hash + Eq, V : Eq, C : Eq] Val::assoc(
  self : Val[Vector[(K, V)]],
  build : (K, Val[V]) -> Val[C],
) -> Val[Vector[C]] {
  Val(self.0.assoc((key, value) => build(key, Val(value)).0))
}

///|
pub fn[K : Hash + Eq, V : Eq, C : Eq] Val::assoc_by(
  self : Val[Vector[V]],
  build : (K, Val[V]) -> Val[C],
  by~ : (V) -> K,
) -> Val[Vector[C]] {
  Val(self.0.assoc_by((key, value) => build(key, Val(value)).0, by~))
}

///|
pub trait Enumerate {
  fn tag(Self) -> String
}

///|
pub fn[E : Enumerate + Eq, C : Eq] Val::switch(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
) -> Val[C] {
  self.switch_by(build, by=value => Enumerate::tag(value))
}

///|
pub fn[E : Eq, C : Eq] Val::switch_by(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
  by~ : (E) -> String,
) -> Val[C] {
  Val(self.0.switch_by((initial, input) => build(initial, Val(input)).0, by~))
}

///|
pub fn[E : Enumerate + Eq, C : Eq] Val::enumerate(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
) -> Val[C] {
  self.enumerate_by(build, by=value => Enumerate::tag(value))
}

///|
pub fn[E : Eq, C : Eq] Val::enumerate_by(
  self : Val[E],
  build : (E, Val[E]) -> Val[C],
  by~ : (E) -> String,
) -> Val[C] {
  Val(
    self.0.enumerate_by((initial, input) => build(initial, Val(input)).0, by~),
  )
}

///|
/// Cache at most `capacity` dynamic branches, evicting the least-recently used
/// inactive branch after a successful candidate commit.
pub fn[E : Eq, C : Eq] Val::enumerate_bounded_by(
  self : Val[E],
  capacity~ : Int,
  build~ : (E, Val[E]) -> Val[C],
  by~ : (E) -> String,
) -> Val[C] {
  Val(
    self.0.enumerate_bounded_by(
      capacity~,
      build=(initial, input) => build(initial, Val(input)).0,
      by~,
    ),
  )
}

///|
struct Sub(@val.Sub)

///|
pub fn Sub::none() -> Sub {
  Sub(@val.no_sub)
}

///|
pub fn Sub::batch(subscriptions : Array[Sub]) -> Sub {
  Sub(@val.sub_batch(subscriptions.map(subscription => subscription.0)))
}

///|
fn[Msg] wrap_emit(emit : @val.Emit[Msg]) -> Emit[Msg] {
  Emit(message => Cmd(emit.emit(message)))
}

///|
pub fn[Model : Eq, Msg] create_pure_state(
  initial : Model,
  update~ : (Model, Msg) -> Model,
) -> (Val[Model], Emit[Msg]) {
  let (value, emit) = @val.create_pure_state(initial, update~)
  (Val(value), wrap_emit(emit))
}

///|
pub fn[Model : Eq, Msg] create_state(
  initial : Model,
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Val[Model], Emit[Msg]) {
  let mapped_subscriptions = match subscriptions {
    Some(build) =>
      Some((model : Model, emit : @val.Emit[Msg]) => {
        build(model, wrap_emit(emit)).0
      })
    None => None
  }
  let (value, emit) = @val.create_state(
    initial,
    update=(model, message, emit) => {
      let (next, command) = update(model, message, wrap_emit(emit))
      (next, command.0)
    },
    subscriptions?=mapped_subscriptions,
  )
  (Val(value), wrap_emit(emit))
}

///|
pub fn[Model : Eq, Msg] create_state_with_init(
  init~ : (Emit[Msg]) -> (Model, Cmd),
  update~ : (Model, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Emit[Msg]) -> Sub,
) -> (Val[Model], Emit[Msg]) {
  let mapped_subscriptions = match subscriptions {
    Some(build) =>
      Some((model : Model, emit : @val.Emit[Msg]) => {
        build(model, wrap_emit(emit)).0
      })
    None => None
  }
  let (value, emit) = @val.create_state_with_init(
    init=emit => {
      let (model, command) = init(wrap_emit(emit))
      (model, command.0)
    },
    update=(model, message, emit) => {
      let (next, command) = update(model, message, wrap_emit(emit))
      (next, command.0)
    },
    subscriptions?=mapped_subscriptions,
  )
  (Val(value), wrap_emit(emit))
}

///|
pub fn[Model : Eq, Msg, Input : Eq] create_state_with_input(
  init~ : (Emit[Msg], Input) -> (Model, Cmd),
  update~ : (Model, Input, Msg, Emit[Msg]) -> (Model, Cmd),
  subscriptions? : (Model, Input, Emit[Msg]) -> Sub,
  input~ : Val[Input],
) -> (Val[Model], Emit[Msg]) {
  let mapped_subscriptions = match subscriptions {
    Some(build) =>
      Some((model : Model, current_input : Input, emit : @val.Emit[Msg]) => {
        build(model, current_input, wrap_emit(emit)).0
      })
    None => None
  }
  let (value, emit) = @val.create_state_with_input(
    input=input.0,
    init=(emit, current_input) => {
      let (model, command) = init(wrap_emit(emit), current_input)
      (model, command.0)
    },
    update=(model, current_input, message, emit) => {
      let (next, command) = update(
        model,
        current_input,
        message,
        wrap_emit(emit),
      )
      (next, command.0)
    },
    subscriptions?=mapped_subscriptions,
  )
  (Val(value), wrap_emit(emit))
}

///|
pub fn[Model : Eq] create_variable(
  initial : Model,
) -> (Val[Model], Emit[(Model) -> Model]) {
  let (value, emit) = @val.create_variable(initial)
  (Val(value), wrap_emit(emit))
}

///|
pub fn[T : Eq] create_resource(
  load : (Emit[Result[T, Error]]) -> Cmd,
) -> Val[Status[T]] {
  Val(
    @val.create_resource(emit => load(wrap_emit(emit)).0).map(status => {
      match status {
        @val.Pending => Pending
        @val.Loaded(value) => Loaded(value)
        @val.Failed(error) => Failed(error)
      }
    }),
  )
}

///|
pub impl[T] Enumerate for Status[T] with fn tag(self) {
  match self {
    Pending => "pending"
    Loaded(_) => "loaded"
    Failed(_) => "failed"
  }
}
