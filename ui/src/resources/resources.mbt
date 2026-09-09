///|
/// Build-time Vega adaptation; source RUI b1291945 (MIT). No browser runtime.
pub fn features() -> Array[String] {
  [
    "accordion", "alert", "alert-dialog", "aspect-ratio", "attachment", "avatar",
    "badge", "breadcrumb", "bubble", "button", "button-group", "calendar", "card",
    "carousel", "chart", "checkbox", "collapsible", "combobox", "command", "context-menu",
    "data-table", "date-picker", "dialog", "direction", "drawer", "dropdown-menu",
    "empty", "field", "hover-card", "input", "input-group", "input-otp", "item",
    "kbd", "label", "marker", "menubar", "message", "message-scroller", "native-select",
    "navigation-menu", "pagination", "popover", "progress", "radio-group", "resizable",
    "scroll-area", "select", "separator", "sheet", "sidebar", "skeleton", "slider",
    "sonner", "spinner", "switch", "table", "tabs", "textarea", "toast", "toggle",
    "toggle-group", "tooltip", "typography", "form", "theme",
  ]
}

///|
fn base_rules() -> String {
  let rules =
    #|.mmui-theme{box-sizing:border-box;font-family:Arial,sans-serif;font-size:14px;line-height:1.5;color:var(--mmui-foreground);background:var(--mmui-background);--mmui-background:#ffffff;--mmui-foreground:#171717;--mmui-primary:#262626;--mmui-primary-foreground:#fafafa;--mmui-muted:#f5f5f5;--mmui-muted-foreground:#737373;--mmui-border:#e5e5e5;--mmui-destructive:#dc2626;--mmui-radius:10px}
    #|.mmui-light{--mmui-background:#ffffff;--mmui-foreground:#171717;--mmui-primary:#262626;--mmui-primary-foreground:#fafafa;--mmui-muted:#f5f5f5;--mmui-muted-foreground:#737373;--mmui-border:#e5e5e5;--mmui-destructive:#dc2626}
    #|.mmui-dark{--mmui-background:#171717;--mmui-foreground:#fafafa;--mmui-primary:#e5e5e5;--mmui-primary-foreground:#262626;--mmui-muted:#262626;--mmui-muted-foreground:#a3a3a3;--mmui-border:#404040;--mmui-destructive:#f87171}
    #|.mmui-ltr{direction:ltr}.mmui-rtl{direction:rtl}.mmui-horizontal{display:flex;flex-direction:row;align-items:center}.mmui-vertical{display:flex;flex-direction:column}.mmui-start{align-self:flex-start}.mmui-center{align-self:center}.mmui-end{align-self:flex-end}.mmui-disabled{opacity:0.5}.mmui-selected{background:var(--mmui-muted)}.mmui-outline{border:1px solid var(--mmui-border)}.mmui-secondary{background:var(--mmui-muted);color:var(--mmui-foreground)}.mmui-destructive{color:var(--mmui-destructive)}.mmui-small{font-size:12px}.mmui-large{font-size:18px}
    #|.mmui-vega-v1{box-sizing:border-box;font-size:14px;line-height:1.5}.mmui-medium{font-size:14px}.mmui-direction{min-width:0}
  rules
}

