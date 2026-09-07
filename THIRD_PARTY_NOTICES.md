# Third-party notices

Minimoon contains adapted source from
[moonbit-community/rabbita](https://github.com/moonbit-community/rabbita),
version 0.13.1 at commit `6392a57a1401257adaa1eb74fc44397a21daaa04`.

The adapted implementation is located in `src/internal_duplix/` and
`src/internal_slotmap/`. Minimoon changed it to add page-owned root scopes,
transactional branch/cache rollback, reversible subscription visibility, and
the framework-specific `Val` integration.

`src/internal_any/` adapts Rabbita's private erased-value wrapper as reviewed at
commit `b6cbf52902574f56895c218a43ee072dbf758f39`. Minimoon uses it only behind
generation-checked, page-owned state-message stores.

Rabbita is licensed under the Apache License 2.0. A copy of that license is
included in this repository as `LICENSE`.

## Review-only references

The [Rabbita/RUI audit](docs/reference/rabbita_and_rui_audit.md) compares the
current implementation with Rabbita 0.15.6 and RUI 0.1.1 at commit
`b1291945fd0201a0b5b39513b88585d6122db7bc`. These are comparison points, not
new source attribution pins or package dependencies.

RUI is separately MIT-licensed. Its notices also credit shadcn/ui Vega and
React DayPicker. This audit and dependency update copy no RUI implementation
or upstream visual recipes; any future adaptation must preserve the applicable
notices and record its exact source revision.

## Development tooling

Generated JavaScript validation uses
[Acorn](https://github.com/acornjs/acorn) 8.18.0 under the MIT License and
[`eslint-scope`](https://github.com/eslint/js/tree/main/packages/eslint-scope)
9.1.2 under the BSD 2-Clause License. They are development-only dependencies
and are not linked into generated MiniApp artifacts.
