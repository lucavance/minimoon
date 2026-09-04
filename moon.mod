name = "lampclaw/minimoon"

version = "0.1.0"

import {
  "moonbitlang/async@0.21.2",
  "moonbitlang/x@0.5.1",
}

readme = "README.mbt.md"

repository = "https://github.com/lucavance/minimoon"

license = "Apache-2.0"

keywords = [
  "moonbit",
  "elm-architecture",
  "tea",
  "host-runtime",
  "host-commands",
  "component-state",
  "miniapp",
  "skyline",
  "incremental-graph",
  "ui-runtime",
]

description = "A MoonBit UI runtime for WeChat MiniApp Skyline with Elm-style state machines, Val-based UI composition, transactional local state, and generated MiniApp host commands."

source = "src"

preferred_target = "js"

options(
  exclude: [
    ".github",
    ".githooks",
    ".node-version",
    "AGENTS.md",
    "README.zh-CN.mbt.md",
    "bun.lock",
    "docs/code-analysis",
    "docs/project_status.md",
    "docs/reference/performance_baseline.md",
    "examples",
    "moon.work",
    "package.json",
    "scripts",
    "templates",
    "top_wbtest.mbt",
    "src/cmd/minimoon_check",
    "src/cmd/minimoon_metrics",
    "src/cmd/minimoon_docs",
    "src/cmd/minimoon_template_generate",
    "src/internal_host_validation",
    "src/internal_components_behavior_test",
    "src/internal_component_styles_behavior_test",
    "**/*_bench.mbt",
    "**/*_test.mbt",
    "**/*_wbtest.mbt",
  ],
)
