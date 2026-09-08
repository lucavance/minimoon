const { registerMinimoonPage } = require("../../minimoon.host.js")
const { minimoonInitialTree } = require("../../minimoon.initial.js")
registerMinimoonPage(require("../../minimoon.runtime.js"), "ui_forms", minimoonInitialTree(2), ["wx.navigateTo","wx.redirectTo","minimoon.measureNodes","wx.request"])
