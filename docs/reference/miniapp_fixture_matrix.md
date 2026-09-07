# MiniApp fixture matrix

## Core release fixture

| Fixture | Page | Primary contract |
| --- | --- | --- |
| `miniapp_conformance_app` | Showcase | bilingual landing UI, state transitions, lifecycle, NavigateTo routing |
| `miniapp_conformance_app` | Home | query and controlled input, state transitions, exact capability payloads/results, request abort/late completion, lifecycle, NavigateTo/RedirectTo |
| `miniapp_conformance_app` | Lab | set/splice/keyed move/full replacement, keyed focus retention, scalar-only controlled reset, no-touch async completion, vertical scroll, `assoc_by`, local state/subscriptions, controls, focus events, overlays, menus, swiper, same-route isolation |
| `miniapp_conformance_app` | Details | independent query/lifecycle state and stack-aware back fallback |

The four routes share one application-wide runtime, one release build, one
verification report, and one real-host artifact fingerprint. Real pages are
the primary navigation structure. Swiper is deliberately kept inside Lab as a
control test rather than used as a substitute for routing.

## Independent UI fixture

[`ui/examples/showcase`](https://github.com/lucavance/minimoon/blob/main/ui/examples/showcase/README.md)
is the separate six-page release fixture for `lampclaw/minimoon_ui 0.1.0`
with core `0.2.0`. It covers 64 RUI families plus Form and Theme: foundation,
overlay/disclosure, forms, data/date, layout/navigation and feedback behavior.
Its native/JS tests, generated resource checks, candidate report, artifact
fingerprint and local host evidence are independent of Conformance. Both
fixtures must pass when the shared core host or UI release is changed; one
application's evidence cannot authorize the other.

## Initializer template

`templates/starter` is the only embedded `minimoon init` template. It has Home
and Details pages and demonstrates the normal application model without
conformance-only capabilities. It is generated and built in a temporary app by
the generator suite; it is not a second committed release fixture.

The fixture and generated starter must pass:

- warning-free JS-target compilation and tests
- App Contract v9 / runtime ABI v11 / renderer protocol v8 validation
- one application-wide runtime/shared host pair with page-aware dispatch
- deterministic release generation and embedded-template drift checks
- generated JavaScript parsing and Page Definition API registration
- hydration, event batching, render acknowledgement/retry, lifecycle,
  capability, subscription, snapshot, disposal, navigation, scroll, and
  instance-isolation host smoke
- Home generated-host smoke for exact login/storage/request/toast/location/media
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
