///|
priv struct NormalizedCacheEntry {
  tree : Json
  children : Array[String]
}

///|
priv struct NormalizationWork {
  node_visits : Int
  cache_hits : Int
}

///|
priv struct NormalizedCandidate {
  tree : Json
  updates : Map[String, NormalizedCacheEntry]
  roots : Array[String]
  reached : Set[String]
  work : NormalizationWork
}

///|
priv struct NormalizationContext[Msg] {
  events : Map[String, PageEvent[Msg]]
  active : Map[String, NormalizedCacheEntry]
  updates : Map[String, NormalizedCacheEntry]
  reached : Set[String]
  node_visits : Ref[Int]
  cache_hits : Ref[Int]
}

///|
fn retained_cache_key(identity : Int, path : String) -> String {
  identity.to_string() + "@" + path.length().to_string() + ":" + path
}

///|
fn indexed_normalization_path(path : String, index : Int) -> String {
  path + "/i:" + index.to_string()
}

///|
fn keyed_normalization_path(path : String, key : String) -> String {
  path + "/k:" + key.length().to_string() + ":" + key
}

///|
fn[Msg] checked_normalize_children(
  children : Array[@ui.Node],
  path : String,
  context : NormalizationContext[Msg],
  cache_children : Array[String],
) -> Result[Array[Json], String] {
  let output : Array[Json] = []
  for index = 0; index < children.length(); index = index + 1 {
    match
      checked_normalize_node(
        children[index],
        "i:" + index.to_string(),
        indexed_normalization_path(path, index),
        context,
        cache_children,
      ) {
      Ok(child) => output.push(child)
      Err(error) => return Err(error)
    }
  }
  Ok(output)
}

///|
fn[Msg] checked_normalize_keyed_children(
  children : Array[@ui.KeyedNode],
  path : String,
  context : NormalizationContext[Msg],
  cache_children : Array[String],
) -> Result[Array[Json], String] {
  let output : Array[Json] = []
  let keys : Set[String] = Set([])
  for child in children {
    let key = child.key()
    if key == "" {
      return Err("MiniApp render key must not be empty")
    }
    if keys.contains(key) {
      return Err("duplicate MiniApp render sibling key: " + key)
    }
    keys.add(key)
    match
      checked_normalize_node(
        child.node(),
        "k:" + key,
        keyed_normalization_path(path, key),
        context,
        cache_children,
      ) {
      Ok(child) => output.push(child)
      Err(error) => return Err(error)
    }
  }
  Ok(output)
}

///|
fn[Msg] checked_normalize_node(
  node : @ui.Node,
  identity : String,
  path : String,
  context : NormalizationContext[Msg],
  cache_children : Array[String],
) -> Result[Json, String] {
  match node {
    @ui.Retained(node_id, child) => {
      let key = retained_cache_key(node_id, path)
      cache_children.push(key)
      context.reached.add(key)
      match context.updates.get(key) {
        Some(entry) => {
          context.cache_hits.val += 1
          Ok(entry.tree)
        }
        None =>
          match context.active.get(key) {
            Some(entry) => {
              context.cache_hits.val += 1
              Ok(entry.tree)
            }
            None => {
              let children : Array[String] = []
              match
                checked_normalize_node(child, identity, path, context, children) {
                Ok(tree) => {
                  context.updates[key] = { tree, children, }
                  Ok(tree)
                }
                Err(error) => Err(error)
              }
            }
          }
      }
    }
    node => {
      context.node_visits.val += 1
      match node {
        @ui.Text(value) =>
          Ok(
            normalized_tree_node("text", identity, value, empty_tree_props(), []),
          )
        @ui.Fragment(children) =>
          match
            checked_normalize_children(children, path, context, cache_children) {
            Ok(normalized) =>
              Ok(
                normalized_tree_node(
                  "fragment",
                  identity,
                  "",
                  empty_tree_props(),
                  normalized,
                ),
              )
            Err(error) => Err(error)
          }
        @ui.KeyedFragment(children) =>
          match
            checked_normalize_keyed_children(
              children, path, context, cache_children,
            ) {
            Ok(normalized) =>
              Ok(
                normalized_tree_node(
                  "fragment",
                  identity,
                  "",
                  empty_tree_props(),
                  normalized,
                ),
              )
            Err(error) => Err(error)
          }
        @ui.Empty =>
          Ok(
            normalized_tree_node("empty", identity, "", empty_tree_props(), []),
          )
        @ui.Element(tag, attrs, children) => {
          if !supported_tree_tag(tag) {
            return Err("unsupported MiniApp render tag: " + tag)
          }
          let kind = miniapp_tree_kind(tag)
          if (
              kind == "input" ||
              kind == "image" ||
              kind == "textarea" ||
              kind == "switch"
            ) &&
            children.length() > 0 {
            return Err("MiniApp " + kind + " nodes must not have children")
          }
          let props = match checked_tree_props(tag, attrs, context.events) {
            Ok(props) => props
            Err(error) => return Err(error)
          }
          match
            checked_normalize_children(children, path, context, cache_children) {
            Ok(normalized) =>
              Ok(normalized_tree_node(kind, identity, "", props, normalized))
            Err(error) => Err(error)
          }
        }
        @ui.Retained(_, _) => abort("unreachable retained normalization branch")
      }
    }
  }
}

