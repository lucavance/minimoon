const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "platform", minimoonInitialTree(5), ["wx.navigateBack","wx.switchTab","wx.login","wx.getStorage","wx.setStorage","wx.request","wx.showToast","wx.getLocation","wx.chooseMedia"])