///|
fn foundation_rules() -> String {
  let rules =
    #|.mmui-button{display:inline-flex;align-items:center;justify-content:center;gap:8px;margin:0;padding:0 16px;min-height:36px;font-size:14px;line-height:1.25;font-weight:500;border:1px solid transparent;border-radius:8px;background:var(--mmui-primary);color:var(--mmui-primary-foreground)}.mmui-button:after{border:none}.mmui-button[disabled]{opacity:0.5}.mmui-button-outline{border-color:var(--mmui-border);background:var(--mmui-background);color:var(--mmui-foreground)}.mmui-button-secondary{background:var(--mmui-muted);color:var(--mmui-foreground)}.mmui-button-ghost,.mmui-button-link{background:transparent;color:var(--mmui-foreground)}.mmui-button-destructive{background:var(--mmui-destructive);color:#fff}.mmui-button-link{text-decoration:underline}.mmui-button-xs{min-height:24px;padding:0 8px;font-size:12px}.mmui-button-sm{min-height:32px;padding:0 12px}.mmui-button-lg{min-height:40px;padding:0 24px}.mmui-button-icon{width:36px;height:36px;padding:0}.mmui-button-icon-xs{width:24px;min-height:24px;padding:0}.mmui-button-icon-sm{width:32px;min-height:32px;padding:0}.mmui-button-icon-lg{width:40px;min-height:40px;padding:0}
    #|.mmui-button-group,.mmui-button-group-text,.mmui-breadcrumb-list,.mmui-item-actions,.mmui-kbd-group,.mmui-bubble-reactions{display:flex;align-items:center;gap:8px}.mmui-button-group.mmui-vertical{align-items:stretch}.mmui-alert,.mmui-card,.mmui-item,.mmui-empty{border:1px solid var(--mmui-border);border-radius:var(--mmui-radius);padding:16px;background:var(--mmui-background)}.mmui-alert-title,.mmui-card-title,.mmui-empty-title,.mmui-item-title{font-weight:600}.mmui-alert-description,.mmui-card-description,.mmui-empty-description,.mmui-item-description,.mmui-message-footer{color:var(--mmui-muted-foreground);font-size:13px}.mmui-card{display:flex;flex-direction:column;gap:16px}.mmui-card-header,.mmui-empty-header{display:flex;flex-direction:column;gap:6px}.mmui-card-footer,.mmui-item-footer,.mmui-item-header,.mmui-message-header{display:flex;align-items:center;gap:8px}.mmui-card.mmui-small{padding:12px;gap:12px}.mmui-card.mmui-large{padding:24px;gap:24px}.mmui-card-action,.mmui-alert-action{align-self:flex-end}
    #|.mmui-aspect-ratio-content{position:absolute;top:0;right:0;bottom:0;left:0}.mmui-avatar{position:relative;display:flex;flex-shrink:0;align-items:center;justify-content:center;width:40px;height:40px;border-radius:9999px;overflow:hidden;background:var(--mmui-muted)}.mmui-avatar.mmui-small{width:28px;height:28px}.mmui-avatar.mmui-large{width:56px;height:56px}.mmui-avatar-image,.mmui-avatar-fallback{width:100%;height:100%}.mmui-avatar-fallback{display:flex;align-items:center;justify-content:center;font-weight:500}.mmui-avatar-badge{position:absolute;bottom:0;right:0;width:10px;height:10px;border-radius:9999px;background:var(--mmui-primary)}.mmui-avatar-group{display:flex}.mmui-avatar-group-count{border-radius:9999px;padding:4px;background:var(--mmui-muted)}
    #|.mmui-badge,.mmui-marker{display:inline-flex;align-items:center;gap:4px;border:1px solid transparent;border-radius:6px;padding:2px 8px;font-size:12px;font-weight:500}.mmui-badge.mmui-default{background:var(--mmui-primary);color:var(--mmui-primary-foreground)}.mmui-badge.mmui-outline,.mmui-marker.mmui-outline{border-color:var(--mmui-border)}.mmui-breadcrumb{font-size:13px;color:var(--mmui-muted-foreground)}.mmui-breadcrumb-page{color:var(--mmui-foreground)}.mmui-breadcrumb-separator{padding:0 4px}.mmui-bubble-group,.mmui-message-group{display:flex;flex-direction:column;gap:8px}.mmui-bubble{max-width:85%;border-radius:12px;padding:10px 14px}.mmui-bubble-content{white-space:pre-wrap}.mmui-message{display:flex;gap:10px;max-width:100%}.mmui-message-content{display:flex;flex-direction:column;gap:6px;flex:1;min-width:0}.mmui-message-avatar{flex-shrink:0}.mmui-item{display:flex;gap:12px;align-items:center}.mmui-item-content{display:flex;flex-direction:column;gap:4px;flex:1;min-width:0}.mmui-item-group{display:flex;flex-direction:column;gap:8px}.mmui-item-media{flex-shrink:0}.mmui-empty{display:flex;flex-direction:column;align-items:center;justify-content:center;gap:16px;padding:32px;text-align:center;border-style:dashed}.mmui-empty-content{max-width:320px}.mmui-empty-media{padding:12px;border-radius:12px;background:var(--mmui-muted)}
    #|.mmui-kbd{display:inline-flex;align-items:center;justify-content:center;min-width:20px;height:20px;padding:0 4px;border-radius:4px;background:var(--mmui-muted);font-size:11px;font-family:monospace}.mmui-label{font-size:14px;font-weight:500}.mmui-required{color:var(--mmui-destructive)}.mmui-separator{flex-shrink:0;background:var(--mmui-border)}.mmui-separator.mmui-horizontal{height:1px;width:100%}.mmui-separator.mmui-vertical{width:1px;min-height:20px;align-self:stretch}.mmui-skeleton{background:var(--mmui-muted);border-radius:6px}.mmui-spinner{display:inline-flex;align-items:center;justify-content:center;width:24px;height:24px;font-size:24px}.mmui-spinner.mmui-small{width:16px;height:16px;font-size:16px}.mmui-spinner.mmui-large{width:32px;height:32px;font-size:32px}
    #|.mmui-typography-h1{font-size:32px;line-height:1.2;font-weight:700}.mmui-typography-h2{font-size:26px;line-height:1.25;font-weight:600}.mmui-typography-h3{font-size:22px;font-weight:600}.mmui-typography-h4{font-size:18px;font-weight:600}.mmui-typography-p{line-height:1.75}.mmui-typography-blockquote{border-left:2px solid var(--mmui-border);padding-left:16px;font-style:italic}.mmui-typography-list{display:flex;flex-direction:column;gap:6px;padding-left:24px}.mmui-typography-inline-code{font-family:monospace;background:var(--mmui-muted);padding:2px 4px;border-radius:4px}.mmui-typography-lead{font-size:20px;color:var(--mmui-muted-foreground)}.mmui-typography-large{font-size:18px;font-weight:600}.mmui-typography-small{font-size:12px}.mmui-typography-muted{color:var(--mmui-muted-foreground)}
    #|.mmui-muted{background:var(--mmui-muted);color:var(--mmui-foreground)}.mmui-tinted{background:#e8e8ed;color:var(--mmui-foreground)}.mmui-dark .mmui-tinted{background:#35353d}.mmui-ghost{background:transparent}.mmui-bubble.mmui-ghost{padding:0;border-radius:0;max-width:100%}.mmui-bubble.mmui-default{background:var(--mmui-primary);color:var(--mmui-primary-foreground)}.mmui-bubble.mmui-outline{border:1px solid var(--mmui-border)}.mmui-marker{display:flex;width:100%;padding:0;border-radius:0;color:var(--mmui-muted-foreground)}.mmui-marker .mmui-separator{flex:1}.mmui-marker-border{border:1px solid var(--mmui-border);padding:8px;border-radius:6px}.mmui-media-plain{background:transparent;padding:0}.mmui-media-icon{width:36px;height:36px;display:flex;align-items:center;justify-content:center;border:1px solid var(--mmui-border);border-radius:8px}.mmui-media-image{width:40px;height:40px;overflow:hidden;border-radius:8px}.mmui-spinner{animation:mmui-spin 1s linear infinite}.mmui-skeleton{animation:mmui-pulse 2s ease-in-out infinite}@keyframes mmui-spin{0%{transform:rotate(0deg)}100%{transform:rotate(360deg)}}@keyframes mmui-pulse{0%{opacity:1}50%{opacity:0.5}100%{opacity:1}}
    #|.mmui-breadcrumb-item{display:flex;align-items:center}.mmui-button-default{background:var(--mmui-primary);color:var(--mmui-primary-foreground)}.mmui-card-content{min-width:0}.mmui-marker-content{min-width:0;flex-shrink:0}.mmui-marker-icon{display:flex;align-items:center;flex-shrink:0}
    #|.mmui-reactions-top{order:-1}.mmui-reactions-bottom{order:1}.mmui-link{background:transparent;text-decoration:underline}.mmui-accordion,.mmui-collapsible{display:flex;flex-direction:column}.mmui-accordion-trigger,.mmui-collapsible-trigger{display:flex;align-items:center;justify-content:space-between;min-height:44px;background:transparent;color:var(--mmui-foreground)}.mmui-accordion-panel,.mmui-tab-panel,.mmui-collapsible-content{padding:12px 0}.mmui-tabs-line{border-bottom:1px solid var(--mmui-border);background:transparent}.mmui-tabs-default{padding:4px;border-radius:8px;background:var(--mmui-muted)}.mmui-tab-list.mmui-vertical{align-items:stretch}.mmui-tab{display:flex;align-items:center;justify-content:center;gap:6px;min-height:36px;font-size:14px}
  rules
}

