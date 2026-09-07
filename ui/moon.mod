name = "lampclaw/minimoon_ui"

version = "0.1.0"

import {
  "lampclaw/minimoon@0.2.0",
}

readme = "README.mbt.md"

repository = "https://github.com/lucavance/minimoon"

license = "MIT"

description = "Native, touch-first Skyline components for Minimoon, adapted from RUI."

keywords = [ "minimoon", "miniapp", "skyline", "components", "rui" ]

source = "src"

preferred_target = "js"

options(
  exclude: [ "examples", "docs", "**/*_test.mbt", "**/*_wbtest.mbt" ],
)
