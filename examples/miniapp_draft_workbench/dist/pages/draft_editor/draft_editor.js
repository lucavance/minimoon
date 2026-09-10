const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "draft_editor", minimoonInitialTree(8), ["wx.navigateBack","wx.switchTab","wx.request"])