///|
fn form_rules() -> String {
  let rules =
    #|.mmui-input,.mmui-textarea,.mmui-native-select,.mmui-select-trigger{box-sizing:border-box;width:100%;min-height:36px;padding:8px 12px;border:1px solid var(--mmui-border);border-radius:8px;background:var(--mmui-background);color:var(--mmui-foreground);font-size:14px}.mmui-textarea{min-height:80px}.mmui-field,.mmui-form,.mmui-field-group,.mmui-field-set{display:flex;flex-direction:column;gap:12px}.mmui-field.mmui-horizontal{flex-direction:row}.mmui-field-label,.mmui-field-legend,.mmui-field-title{font-weight:500}.mmui-field-description,.mmui-form-description{font-size:13px;color:var(--mmui-muted-foreground)}.mmui-field-error,.mmui-form-message{font-size:13px;color:var(--mmui-destructive)}.mmui-field-content{flex:1;min-width:0}.mmui-input-group{display:flex;align-items:center;gap:8px;border:1px solid var(--mmui-border);border-radius:8px;padding:0 8px}.mmui-input-group-addon{flex-shrink:0;color:var(--mmui-muted-foreground)}.mmui-input-group-control{flex:1;min-width:0}.mmui-input-group-text{font-size:13px;color:var(--mmui-muted-foreground)}
    #|.mmui-checkbox{position:relative;display:flex;align-items:center;gap:8px}.mmui-checkbox-mixed{position:absolute;left:6px;top:0;pointer-events:none}.mmui-radio-group{gap:10px}.mmui-radio-group-item{font-size:14px}.mmui-toggle-group{display:flex;gap:4px}.mmui-toggle{margin:0;padding:8px 12px;min-height:36px;border-radius:6px;background:transparent;color:var(--mmui-foreground);font-size:14px;line-height:20px}.mmui-toggle:after{border:none}.mmui-toggle.mmui-selected{background:var(--mmui-muted)}.mmui-progress{width:100%}.mmui-progress-value,.mmui-progress-label{font-size:13px}.mmui-input-otp{position:relative;display:flex;gap:8px}.mmui-input-otp-native{position:absolute;top:0;left:0;width:100%;height:100%;opacity:0.01;z-index:1}.mmui-input-otp-group{display:flex}.mmui-input-otp-slot{display:flex;align-items:center;justify-content:center;width:40px;height:44px;border:1px solid var(--mmui-border);font-size:18px;font-family:monospace}.mmui-input-otp-slot.mmui-active{border-color:var(--mmui-primary)}.mmui-input-otp-separator{padding:0 8px;line-height:44px}
    #|.mmui-select{position:relative}.mmui-select-panel{background:var(--mmui-background);border:1px solid var(--mmui-border);border-radius:8px;padding:4px;max-height:320px}.mmui-select-item{display:flex;justify-content:space-between;padding:10px 12px;border-radius:4px}.mmui-select-item.mmui-selected{background:var(--mmui-muted)}.mmui-select-label{padding:6px 12px;font-weight:500;font-size:12px}.mmui-slider{position:relative;min-height:44px;display:flex;align-items:center}.mmui-slider-track{position:relative;width:100%;height:6px;background:var(--mmui-muted);border-radius:999px}.mmui-slider-range{position:absolute;height:6px;background:var(--mmui-primary);border-radius:999px}.mmui-slider-thumb{position:absolute;top:50%;width:20px;height:20px;margin-top:-10px;margin-left:-10px;border-radius:999px;border:2px solid var(--mmui-primary);background:var(--mmui-background)}.mmui-slider.mmui-vertical{width:44px;height:200px;justify-content:center}.mmui-slider.mmui-vertical .mmui-slider-track{width:6px;height:100%}.mmui-slider.mmui-vertical .mmui-slider-range{width:6px;height:auto}.mmui-slider.mmui-vertical .mmui-slider-thumb{left:50%;top:auto;margin-top:0;margin-bottom:-10px}
    #|.mmui-input-group{flex-wrap:wrap}.mmui-addon-inline-start{order:-1}.mmui-addon-inline-end{order:1}.mmui-addon-block-start{order:-2;width:100%;padding-top:8px}.mmui-addon-block-end{order:2;width:100%;padding-bottom:8px}.mmui-input-otp[aria-invalid=true]{border-color:var(--mmui-destructive)}
    #|.mmui-slider-native{width:100%;min-height:44px}.mmui-switch{display:inline-flex;align-items:center}.mmui-toggle.mmui-selected,.mmui-select-item.mmui-selected{color:var(--mmui-foreground)}.mmui-focused{border-color:var(--mmui-primary)}.mmui-invalid{border-color:var(--mmui-destructive)}.mmui-readonly{opacity:1;color:var(--mmui-foreground)}.mmui-switch.mmui-small{transform:scale(0.8)}
  rules
}

