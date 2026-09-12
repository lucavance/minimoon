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

The optional `src/http/` authoring facade follows Rabbita's request-builder API
as reviewed at `eccae7507360aec8465469bafb7fb4da5b260a2a` (2026-09-08,
Rabbita 0.15.6 source). It delegates to Minimoon's declared `wx.request`
capability instead of importing the browser HTTP implementation. The Apache-2.0
license above applies; this source reference is not a package dependency.

The historical [Rabbita/RUI audit](https://github.com/lucavance/minimoon/blob/main/docs/reference/rabbita_and_rui_audit.md)
compared Minimoon 0.1.1 with Rabbita 0.15.6 and RUI 0.1.1 at commit
`b1291945fd0201a0b5b39513b88585d6122db7bc`. Its
[2026-09-12 follow-up](https://github.com/lucavance/minimoon/blob/main/docs/reference/rabbita_and_rui_audit.md#2026-09-12-follow-up)
reviews upstream `0a5836a3d303b7390d7067894ba8471cbd4ffcdf` against Minimoon
`052d7af`. These review points do not replace the original source attribution
pins or introduce package dependencies.

RUI is separately MIT-licensed. Its notices also credit shadcn/ui Vega and
React DayPicker. The original audit and this follow-up copy no upstream
implementation or visual recipes. The independent UI adaptation records its
source pins and retained notices in [UI provenance](https://github.com/lucavance/minimoon/blob/main/ui/THIRD_PARTY_NOTICES.md).
Future adaptations must preserve the applicable notices and record their exact
source revisions.

## Development tooling

Generated JavaScript validation uses
[Acorn](https://github.com/acornjs/acorn) 8.18.0 under the MIT License and
[`eslint-scope`](https://github.com/eslint/js/tree/main/packages/eslint-scope)
9.1.2 under the BSD 2-Clause License. They are development-only dependencies
and are not linked into generated MiniApp artifacts.
