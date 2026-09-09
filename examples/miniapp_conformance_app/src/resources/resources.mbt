///|
/// Original fixture presentation and icons; no third-party visual assets.
pub fn resources(features : Array[String]) -> @build_resources.ResourceBundle {
  guard features.is_empty() else {
    abort("conformance resources have no features")
  }
  {
    id: "minimoon-conformance",
    version: "0.2.0",
    wxss: stylesheet(),
    assets: tab_icons(),
  }
}

///|
fn stylesheet() -> String {
  let css =
    #|page{background:#203B63;color:#182438;font-size:30rpx;line-height:1.6}.demo-screen{position:relative;background:#F4F6FA;color:#182438;box-sizing:border-box;overflow:hidden}.demo-nav{position:absolute;top:0;left:0;right:0;box-sizing:border-box;background:#203B63;color:#fff;display:flex;align-items:flex-end;padding:0 40rpx 12px;z-index:20}.demo-nav-title{font-size:30rpx;font-weight:600;line-height:28px;white-space:nowrap}.demo-scroll{position:absolute;left:0;right:0;box-sizing:border-box;background:#F4F6FA}.demo-hero{min-height:128rpx;padding:16rpx 40rpx 40rpx;border-radius:0 0 50% 50% / 0 0 32rpx 32rpx;box-sizing:border-box;background:#203B63;color:#fff;display:flex;flex-direction:column;justify-content:center}.demo-hero-home{min-height:192rpx}.demo-title{font-size:56rpx;font-weight:700;line-height:1.15;margin:0}.demo-hero-note{font-size:30rpx;line-height:1.4;opacity:.8;margin-top:8rpx}.demo-body{padding:32rpx 40rpx 40rpx;display:flex;flex-direction:column;gap:32rpx;box-sizing:border-box}.demo-card{background:#fff;border-radius:24rpx;padding:32rpx;box-sizing:border-box;min-width:0;display:flex;flex-direction:column;gap:20rpx}.demo-card-title{font-size:32rpx;font-weight:600;line-height:1.4;margin:0}.demo-muted{color:#6A778B;font-size:30rpx}.demo-actions{display:flex;flex-wrap:wrap;align-items:center;gap:16rpx}.demo-action{margin:0;padding:18rpx 24rpx;background:#356AE6;color:#fff;border-radius:16rpx;font-size:30rpx;font-weight:500;line-height:1.4;min-height:44px;box-sizing:border-box}.demo-action:after,.demo-note-toggle:after{border:0}.demo-secondary{background:#EAF0FB;color:#203B63}.demo-value{font-size:64rpx;font-weight:700;color:#356AE6;line-height:1.2}.demo-input{background:#F4F6FA;border-radius:16rpx;padding:20rpx 24rpx;box-sizing:border-box;font-size:30rpx}.demo-output{font-size:30rpx;white-space:pre-wrap;word-break:break-all;overflow-wrap:anywhere;min-width:0}.demo-notes{border-top:1px solid #E4E9F1}.demo-note-toggle{min-height:44px;margin:0;padding:20rpx 0;background:transparent;color:#6A778B;font-size:30rpx;line-height:1.4;text-align:left}.demo-note-content{color:#6A778B;font-size:28rpx;line-height:1.6}.demo-probe{padding:24rpx;border:1px solid #E4E9F1;border-radius:16rpx}.demo-stack{display:flex;flex-direction:column;gap:20rpx}
  css
}
