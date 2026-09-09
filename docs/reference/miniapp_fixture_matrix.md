# MiniApp fixture matrix

## Core release fixture

| Fixture | Page | Primary contract |
| --- | --- | --- |
| `miniapp_conformance_app` | Showcase / 首页 | landing UI, local count/reset, lifecycle and three SwitchTab shortcuts |
| `miniapp_conformance_app` | Interaction / 交互 | native controls, local components, Disclosure/Accordion/Tabs and overlays/menu semantics |
| `miniapp_conformance_app` | Platform / 平台 | independently mounted public HTTP and host-capability scenarios |
| `miniapp_conformance_app` | Application / 应用 | application count, request and draft projections; local versus App ownership |
| `miniapp_conformance_app` | Request Lifecycle | optional marker, page/App delayed request ownership, hide versus unload, NavigateTo/RedirectTo and Back |
| `miniapp_conformance_app` | Runtime Lab | set/splice/keyed move/full replacement, keyed focus, scalar-only reset, controlled reconciliation, no-touch async, scrolling, local component disposal and same-route isolation |
| `miniapp_conformance_app` | Draft Editor | required input, validation/typed echo, minimal shared observer, folded lifecycle notes and stack-aware Back |

The seven routes share one application-wide runtime, one release build, one
verification report, and one real-host artifact fingerprint. Real pages are
the primary navigation structure. Swiper is deliberately kept inside Lab as a
control test rather than used as a substitute for routing; its ordinary usage lives in Interaction.
The configured `src/app` owns typed domains, not presentation. Application alone
provides the complete controller; Draft Editor observes count/request and Request
Lifecycle has minimal App-request controls. All seven page factories take
the application's `Deps`. App HTTP survives page unload, and Clear invalidates
an obsolete response through a business epoch.

The first four routes are native bottom tabs; Request Lifecycle, Runtime Lab and Draft Editor
are non-tab routes. Tab switching causes Hide/Show and preserves local state;
it cannot substitute for RedirectTo, true Unload or two instances of Runtime Lab. Top
layout uses synchronous window/safe-area/capsule metrics before the first
business tree, with resize and Show entering the existing transaction queue.

## Independent UI fixture

[`ui/examples/showcase`](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md)
is the separate six-page release fixture for `lampclaw/minimoon_ui 0.1.0`
with core `0.2.0`. It covers 64 RUI families plus Form and Theme: foundation,
overlay/disclosure, forms, data/date, layout/navigation and feedback behavior.
Its native/JS tests, generated resource checks, candidate report, artifact
fingerprint and local host evidence are independent of Conformance. Both
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