///|
pub fn resources(requested : Array[String]) -> @build_resources.ResourceBundle {
  let all = features()
  let selected : Map[String, Bool] = Map([])
  let input = if requested.is_empty() { all } else { requested }
  for name in input {
    guard all.contains(name) else {
      abort("unknown minimoon_ui resource feature: " + name)
    }
    selected[name] = true
  }
  selected["theme"] = true
  // Resolve a deterministic transitive closure before selecting CSS groups.
  let dependencies : Array[(String, Array[String])] = [
    ("command", ["input", "scroll-area"]),
    ("combobox", ["command", "popover"]),
    ("select", ["popover", "scroll-area"]),
    ("date-picker", ["calendar", "popover"]),
    ("data-table", ["table", "pagination", "checkbox", "input"]),
    ("input-group", ["input", "textarea"]),
    ("input-otp", ["input"]),
    ("form", ["field", "label"]),
    ("field", ["label"]),
    ("sonner", ["toast"]),
    ("attachment", ["item"]),
    ("hover-card", ["popover"]),
    ("tooltip", ["popover"]),
    ("context-menu", ["popover"]),
    ("dropdown-menu", ["popover"]),
    ("menubar", ["dropdown-menu"]),
    ("navigation-menu", ["popover"]),
    ("drawer", ["dialog"]),
    ("alert-dialog", ["dialog"]),
    ("sidebar", ["sheet", "scroll-area"]),
    ("message-scroller", ["scroll-area"]),
  ]
  let mut changed = true
  while changed {
    changed = false
    for dependency in dependencies {
      if selected.contains(dependency.0) {
        for name in dependency.1 {
          if !selected.contains(name) {
            selected[name] = true
            changed = true
          }
        }
      }
    }
  }
  // Compound components transitively depend on native buttons, icons and labels.
  if selected.contains("input-group") {
    selected["input"] = true
    selected["textarea"] = true
  }
  if selected.contains("form") {
    selected["field"] = true
    selected["label"] = true
  }
  if selected.contains("input-otp") {
    selected["input"] = true
  }
  if selected.contains("date-picker") {
    selected["calendar"] = true
    selected["popover"] = true
  }
  if selected.contains("combobox") {
    selected["command"] = true
    selected["popover"] = true
  }
  if selected.contains("data-table") {
    selected["table"] = true
    selected["pagination"] = true
    selected["checkbox"] = true
  }
  if selected.contains("sonner") {
    selected["toast"] = true
  }
  if selected.contains("attachment") {
    selected["item"] = true
  }
  selected["button"] = true
  selected["separator"] = true
  let manifest = all.filter(name => selected.contains(name)).join("\n") + "\n"
  let assets : Array[@build_resources.ResourceAsset] = [
    {
      path: "assets/mmui/features.txt",
      content: @build_resources.Text(manifest),
    },
  ]
  for mode in ["light", "dark"] {
    let color = if mode == "light" { "#171717" } else { "#fafafa" }
    for
      icon in [
        ("check", "M5 12l4 4L19 6"),
        ("chevron-down", "M6 9l6 6 6-6"),
        ("close", "M6 6l12 12M18 6L6 18"),
      ] {
      assets.push({
        path: "assets/mmui/" + icon.0 + "-" + mode + ".svg",
        content: @build_resources.Text(
          "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"24\" height=\"24\" viewBox=\"0 0 24 24\"><path d=\"" +
          icon.1 +
          "\" fill=\"none\" stroke=\"" +
          color +
          "\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\"/></svg>",
        ),
      })
    }
  }
  let form_names = [
    "checkbox", "field", "form", "input", "input-group", "input-otp", "native-select",
    "progress", "radio-group", "select", "slider", "switch", "textarea", "toggle",
    "toggle-group",
  ]
  let css = base_rules() +
    "\n" +
    foundation_rules() +
    (if form_names.any(name => selected.contains(name)) {
      "\n" + form_rules()
    } else {
      ""
    }) +
    "\n" +
    extra_rules() +
    "\n" +
    attachment_rules()
  { id: "lampclaw/minimoon_ui/vega-v1", version: "0.1.0", wxss: css, assets, }
}
