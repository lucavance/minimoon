///|
/// The complete contract for one MiniApp page. Model and Msg remain private to
/// the application package while the generator consumes the stable metadata
/// exposed through the methods below.
pub struct PageProgram[Model, Msg] {
  id : String
  route : String
  title : String
  initial : Model
  component_owner_id : Int
  component : @runtime.Component[Model, Msg]
  view : (Events[Msg], Model) -> @ui.Node
  contract_tree : Json
  active_tree : Ref[Json]
  active_events : Ref[Array[PageEvent[Msg]]]
  active_event_index : Ref[Map[String, PageEvent[Msg]]]
  active_subscriptions : Ref[Array[HostSubscription[Msg]]]
  active_scope_cleanups : Ref[Map[String, () -> Unit]]
  capabilities : Array[MiniappCapability]
  lifecycle : Array[PageLifecycleEvent[Msg]]
  inputs : Array[PageInput[Msg]]
  init : Msg?
}

///|
priv struct RenderCandidate[Msg] {
  tree : Json
  normalization : NormalizedCandidate
  events : Array[PageEvent[Msg]]
  event_index : Map[String, PageEvent[Msg]]
  subscriptions : Array[HostSubscription[Msg]]
  scope_cleanups : Map[String, () -> Unit]
  commits : Array[() -> Unit]
}

///|
let next_component_owner_id : Ref[Int] = Ref(1)

///|
fn allocate_component_owner_id() -> Int {
  let owner_id = next_component_owner_id.val
  next_component_owner_id.val = owner_id + 1
  owner_id
}

///|
fn[Msg] RenderCandidate::commit(self : RenderCandidate[Msg]) -> Unit {
  for commit in self.commits {
    commit()
  }
}

///|
fn[Model, Msg] render_candidate(
  view : (Events[Msg], Model) -> @ui.Node,
  model : Model,
  root_subscriptions : ((Model) -> Subscriptions[Msg])?,
  owner_id : Int,
  normalization_cache : Map[String, NormalizedCacheEntry],
) -> Result[RenderCandidate[Msg], String] {
  let registry = events_for_owner(owner_id)
  let node = view(registry, model)
  match root_subscriptions {
    Some(build) =>
      for entry in build(model).entries {
        registry.subscriptions.val.push(entry)
      }
    None => ()
  }
  let registered = registry.entries()
  let event_index = registry.event_index()
  let result = match registry.validation_error() {
    Some(error) => Err(error)
    None =>
      match page_events_validation_error(registered) {
        Some(error) => Err(error)
        None =>
          match subscription_validation_error(registry.subscription_entries()) {
            Some(error) => Err(error)
            None =>
              match
                normalize_miniapp_tree_cached_checked(
                  node, event_index, normalization_cache,
                ) {
                Ok(normalization) =>
                  Ok({
                    tree: normalization.tree,
                    normalization,
                    events: registered,
                    event_index,
                    subscriptions: registry.subscription_entries(),
                    scope_cleanups: registry.cleanups(),
                    commits: registry.commits(),
                  })
                Err(error) => Err(error)
              }
          }
      }
  }
  match result {
    Err(error) => {
      registry.rollback()
      Err(error)
    }
    Ok(candidate) => Ok(candidate)
  }
}

