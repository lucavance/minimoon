const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "request_lifecycle", minimoonInitialTree(6), ["wx.request","wx.navigateTo","wx.redirectTo","wx.navigateBack","wx.switchTab"])
