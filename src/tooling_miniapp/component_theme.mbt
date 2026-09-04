///|
pub fn component_theme_css(theme : String) -> String {
  match theme {
    "" => ""
    "minimal-v1" =>
      (
        #|.mm-disclosure,.mm-accordion,.mm-tabs{box-sizing:border-box;color:#172033;font-size:28rpx}
        #|.mm-disclosure,.mm-accordion__item,.mm-tabs__panel{border:1rpx solid #d9e2f0;border-radius:16rpx;background:#fff}
        #|.mm-disclosure__trigger,.mm-accordion__trigger,.mm-tabs__tab{box-sizing:border-box;margin:0;padding:20rpx 24rpx;border:0;border-radius:0;background:transparent;color:inherit;font:inherit;line-height:1.4;text-align:left}
        #|.mm-disclosure__trigger,.mm-accordion__trigger{display:flex;width:100%;font-weight:600}
        #|.mm-disclosure__panel,.mm-accordion__panel,.mm-tabs__panel{padding:20rpx 24rpx;line-height:1.6}
        #|.mm-accordion__item{margin-top:12rpx;overflow:hidden}
        #|.mm-accordion__item:first-child{margin-top:0}
        #|.mm-tabs__list{display:flex;gap:8rpx;margin-bottom:12rpx}
        #|.mm-tabs__tab{border-radius:12rpx;color:#52647a}
        #|.mm-tabs__tab--active{background:#e8f1ff;color:#1456b8;font-weight:600}
        #|.mm-tabs__tab--inactive{background:#f5f7fa}
        #|.mm-disclosure__trigger[disabled],.mm-accordion__trigger[disabled],.mm-tabs__tab[disabled]{opacity:.45}
        #|
      )
    "minimal-v2" =>
      component_theme_css("minimal-v1") +
      (
        #|.mm-dialog,.mm-dialog__trigger,.mm-dialog__title,.mm-dialog__description,.mm-dialog__close,.mm-sheet,.mm-sheet__trigger,.mm-sheet__title,.mm-sheet__description,.mm-sheet__close,.mm-dropdown__trigger,.mm-dropdown__item,.mm-dropdown__label,.mm-dropdown__submenu-trigger{box-sizing:border-box}
        #|.mm-overlay,.mm-dismiss{position:fixed;z-index:40;top:0;right:0;bottom:0;left:0;background:rgba(15,23,42,.42)}
        #|.mm-dismiss{z-index:20;background:transparent}
        #|.mm-dialog__surface,.mm-sheet__surface{position:fixed;z-index:41;padding:32rpx;background:#fff}
        #|.mm-dialog__surface{top:50%;left:50%;width:calc(100% - 80rpx);transform:translate(-50%,-50%)}
        #|.sheet--right{top:0;right:0;bottom:0;width:86%}
        #|.sheet--left{top:0;bottom:0;left:0;width:86%}
        #|.sheet--top{top:0;right:0;left:0;max-height:86%}
        #|.sheet--bottom{right:0;bottom:0;left:0;max-height:86%}
        #|.mm-dropdown{position:relative}
        #|.mm-dropdown__content,.mm-dropdown__submenu-content{position:absolute;z-index:21;border:1rpx solid #d9e2f0;background:#fff}
        #|.dropdown--bottom-start{top:100%;left:0}.dropdown--bottom-end{top:100%;right:0}.dropdown--top-start{bottom:100%;left:0}.dropdown--top-end{right:0;bottom:100%}
        #|.mm-dropdown__separator{height:1rpx;background:#d9e2f0}
        #|.mm-dropdown__submenu-content{position:relative}
        #|
      )
    _ => abort("unsupported component theme: " + theme)
  }
}

///|
fn theme_hash(css : String) -> String {
  let mut hash = 1469598103934665603UL
  for char in css {
    hash = (hash ^ char.to_int().to_uint64()) * 1099511628211UL
  }
  "fnv1a64-v1:" + hash.to_string(radix=16)
}

///|
pub fn component_theme_manifest(theme : String) -> Json {
  if theme == "" {
    return Json::null()
  }
  let css = component_theme_css(theme)
  Json::object({
    "id": Json::string(theme),
    "version": Json::string(if theme == "minimal-v2" { "2" } else { "1" }),
    "hash": Json::string(theme_hash(css)),
    "bytes": Json::number(
      @utf8.encode(css).length().to_double(),
      repr=@utf8.encode(css).length().to_string(),
    ),
  })
}
