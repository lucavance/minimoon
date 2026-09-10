# MiniApp fixture matrix

## Core release fixture

| Fixture | Page | Primary contract |
| --- | --- | --- |
| `miniapp_draft_workbench` | Workbench / 工作台 | draft count, current buffer, new/resume and saved-list navigation |
| `miniapp_draft_workbench` | Drafts / 草稿 | persisted records, edit/delete and storage feedback |
| `miniapp_draft_workbench` | Online / 联机 | App-owned typed echo, errors, retry and stale-response isolation |
| `miniapp_draft_workbench` | More / 更多 | scoped data reset, instructions and laboratory entries |
| `miniapp_draft_workbench` | Draft Editor | required mode/id input, manual save, shared buffer and page-owned trial |
| `miniapp_draft_workbench` | Interaction | native controls, local components and core component catalogue |
| `miniapp_draft_workbench` | Platform | ten public HTTP cases and independent wx capabilities |
| `miniapp_draft_workbench` | Request Lifecycle | technical shared counter, App/page delayed requests and navigation |
| `miniapp_draft_workbench` | Runtime Lab | keyed focus, reconciliation, async, disposal and instance isolation |

The nine routes share one App runtime, release build and artifact fingerprint.
Only the first four are native Tabs. All page factories take `Deps`; App owns
business data and the editor buffer, while pages own their local request effects.
Hide/Show retains state; actual unload disposes page-owned work.
The example was formerly named `miniapp_conformance_app`; there is no duplicate fixture.
See the [workbench guide](https://github.com/lucavance/minimoon/blob/main/examples/miniapp_draft_workbench/README.md) for the three complete workflows.

## Independent UI fixture

[`ui/examples/showcase`](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md)
is the separate six-page release fixture for `lampclaw/minimoon_ui 0.1.0`
with core `0.2.0`. It covers 64 RUI families plus Form and Theme: foundation,
overlay/disclosure, forms, data/date, layout/navigation and feedback behavior.
Its native/JS tests, generated resource checks, candidate report, artifact
fingerprint and local host evidence are independent of Draft Workbench. Both
fixtures must pass when the shared core host or UI release is changed; one
application's evidence cannot authorize the other.
The UI fixture keeps the no-application entry path and no-argument factories;
like the core fixture, its source configuration requires schema `11`.

## Initializer template

`templates/starter` is the only embedded `minimoon init` template. It has Home
and Details pages and demonstrates the normal application model without
conformance-only capabilities. It is generated and built in a temporary app by
the generator suite; it is not a second committed release fixture.
The initializer emits current schema `11` and a core dependency, without an
implicit `application` entry or UI dependency.

The fixture and generated starter must pass:

- warning-free JS-target compilation and tests
- App Contract v11 / runtime ABI v13 / renderer protocol v8 validation
- one application-wide runtime/shared host pair with page-aware dispatch
- deterministic release generation and embedded-template drift checks
- generated JavaScript parsing and Page Definition API registration
- hydration, event batching, render acknowledgement/retry, lifecycle,
  capability, subscription, snapshot, disposal, navigation, scroll, and
  instance-isolation host smoke
- Platform generated-host smoke for exact login/storage/request/toast/location/media
  payloads and successes, failed login, unavailable location, exactly-once
  request abort on unload, and ignored late success
- coalesced async drain, timeout cancellation, exact keyed-move focus, and
  same-identity scalar-only controlled-reset probes
- release fingerprint/report validation and fixed artifact budgets

```bash
minimoon check --suite codegen
minimoon check --suite generator
minimoon check --suite host
minimoon check --suite release
minimoon check --suite perf
```

Add coverage to an existing conformance page whenever practical. A new
committed example requires a contract that cannot be validated meaningfully in
the existing application and must justify the extra real-host release burden.