///|
fn[Msg] normalize_miniapp_tree_cached_checked(
  node : @ui.Node,
  events : Map[String, PageEvent[Msg]],
  active : Map[String, NormalizedCacheEntry],
) -> Result[NormalizedCandidate, String] {
  let updates : Map[String, NormalizedCacheEntry] = Map([])
  let reached : Set[String] = Set([])
  let node_visits = Ref(0)
  let cache_hits = Ref(0)
  let context = { events, active, updates, reached, node_visits, cache_hits, }
  let roots : Array[String] = []
  match checked_normalize_node(node, "root", "root", context, roots) {
    Ok(tree) =>
      Ok({
        tree,
        updates,
        roots,
        reached,
        work: { node_visits: node_visits.val, cache_hits: cache_hits.val, },
      })
    Err(error) => Err(error)
  }
}

///|
fn prune_normalized_cache(
  entries : Map[String, NormalizedCacheEntry],
  key : String,
  retained : Set[String],
) -> Unit {
  if retained.contains(key) {
    return
  }
  match entries.get(key) {
    Some(entry) => {
      entries.remove(key)
      for child in entry.children {
        prune_normalized_cache(entries, child, retained)
      }
    }
    None => ()
  }
}

///|
fn commit_normalized_candidate(
  candidate : NormalizedCandidate,
  entries : Ref[Map[String, NormalizedCacheEntry]],
  roots : Ref[Array[String]],
) -> Unit {
  let _ = candidate.work.node_visits
  let _ = candidate.work.cache_hits
  for key in roots.val {
    if !candidate.reached.contains(key) {
      prune_normalized_cache(entries.val, key, candidate.reached)
    }
  }
  for key, entry in candidate.updates {
    entries.val[key] = entry
  }
  roots.val = candidate.roots
}

///|
fn[Msg] checked_page_event_index(
  events : Array[PageEvent[Msg]],
) -> Result[Map[String, PageEvent[Msg]], String] {
  let output : Map[String, PageEvent[Msg]] = Map([])
  for event in events {
    if output.contains(event.key) {
      return Err("duplicate page event key: " + event.key)
    }
    output[event.key] = event
  }
  Ok(output)
}

///|
pub fn[Msg] normalize_miniapp_tree(
  node : @ui.Node,
  events : Array[PageEvent[Msg]],
) -> Json {
  match normalize_miniapp_tree_checked(node, events) {
    Ok(tree) => tree
    Err(error) => abort(error)
  }
}

///|
pub fn[Msg] normalize_miniapp_tree_checked(
  node : @ui.Node,
  events : Array[PageEvent[Msg]],
) -> Result[Json, String] {
  match checked_page_event_index(events) {
    Err(error) => Err(error)
    Ok(index) =>
      match normalize_miniapp_tree_cached_checked(node, index, Map([])) {
        Ok(candidate) => Ok(candidate.tree)
        Err(error) => Err(error)
      }
  }
}

