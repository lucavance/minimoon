///|
/// Synchronous, page-owned host facts. No callbacks, listeners or device globals.
fn host_layout_reader() -> String {
  (
    #|function readMinimoonLayout(previous) {
    #|  const result = previous ? JSON.parse(JSON.stringify(previous)) : { window: null, menu_button: null }
    #|  const number = value => typeof value === "number" && Number.isFinite(value) && value >= 0 && value <= 1000000
    #|  const rect = value => value && typeof value === "object" && !Array.isArray(value) && number(value.left) && number(value.top) && number(value.width) && value.width > 0 && number(value.height) && value.height > 0 ? { left: value.left, top: value.top, width: value.width, height: value.height } : null
    #|  const fits = (value, window) => !value || !window || (value.left + value.width <= window.screen_width && value.top + value.height <= window.screen_height)
    #|  if (typeof wx !== "undefined" && typeof wx.getWindowInfo === "function") {
    #|    try {
    #|      const raw = wx.getWindowInfo()
    #|      if (raw && [raw.windowWidth, raw.windowHeight, raw.screenWidth, raw.screenHeight, raw.screenTop, raw.statusBarHeight].every(number) && raw.windowWidth > 0 && raw.windowHeight > 0 && raw.screenWidth >= raw.windowWidth && raw.screenHeight >= raw.windowHeight && raw.screenTop + raw.windowHeight <= raw.screenHeight && raw.statusBarHeight <= raw.screenHeight) {
    #|        const window = { window_width: raw.windowWidth, window_height: raw.windowHeight, screen_width: raw.screenWidth, screen_height: raw.screenHeight, screen_top: raw.screenTop, status_bar_height: raw.statusBarHeight, safe_area: rect(raw.safeArea) }
    #|        if (!window.safe_area || !fits(window.safe_area, window)) window.safe_area = result.window && fits(result.window.safe_area, window) ? result.window.safe_area : null
    #|        result.window = window
    #|      }
    #|    } catch (_) {}
    #|  }
    #|  if (typeof wx !== "undefined" && typeof wx.getMenuButtonBoundingClientRect === "function") {
    #|    try {
    #|      const menu = rect(wx.getMenuButtonBoundingClientRect())
    #|      if (menu && fits(menu, result.window)) result.menu_button = menu
    #|    } catch (_) {}
    #|  }
    #|  if (!fits(result.menu_button, result.window)) result.menu_button = null
    #|  return result
    #|}
  )
}
