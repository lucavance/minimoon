const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "ui_layout", minimoonInitialTree(4), ["wx.navigateTo","wx.redirectTo","minimoon.measureNodes"])
