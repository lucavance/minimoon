# Roadmap

## 0.1.0 first non-prerelease release

The complete current implementation is the `0.1.0` public baseline:

- Elm-style state machines, callable `Emit`, transactional `Val` composition,
  and page-owned effects and subscriptions;
- App Contract v7, runtime ABI v10, renderer protocol v7, CommonJS output, and
  Skyline Page Definition API registration;
- normalized tree testing plus optional headless and styled component
  packages;
- one two-page starter and one maintained four-page Conformance fixture;
- deterministic coverage, API, generator, host, performance, archive, and CI
  gates.

The public repository keeps only reproducible candidate state in
[`verify_report.json`](../examples/miniapp_conformance_app/generated/verify_report.json)
and
[`release_summary.json`](../examples/miniapp_conformance_app/generated/release_summary.json),
while fingerprint-bound
[`devtools.evidence.json`](../examples/miniapp_conformance_app/generated/devtools.evidence.json)
is local and Git-ignored. Local release verification does not publish its
timestamp, tool version, notes, or outcome in the repository.

## 0.1.1 starter maintenance

The `0.1.1` patch keeps the 0.1 public API and generated host protocols
unchanged while making a fresh `minimoon init` formatter-stable under the
supported MoonBit toolchain. It also expresses JavaScript runtime compatibility
as Node `>=24.11.0` rather than an exact local-version file. Generator and CI
gates enforce both properties.

## 0.1.x maintenance

1. Treat the exact gate-passing 0.1.0 archive as the immutable registry baseline.
2. Drive API additions from sustained application dogfooding rather than
   expanding the public surface speculatively.
3. Extend the Conformance fixture before adding another release fixture.
4. Revalidate generated-byte changes in the real WeChat host.

## Next iteration: RUI-inspired MiniApp components

The dependency refresh and
[Rabbita 0.15.6 / RUI 0.1.1 audit](reference/rabbita_and_rui_audit.md) establish
the next component iteration. The current change schedules this work and
does not add components. The audit maps all 64 RUI showcase entries; six have
existing optional-component counterparts, while other entries include native
substitutes, style recipes, reusable behavior gaps, and browser-only designs.

Evaluate and implement in this order, using concrete application cases to
bound each batch:

1. Field/form feedback and Alert Dialog: shared labels/help/errors, typed native
   control integration, explicit confirmation/cancellation, and dismissal policy.
2. Progress/Slider and Combobox/Searchable Select: establish required host
   controls, events, and semantics before adding reusable behavior.
3. Message Scroller with message layout recipes, then custom Toast/Sonner:
   scroll retention, new-message feedback, and scope-owned notification cleanup.

Calendar/ranges, Attachment, Input OTP, Pagination, Data Table, navigation/
Sidebar, Drawer, and Toggle/Toggle Group remain subsequent candidates. Pure
style recipes enter the package only when dogfooding demonstrates shared
behavior. Browser hover, context menus, portals/collision engines, desktop
resizing, and SSR are outside this component iteration.

Before implementation, record the application scenario, native alternative,
remaining behavior, provenance/license choice, and API compatibility impact.
Keep existing optional APIs and theme contracts compatible; any new root
control, semantic variant, or protocol field needs a separately planned
versioned change because the 0.1.x root API is locked.

Completion requires native/JS semantic behavior tests, controlled/self-owned
and reactive-slot coverage where applicable, keyed/hide/dispose ownership
checks, API/generator/size gates, and the affected Conformance scenarios.
Revalidate changed artifacts in WeChat Developer Tools before a release claim.

## Deferred

- ESM output; CommonJS remains the verified host boundary.
- Additional render targets.
- Backend-owned payment completion.
- Broad example expansion without independent verification value.
