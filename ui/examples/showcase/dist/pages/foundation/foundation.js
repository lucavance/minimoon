const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "ui_foundation", minimoonInitialTree(0), ["wx.navigateTo","wx.redirectTo","minimoon.measureNodes"])
