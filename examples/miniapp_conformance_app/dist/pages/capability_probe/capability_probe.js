const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "capability_probe", minimoonInitialTree(4), ["wx.login","wx.getStorage","wx.setStorage","wx.request","wx.showToast","wx.getLocation","wx.chooseMedia","wx.navigateTo","wx.redirectTo","wx.navigateBack","wx.switchTab"])
