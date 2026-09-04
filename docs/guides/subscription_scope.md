# Subscription scope

Subscriptions are `Sub` values owned by the lexical graph scope where state is
created.

```moonbit
let (model, emit) = @minimoon.create_state(
  initial,
  update~,
  subscriptions=(current, emit) => {
    if current.enabled {
      context.every(
        key="pulse",
        interval_ms=1000,
        command=emit(Pulse),
      )
    } else {
      @minimoon.Sub::none()
    }
  },
)
```

Page lifecycle helpers (`on_load`, `on_show`, `on_hide`, `on_unload`, pull-down
refresh, and reach-bottom) also return `Sub`; `Sub::batch` combines them.

For state inside `Val::assoc_by`, the keyed branch owns its providers. Reorder
keeps them active. Candidate removal makes them invisible before the renderer
derives the next subscription set; commit disposes them and rollback restores
them. A rejected render therefore cannot lose an existing timer or publish a
stale new one.

Page disposal recursively invalidates emitters and stops active intervals.
Commands from a disposed branch become no-ops. The host generation token also
rejects callbacks queued before unload.

The renderer owns the only live host-subscription table. When a render keeps
the same key and interval, no stop/start pair is emitted, but the table replaces
the typed message with the newest one. A later tick therefore observes current
model/input capture without allocating a duplicate timer.