///|
pub fn[Model, Msg] page_program(
  id~ : String,
  route~ : String,
  title~ : String,
  model~ : Model,
  update~ : @runtime.Update[Model, Msg],
  view~ : (Events[Msg], Model) -> @ui.Node,
  projection_guard? : @runtime.ProjectionGuard[Model],
  capabilities? : Array[MiniappCapability] = [],
  lifecycle? : Array[PageLifecycleEvent[Msg]] = [],
  inputs? : Array[PageInput[Msg]] = [],
  init? : Msg,
  subscriptions? : (Model) -> Subscriptions[Msg],
) -> PageProgram[Model, Msg] {
  validate_page_identity(id, route, title)
  let component_owner_id = allocate_component_owner_id()
  let normalization_cache : Ref[Map[String, NormalizedCacheEntry]] = Ref(
    Map([]),
  )
  let normalization_roots : Ref[Array[String]] = Ref([])
  let initial = match
    render_candidate(
      view,
      model,
      subscriptions,
      component_owner_id,
      normalization_cache.val,
    ) {
    Ok(candidate) => candidate
    Err(error) => abort(error)
  }
  initial.commit()
  commit_normalized_candidate(
    initial.normalization,
    normalization_cache,
    normalization_roots,
  )
  let active_events = Ref(initial.events)
  let active_event_index = Ref(initial.event_index)
  let active_subscriptions = Ref(initial.subscriptions)
  let active_scope_cleanups = Ref(initial.scope_cleanups)
  let active_tree = Ref(initial.tree)
  {
    id,
    route,
    title,
    initial: model,
    component_owner_id,
    component: @runtime.checked_component(
      model~,
      update~,
      view=(current, _) => view(events_for_owner(component_owner_id), current),
      project=current => {
        match
          render_candidate(
            view,
            current,
            subscriptions,
            component_owner_id,
            normalization_cache.val,
          ) {
          Ok(candidate) => {
            for scope, cleanup in active_scope_cleanups.val {
              if !candidate.scope_cleanups.contains(scope) {
                cleanup()
              }
            }
            candidate.commit()
            commit_normalized_candidate(
              candidate.normalization,
              normalization_cache,
              normalization_roots,
            )
            active_tree.val = candidate.tree
            active_events.val = candidate.events
            active_event_index.val = candidate.event_index
            active_subscriptions.val = candidate.subscriptions
            active_scope_cleanups.val = candidate.scope_cleanups
            // The page runtime consumes the committed typed tree directly.
            // This token only asks runtime_core to enqueue a state boundary.
            Ok("typed-tree")
          }
          Err(error) => Err(error)
        }
      },
      projection_guard?,
    ),
    view,
    contract_tree: initial.tree,
    active_tree,
    active_events,
    active_event_index,
    active_subscriptions,
    active_scope_cleanups,
    capabilities,
    lifecycle,
    inputs,
    init,
  }
}

///|
pub fn[Model, Msg] simple_page_program(
  id~ : String,
  route~ : String,
  title~ : String,
  model~ : Model,
  update~ : @runtime.PureUpdate[Model, Msg],
  view~ : (Events[Msg], Model) -> @ui.Node,
  projection_guard? : @runtime.ProjectionGuard[Model],
  capabilities? : Array[MiniappCapability] = [],
  lifecycle? : Array[PageLifecycleEvent[Msg]] = [],
  inputs? : Array[PageInput[Msg]] = [],
  init? : Msg,
  subscriptions? : (Model) -> Subscriptions[Msg],
) -> PageProgram[Model, Msg] {
  page_program(
    id~,
    route~,
    title~,
    model~,
    update=(current, msg) => @runtime.no_cmd(update(current, msg)),
    view~,
    projection_guard?,
    capabilities~,
    lifecycle~,
    inputs~,
    init?,
    subscriptions?,
  )
}

///|
pub fn[Model, Msg] PageProgram::id(self : PageProgram[Model, Msg]) -> String {
  self.id
}

///|
pub fn[Model, Msg] PageProgram::route(self : PageProgram[Model, Msg]) -> String {
  self.route
}

///|
pub fn[Model, Msg] PageProgram::title(self : PageProgram[Model, Msg]) -> String {
  self.title
}

///|
pub fn[Model, Msg] PageProgram::initial_model(
  self : PageProgram[Model, Msg],
) -> Model {
  self.initial
}

///|
pub fn[Model, Msg] PageProgram::component(
  self : PageProgram[Model, Msg],
) -> @runtime.Component[Model, Msg] {
  self.component
}

///|
pub fn[Model, Msg] PageProgram::initial_tree(
  self : PageProgram[Model, Msg],
) -> Json {
  self.contract_tree
}

///|
pub fn[Model, Msg] PageProgram::render(
  self : PageProgram[Model, Msg],
) -> @ui.Node {
  self.component.render()
}

