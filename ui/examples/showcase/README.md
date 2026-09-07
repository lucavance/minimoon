# Minimoon UI showcase

This six-page verification application exercises `lampclaw/minimoon_ui 0.1.0`
with core `lampclaw/minimoon 0.2.0`. It covers all 64 pinned RUI families plus
Form and Theme, with native substitutions described in the
[migration map](../../docs/migration.md).

From the repository root:

```bash
bun run minimoon build ui/examples/showcase --mode release
bun run minimoon verify ui/examples/showcase --candidate
```

Import the unchanged `dist/` into WeChat Developer Tools. The generated
`smoke_checklist.json` includes every application-specific check declared in
`miniapp.minimoon.json`. Validate all six pages in the Skyline simulator,
physical-device preview and device debugging, with ES6 transformation, enhanced
compilation and minification enabled and an online minimum base library of
3.17.0 or newer.

The CI artifact `minimoon-ui-devtools-<commit>` is independent of the core
`minimoon-devtools-<commit>` artifact. Check both file and ZIP hashes before
import. Follow the
[validation runbook](../../../docs/operations/miniapp_devtools_validation.md)
and [release handoff](../../../docs/operations/release_candidate_handoff.md).

Candidate reports deliberately leave real-host validation pending. The UI
showcase owns its own ignored, fingerprint-bound evidence; never substitute
the core Conformance application's evidence. A verification command rebuilds
artifacts, so confirm the fingerprint remains the exact one tested and repeat
host acceptance if it changes.