///|
pub fn dynamic_templates_wxml() -> String {
  let semantics = " aria-role=\"{{node.props.role}}\" aria-expanded=\"{{node.props.ariaExpanded}}\" aria-selected=\"{{node.props.ariaSelected}}\" aria-disabled=\"{{node.props.ariaDisabled}}\" aria-hidden=\"{{node.props.ariaHidden}}\" aria-checked=\"{{node.props.ariaChecked}}\" aria-modal=\"{{node.props.ariaModal}}\" aria-controls=\"{{node.props.ariaControls}}\" aria-labelledby=\"{{node.props.ariaLabelledBy}}\" aria-describedby=\"{{node.props.ariaDescribedBy}}\" aria-orientation=\"{{node.props.ariaOrientation}}\" aria-haspopup=\"{{node.props.ariaHasPopup}}\""
  "<template name=\"minimoon_dynamic_node\">\n" +
  "  <block wx:if=\"{{node.kind === 'empty'}}\"></block>\n" +
  "  <block wx:elif=\"{{node.kind === 'fragment'}}\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\">\n" +
  "      <template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" />\n" +
  "    </block>\n" +
  "  </block>\n" +
  "  <text wx:elif=\"{{node.kind === 'text'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" aria-label=\"{{node.props.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{node.props.section}}\" data-minimoon-tap=\"{{node.events.tap}}\" bindtap=\"__mmDispatchTap\">{{node.text}}</text>\n" +
  "  <view wx:elif=\"{{node.kind === 'view'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" aria-label=\"{{node.props.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{node.props.section}}\" data-minimoon-tap=\"{{node.events.tap}}\" bindtap=\"__mmDispatchTap\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block>\n" +
  "  </view>\n" +
  "  <button wx:elif=\"{{node.kind === 'button'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" disabled=\"{{node.props.disabled}}\" aria-label=\"{{node.props.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{node.props.section}}\" data-minimoon-tap=\"{{node.events.tap}}\" catchtap=\"__mmDispatchTap\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block>\n" +
  "  </button>\n" +
  "  <input wx:elif=\"{{node.kind === 'input'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" value=\"{{node.props.value}}\" placeholder=\"{{node.props.placeholder}}\" disabled=\"{{node.props.disabled}}\" focus=\"{{node.props.focus}}\" aria-label=\"{{node.props.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{node.props.section}}\" data-minimoon-input=\"{{node.events.input}}\" data-minimoon-confirm=\"{{node.events.confirm}}\" data-minimoon-focus=\"{{node.events.focus}}\" data-minimoon-blur=\"{{node.events.blur}}\" bindinput=\"__mmDispatchInput\" bindconfirm=\"__mmDispatchConfirm\" bindfocus=\"__mmDispatchFocus\" bindblur=\"__mmDispatchBlur\" />\n" +
  "  <image wx:elif=\"{{node.kind === 'image'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" src=\"{{node.props.src}}\" aria-label=\"{{node.props.ariaLabel || node.props.alt}}\"" +
  semantics +
  " data-minimoon-section=\"{{node.props.section}}\" data-minimoon-tap=\"{{node.events.tap}}\" bindtap=\"__mmDispatchTap\" />\n" +
  "  <scroll-view wx:elif=\"{{node.kind === 'scroll-view'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" scroll-x=\"{{node.props.scrollX}}\" scroll-y=\"{{node.props.scrollY}}\" scroll-top=\"{{node.props.scrollTop}}\" scroll-left=\"{{node.props.scrollLeft}}\" scroll-into-view=\"{{node.props.scrollIntoView}}\" upper-threshold=\"{{node.props.upperThreshold}}\" lower-threshold=\"{{node.props.lowerThreshold}}\" data-minimoon-scroll=\"{{node.events.scroll}}\" data-minimoon-upper=\"{{node.events.upper}}\" data-minimoon-lower=\"{{node.events.lower}}\" bindscroll=\"__mmDispatchScroll\" bindscrolltoupper=\"__mmDispatchUpper\" bindscrolltolower=\"__mmDispatchLower\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block>\n" +
  "  </scroll-view>\n" +
  "  <textarea wx:elif=\"{{node.kind === 'textarea'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" model:value=\"{{node.props.value}}\" placeholder=\"{{node.props.placeholder}}\" maxlength=\"{{node.props.maxlength}}\" disabled=\"{{node.props.disabled}}\" focus=\"{{node.props.focus}}\" aria-label=\"{{node.props.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{node.props.section}}\" data-minimoon-input=\"{{node.events.input}}\" data-minimoon-confirm=\"{{node.events.confirm}}\" data-minimoon-focus=\"{{node.events.focus}}\" data-minimoon-blur=\"{{node.events.blur}}\" bind:input=\"__mmDispatchInput\" bind:confirm=\"__mmDispatchConfirm\" bind:focus=\"__mmDispatchFocus\" bind:blur=\"__mmDispatchBlur\"></textarea>\n" +
  "  <switch wx:elif=\"{{node.kind === 'switch'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" checked=\"{{node.props.checked}}\" disabled=\"{{node.props.disabled}}\" color=\"{{node.props.color}}\" aria-label=\"{{node.props.ariaLabel}}\"" +
  semantics +
  " data-minimoon-change=\"{{node.events.change}}\" bindchange=\"__mmDispatchChange\" />\n" +
  "  <checkbox-group wx:elif=\"{{node.kind === 'checkbox-group'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" data-minimoon-change=\"{{node.events.change}}\" bindchange=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></checkbox-group>\n" +
  "  <checkbox wx:elif=\"{{node.kind === 'checkbox'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" value=\"{{node.props.value}}\" checked=\"{{node.props.checked}}\" disabled=\"{{node.props.disabled}}\" color=\"{{node.props.color}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></checkbox>\n" +
  "  <radio-group wx:elif=\"{{node.kind === 'radio-group'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" data-minimoon-change=\"{{node.events.change}}\" bindchange=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></radio-group>\n" +
  "  <radio wx:elif=\"{{node.kind === 'radio'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" value=\"{{node.props.value}}\" checked=\"{{node.props.checked}}\" disabled=\"{{node.props.disabled}}\" color=\"{{node.props.color}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></radio>\n" +
  "  <picker wx:elif=\"{{node.kind === 'picker'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" mode=\"{{node.props.mode}}\" model:value=\"{{node.props.value}}\" range=\"{{node.props.range}}\" disabled=\"{{node.props.disabled}}\" data-minimoon-change=\"{{node.events.change}}\" bind:change=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></picker>\n" +
  "  <swiper wx:elif=\"{{node.kind === 'swiper'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" current=\"{{node.props.current}}\" autoplay=\"{{node.props.autoplay}}\" circular=\"{{node.props.circular}}\" interval=\"{{node.props.interval}}\" duration=\"{{node.props.duration}}\" data-minimoon-change=\"{{node.events.change}}\" bindchange=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></swiper>\n" +
  "  <swiper-item wx:elif=\"{{node.kind === 'swiper-item'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" item-id=\"{{node.props.itemId}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></swiper-item>\n" +
  "  <navigator wx:elif=\"{{node.kind === 'navigator'}}\" id=\"{{node.props.id}}\" class='{{node.props.className}}' style=\"{{node.props.style}}\" url=\"{{node.props.url}}\" open-type=\"{{node.props.openType}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child}}\" /></block></navigator>\n" +
  "</template>\n"
}

///|
pub fn dynamic_page_wxml(
  page_id : String,
  templates_src? : String = "../../minimoon.templates.wxml",
) -> String {
  "<import src=\"" +
  templates_src +
  "\" />\n" +
  "<template is=\"minimoon_dynamic_node\" data=\"{{node: " +
  page_id +
  ".tree}}\" />\n"
}
