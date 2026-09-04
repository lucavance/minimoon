// Derived from moonbit-community/rabbita v0.13.1 (6392a57), Apache-2.0.
// Modified and maintained as part of Minimoon's internal incremental graph.

///|
fn[T] map_node(childs : Array[&ErasedNode], compute : () -> T) -> Node[T] {
  let dirty = { dirty: true, parents: [], id: get_uuid(), }
  {
    id: get_uuid(),
    scope: current_scope.val,
    value: None,
    compute,
    childs,
    dirty_flag: dirty,
    changed_at: 0,
    recomputed_at: 0,
  }
}

///|
pub fn[A : Eq, B] Node::map1(a : Node[A], f : (A) -> B) -> Node[B] {
  map_node([a], () => f(a.value.unwrap()))
}

///|
pub fn[A : Eq, B : Eq, C] Node::map2(
  a : Node[A],
  b : Node[B],
  f : (A, B) -> C,
) -> Node[C] {
  map_node([a, b], () => f(a.value.unwrap(), b.value.unwrap()))
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D] Node::map3(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  f : (A, B, C) -> D,
) -> Node[D] {
  map_node([a, b, c], () => {
    f(a.value.unwrap(), b.value.unwrap(), c.value.unwrap())
  })
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E] Node::map4(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  d : Node[D],
  f : (A, B, C, D) -> E,
) -> Node[E] {
  map_node([a, b, c, d], () => {
    f(a.value.unwrap(), b.value.unwrap(), c.value.unwrap(), d.value.unwrap())
  })
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F] Node::map5(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  d : Node[D],
  e : Node[E],
  f : (A, B, C, D, E) -> F,
) -> Node[F] {
  map_node([a, b, c, d, e], () => {
    f(
      a.value.unwrap(),
      b.value.unwrap(),
      c.value.unwrap(),
      d.value.unwrap(),
      e.value.unwrap(),
    )
  })
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G] Node::map6(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  d : Node[D],
  e : Node[E],
  f : Node[F],
  g : (A, B, C, D, E, F) -> G,
) -> Node[G] {
  map_node([a, b, c, d, e, f], () => {
    g(
      a.value.unwrap(),
      b.value.unwrap(),
      c.value.unwrap(),
      d.value.unwrap(),
      e.value.unwrap(),
      f.value.unwrap(),
    )
  })
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H] Node::map7(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  d : Node[D],
  e : Node[E],
  f : Node[F],
  g : Node[G],
  h : (A, B, C, D, E, F, G) -> H,
) -> Node[H] {
  map_node([a, b, c, d, e, f, g], () => {
    h(
      a.value.unwrap(),
      b.value.unwrap(),
      c.value.unwrap(),
      d.value.unwrap(),
      e.value.unwrap(),
      f.value.unwrap(),
      g.value.unwrap(),
    )
  })
}

///|
pub fn[A : Eq, B : Eq, C : Eq, D : Eq, E : Eq, F : Eq, G : Eq, H : Eq, I] Node::map8(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  d : Node[D],
  e : Node[E],
  f : Node[F],
  g : Node[G],
  h : Node[H],
  i : (A, B, C, D, E, F, G, H) -> I,
) -> Node[I] {
  map_node([a, b, c, d, e, f, g, h], () => {
    i(
      a.value.unwrap(),
      b.value.unwrap(),
      c.value.unwrap(),
      d.value.unwrap(),
      e.value.unwrap(),
      f.value.unwrap(),
      g.value.unwrap(),
      h.value.unwrap(),
    )
  })
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
] Node::map9(
  a : Node[A],
  b : Node[B],
  c : Node[C],
  d : Node[D],
  e : Node[E],
  f : Node[F],
  g : Node[G],
  h : Node[H],
  i : Node[I],
  j : (A, B, C, D, E, F, G, H, I) -> J,
) -> Node[J] {
  map_node([a, b, c, d, e, f, g, h, i], () => {
    j(
      a.value.unwrap(),
      b.value.unwrap(),
      c.value.unwrap(),
      d.value.unwrap(),
      e.value.unwrap(),
      f.value.unwrap(),
      g.value.unwrap(),
      h.value.unwrap(),
      i.value.unwrap(),
    )
  })
}
