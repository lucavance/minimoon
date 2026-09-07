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
              kind == "switch" ||
              kind == "slider" ||
              kind == "progress"
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
  // Short template-local aliases preserve every binding and avoid duplicating
  // long property paths in each native tag. The normalized wire tree is unchanged.
  let semantics = " aria-role=\"{{p.role}}\" aria-expanded=\"{{p.ariaExpanded}}\" aria-selected=\"{{p.ariaSelected}}\" aria-disabled=\"{{p.ariaDisabled}}\" aria-hidden=\"{{p.ariaHidden}}\" aria-checked=\"{{p.ariaChecked}}\" aria-modal=\"{{p.ariaModal}}\" aria-controls=\"{{p.ariaControls}}\" aria-labelledby=\"{{p.ariaLabelledBy}}\" aria-describedby=\"{{p.ariaDescribedBy}}\" aria-orientation=\"{{p.ariaOrientation}}\" aria-haspopup=\"{{p.ariaHasPopup}}\" aria-required=\"{{p.ariaRequired}}\" aria-invalid=\"{{p.ariaInvalid}}\" aria-busy=\"{{p.ariaBusy}}\" aria-live=\"{{p.ariaLive}}\" aria-valuemin=\"{{p.ariaValueMin}}\" aria-valuemax=\"{{p.ariaValueMax}}\" aria-valuenow=\"{{p.ariaValueNow}}\" aria-valuetext=\"{{p.ariaValueText}}\""
  "<template name=\"minimoon_dynamic_node\">\n" +
  "  <block wx:if=\"{{node.kind === 'empty'}}\"></block>\n" +
  "  <block wx:elif=\"{{node.kind === 'fragment'}}\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\">\n" +
  "      <template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" />\n" +
  "    </block>\n" +
  "  </block>\n" +
  "  <text wx:elif=\"{{node.kind === 'text'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{p.section}}\" data-minimoon-tap=\"{{e.tap}}\" bindtap=\"__mmDispatchTap\">{{node.text}}</text>\n" +
  "  <view wx:elif=\"{{node.kind === 'view' && p.catchMove}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-longpress=\"{{e.longpress}}\" data-minimoon-touchstart=\"{{e.touchstart}}\" data-minimoon-touchmove=\"{{e.touchmove}}\" data-minimoon-touchend=\"{{e.touchend}}\" data-minimoon-touchcancel=\"{{e.touchcancel}}\" bindlongpress=\"__mmDispatchLongPress\" bindtouchstart=\"__mmDispatchTouchStart\" catchtouchmove=\"__mmDispatchTouchMove\" bindtouchend=\"__mmDispatchTouchEnd\" bindtouchcancel=\"__mmDispatchTouchCancel\" data-minimoon-section=\"{{p.section}}\" data-minimoon-tap=\"{{e.tap}}\" bindtap=\"__mmDispatchTap\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block>\n" +
  "  </view>\n" +
  "  <view wx:elif=\"{{node.kind === 'view'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-longpress=\"{{e.longpress}}\" data-minimoon-touchstart=\"{{e.touchstart}}\" data-minimoon-touchmove=\"{{e.touchmove}}\" data-minimoon-touchend=\"{{e.touchend}}\" data-minimoon-touchcancel=\"{{e.touchcancel}}\" bindlongpress=\"__mmDispatchLongPress\" bindtouchstart=\"__mmDispatchTouchStart\" bindtouchmove=\"__mmDispatchTouchMove\" bindtouchend=\"__mmDispatchTouchEnd\" bindtouchcancel=\"__mmDispatchTouchCancel\" data-minimoon-section=\"{{p.section}}\" data-minimoon-tap=\"{{e.tap}}\" bindtap=\"__mmDispatchTap\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block>\n" +
  "  </view>\n" +
  "  <button wx:elif=\"{{node.kind === 'button'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" disabled=\"{{p.disabled}}\" name=\"{{p.name}}\" form-type=\"{{p.formType}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{p.section}}\" data-minimoon-tap=\"{{e.tap}}\" catchtap=\"__mmDispatchTap\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block>\n" +
  "  </button>\n" +
  "  <input wx:elif=\"{{node.kind === 'input'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" type=\"{{p.type || 'text'}}\" name=\"{{p.name}}\" password=\"{{p.password}}\" maxlength=\"{{p.maxlength == null ? 140 : p.maxlength}}\" selection-start=\"{{p.selectionStart == null ? -1 : p.selectionStart}}\" selection-end=\"{{p.selectionEnd == null ? -1 : p.selectionEnd}}\" value=\"{{p.value}}\" placeholder=\"{{p.placeholder}}\" disabled=\"{{p.disabled}}\" focus=\"{{p.focus}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{p.section}}\" data-minimoon-input=\"{{e.input}}\" data-minimoon-confirm=\"{{e.confirm}}\" data-minimoon-focus=\"{{e.focus}}\" data-minimoon-blur=\"{{e.blur}}\" bindinput=\"__mmDispatchInput\" bindconfirm=\"__mmDispatchConfirm\" bindfocus=\"__mmDispatchFocus\" bindblur=\"__mmDispatchBlur\" />\n" +
  "  <image wx:elif=\"{{node.kind === 'image'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" src=\"{{p.src}}\" mode=\"{{p.mode || 'scaleToFill'}}\" aria-label=\"{{p.ariaLabel || p.alt}}\"" +
  semantics +
  " data-minimoon-section=\"{{p.section}}\" data-minimoon-tap=\"{{e.tap}}\" bindtap=\"__mmDispatchTap\" data-minimoon-load=\"{{e.load}}\" data-minimoon-error=\"{{e.error}}\" bindload=\"__mmDispatchLoad\" binderror=\"__mmDispatchError\" />\n" +
  "  <scroll-view wx:elif=\"{{node.kind === 'scroll-view'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" scroll-x=\"{{p.scrollX}}\" scroll-y=\"{{p.scrollY}}\" scroll-top=\"{{p.scrollTop}}\" scroll-left=\"{{p.scrollLeft}}\" scroll-into-view=\"{{p.scrollIntoView}}\" upper-threshold=\"{{p.upperThreshold}}\" lower-threshold=\"{{p.lowerThreshold}}\" data-minimoon-scroll=\"{{e.scroll}}\" data-minimoon-upper=\"{{e.upper}}\" data-minimoon-lower=\"{{e.lower}}\" bindscroll=\"__mmDispatchScroll\" bindscrolltoupper=\"__mmDispatchUpper\" bindscrolltolower=\"__mmDispatchLower\">\n" +
  "    <block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block>\n" +
  "  </scroll-view>\n" +
  "  <textarea wx:elif=\"{{node.kind === 'textarea'}}\" id=\"{{p.id}}\" name=\"{{p.name}}\" class='{{p.className}}' style=\"{{p.style}}\" model:value=\"{{p.value}}\" placeholder=\"{{p.placeholder}}\" maxlength=\"{{p.maxlength}}\" disabled=\"{{p.disabled}}\" focus=\"{{p.focus}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-section=\"{{p.section}}\" data-minimoon-input=\"{{e.input}}\" data-minimoon-confirm=\"{{e.confirm}}\" data-minimoon-focus=\"{{e.focus}}\" data-minimoon-blur=\"{{e.blur}}\" bind:input=\"__mmDispatchInput\" bind:confirm=\"__mmDispatchConfirm\" bind:focus=\"__mmDispatchFocus\" bind:blur=\"__mmDispatchBlur\"></textarea>\n" +
  "  <switch wx:elif=\"{{node.kind === 'switch'}}\" id=\"{{p.id}}\" name=\"{{p.name}}\" class='{{p.className}}' style=\"{{p.style}}\" checked=\"{{p.checked}}\" disabled=\"{{p.disabled}}\" color=\"{{p.color}}\" aria-label=\"{{p.ariaLabel}}\"" +
  semantics +
  " data-minimoon-change=\"{{e.change}}\" bindchange=\"__mmDispatchChange\" />\n" +
  "  <checkbox-group wx:elif=\"{{node.kind === 'checkbox-group'}}\" id=\"{{p.id}}\" name=\"{{p.name}}\" class='{{p.className}}' style=\"{{p.style}}\" data-minimoon-change=\"{{e.change}}\" bindchange=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></checkbox-group>\n" +
  "  <checkbox wx:elif=\"{{node.kind === 'checkbox'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" value=\"{{p.value}}\" checked=\"{{p.checked}}\" disabled=\"{{p.disabled}}\" color=\"{{p.color}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></checkbox>\n" +
  "  <radio-group wx:elif=\"{{node.kind === 'radio-group'}}\" id=\"{{p.id}}\" name=\"{{p.name}}\" class='{{p.className}}' style=\"{{p.style}}\" data-minimoon-change=\"{{e.change}}\" bindchange=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></radio-group>\n" +
  "  <radio wx:elif=\"{{node.kind === 'radio'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" value=\"{{p.value}}\" checked=\"{{p.checked}}\" disabled=\"{{p.disabled}}\" color=\"{{p.color}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></radio>\n" +
  "  <picker wx:elif=\"{{node.kind === 'picker'}}\" id=\"{{p.id}}\" name=\"{{p.name}}\" class='{{p.className}}' style=\"{{p.style}}\" mode=\"{{p.mode}}\" model:value=\"{{p.value}}\" range=\"{{p.range}}\" disabled=\"{{p.disabled}}\" data-minimoon-change=\"{{e.change}}\" bind:change=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></picker>\n" +
  "  <swiper wx:elif=\"{{node.kind === 'swiper'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" vertical=\"{{p.vertical}}\" current=\"{{p.current}}\" autoplay=\"{{p.autoplay}}\" circular=\"{{p.circular}}\" interval=\"{{p.interval}}\" duration=\"{{p.duration}}\" data-minimoon-change=\"{{e.change}}\" bindchange=\"__mmDispatchChange\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></swiper>\n" +
  "  <swiper-item wx:elif=\"{{node.kind === 'swiper-item'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" item-id=\"{{p.itemId}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></swiper-item>\n" +
  "  <navigator wx:elif=\"{{node.kind === 'navigator'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" url=\"{{p.url}}\" open-type=\"{{p.openType}}\"><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></navigator>\n" +
  "  <label wx:elif=\"{{node.kind === 'label'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\" for=\"{{p.for}}\"" +
  semantics +
  "><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></label>\n" +
  "  <form wx:elif=\"{{node.kind === 'form'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\" data-minimoon-submit=\"{{e.submit}}\" data-minimoon-reset=\"{{e.reset}}\" bindsubmit=\"__mmDispatchSubmit\" bindreset=\"__mmDispatchReset\"" +
  semantics +
  "><block wx:for=\"{{node.children}}\" wx:key=\"identity\" wx:for-item=\"child\"><template is=\"minimoon_dynamic_node\" data=\"{{node: child, p: child.props, e: child.events}}\" /></block></form>\n" +
  "  <slider wx:elif=\"{{node.kind === 'slider'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\" name=\"{{p.name}}\" value=\"{{p.value}}\" min=\"{{p.min}}\" max=\"{{p.max}}\" step=\"{{p.step}}\" disabled=\"{{p.disabled}}\" show-value=\"{{p.showValue}}\" activeColor=\"{{p.activeColor}}\" backgroundColor=\"{{p.backgroundColor}}\" block-color=\"{{p.blockColor}}\" block-size=\"{{p.blockSize}}\" data-minimoon-change=\"{{e.change}}\" data-minimoon-changing=\"{{e.changing}}\" bindchange=\"__mmDispatchChange\" bindchanging=\"__mmDispatchChanging\"" +
  semantics +
  " />\n" +
  "  <progress wx:elif=\"{{node.kind === 'progress'}}\" id=\"{{p.id}}\" class='{{p.className}}' style=\"{{p.style}}\" aria-label=\"{{p.ariaLabel}}\" percent=\"{{p.percent}}\" stroke-width=\"{{p.strokeWidth}}\" show-info=\"{{p.showInfo}}\" active=\"{{p.active}}\" activeColor=\"{{p.activeColor}}\" backgroundColor=\"{{p.backgroundColor}}\"" +
  semantics +
  " />\n" +
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
  ".tree, p: " +
  page_id +
  ".tree.props, e: " +
  page_id +
  ".tree.events}}\" />\n"
}
