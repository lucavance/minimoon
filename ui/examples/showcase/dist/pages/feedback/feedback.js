const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "ui_feedback", minimoonInitialTree(5), ["wx.navigateTo","wx.redirectTo","minimoon.measureNodes"])
