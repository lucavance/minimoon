const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "lab", minimoonInitialTree(5), ["wx.navigateBack","wx.switchTab"])