///|
pub fn[Model, Msg] PageProgram::events(
  self : PageProgram[Model, Msg],
) -> Array[PageEvent[Msg]] {
  self.active_events.val.copy()
}

///|
pub fn[Model, Msg] PageProgram::capabilities(
  self : PageProgram[Model, Msg],
) -> Array[MiniappCapability] {
  self.capabilities
}

///|
pub fn[Model, Msg] PageProgram::lifecycle(
  self : PageProgram[Model, Msg],
) -> Array[PageLifecycleEvent[Msg]] {
  self.lifecycle
}

///|
pub fn[Model, Msg] PageProgram::inputs(
  self : PageProgram[Model, Msg],
) -> Array[PageInput[Msg]] {
  self.inputs
}

///|
pub fn[Model, Msg] PageProgram::decode_event(
  self : PageProgram[Model, Msg],
  key : String,
  payload : Json,
) -> Result[Msg?, MiniappDecodeError] {
  match self.active_event_index.val.get(key) {
    Some(event) =>
      match (event.decode)(payload) {
        Ok(msg) => Ok(Some(msg))
        Err(error) => Err(error)
      }
    None => Ok(None)
  }
}

///|
pub fn[Model, Msg] PageProgram::decode_lifecycle(
  self : PageProgram[Model, Msg],
  hook : PageLifecycleHook,
  payload : Json,
) -> Result[Msg?, MiniappDecodeError] {
  for event in self.lifecycle {
    if event.hook == hook {
      return match (event.decode)(payload) {
        Ok(msg) => Ok(Some(msg))
        Err(error) => Err(error)
      }
    }
  }
  Ok(None)
}

///|
pub fn[Model, Msg] PageProgram::decode_input(
  self : PageProgram[Model, Msg],
  name : String,
  value : String,
) -> Result[Msg?, MiniappDecodeError] {
  for input in self.inputs {
    if input.name == name {
      return match (input.decode)(value) {
        Ok(msg) => Ok(Some(msg))
        Err(error) => Err(error)
      }
    }
  }
  Ok(None)
}

///|
fn validate_page_identity(id : String, route : String, title : String) -> Unit {
  guard is_page_identifier(id) else {
    abort("page id must match [A-Za-z_][A-Za-z0-9_]*: " + id)
  }
  guard route != "" else { abort("page route must not be empty") }
  guard !route.has_prefix("/") &&
    !route.has_suffix("/") &&
    !route.contains("//") &&
    !route.contains("..") else {
    abort("page route must be a normalized relative path: " + route)
  }
  for char in route {
    let valid = (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      char == '_' ||
      char == '-' ||
      char == '/'
    guard valid else {
      abort("page route contains an unsupported character: " + route)
    }
  }
  guard title != "" else { abort("page title must not be empty") }
}

///|
fn is_page_identifier(value : String) -> Bool {
  guard value != "" else { false }
  for index = 0; index < value.length(); index = index + 1 {
    let char = value[index]
    let valid = (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      char == '_' ||
      (index > 0 && char >= '0' && char <= '9')
    guard valid else { return false }
  }
  true
}

///|
fn[Msg] page_events_validation_error(events : Array[PageEvent[Msg]]) -> String? {
  let keys : Set[String] = Set([])
  for event in events {
    if keys.contains(event.key) {
      return Some("duplicate page event key: " + event.key)
    }
    keys.add(event.key)
  }
  None
}

///|
fn[Msg] subscription_validation_error(
  subscriptions : Array[HostSubscription[Msg]],
) -> String? {
  let keys : Set[String] = Set([])
  for subscription in subscriptions {
    if subscription.key == "" {
      return Some("subscription key must not be empty")
    }
    if subscription.interval_ms <= 0 {
      return Some("subscription interval must be positive: " + subscription.key)
    }
    if keys.contains(subscription.key) {
      return Some("duplicate subscription key: " + subscription.key)
    }
    keys.add(subscription.key)
  }
  None
}
