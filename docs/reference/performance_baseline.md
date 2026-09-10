# Performance and artifact budgets

Run-specific timings belong in ignored `_build/perf/` reports. Fixture status
and fingerprints belong in generated reports. This document owns deterministic
ceilings and their byte calibration, not transient benchmark samples.

## Release layout and byte ceilings

Each application has one runtime, one host, one protocol/COW helper, one compact
initial-tree module, one shared recursive WXML file, one global WXSS file, and
small indexed page registration/template stubs. An opted-in application also
has a `minimoon.app.js` entry helper.

| Artifact | Ceiling |
| --- | ---: |
| Draft Workbench application runtime | 440,000 bytes |
| generated starter runtime | 230,000 bytes |
| App-enabled shared host | 19,000 bytes |
| no-App shared host (including starter) | 18,000 bytes |
| shared protocol | 10,000 bytes |
| compact initial trees | 41,000 bytes |
| each page JavaScript bridge | 2,048 bytes |
| shared `minimoon.templates.wxml` | 20,000 bytes |
| global `app.wxss` | 9,500 bytes |
| each page WXML | 1,024 bytes |
| each page WXSS | exactly 0 bytes |

Aggregate JavaScript includes `app.js`, runtime, host, protocol, initial trees,
all page bridges, and `minimoon.app.js` when application ownership is enabled:

| Application | Ceiling |
| --- | ---: |
| committed Draft Workbench fixture | 480,000 bytes |
| generated starter | 258,000 bytes |

Release generation minifies the host and runtime syntax. For historical
comparison, the earlier 2026-09-08 authoring calibration used
`moon 0.1.20260907`, `moonc v0.10.12`, Node
24.20.0, and Bun 1.4.2. Its Conformance release measures 387,977 runtime bytes,
15,624 host bytes, 9,492 protocol bytes, 303 initial-tree bytes, and 418,121
aggregate JavaScript bytes, including the 3,464-byte application helper.
Against that review's ceilings, headroom was respectively 12,023, 376, 508,
40,697, and 34,879 bytes.

## Approved Draft Workbench example budget review

The 2026-09-10 review changes only the maintained core example's fixed runtime
and aggregate JavaScript ceilings. The comparison baseline is commit `bf02050`,
whose former Conformance example contains 399,716 runtime bytes and 433,364
aggregate JavaScript bytes. It leaves just 284 runtime bytes below the former
400,000-byte ceiling.

The renamed nine-route Draft Workbench adds local draft CRUD, validated and
versioned persistence, one App-owned editing buffer, typed public HTTP echo,
and page/App request-lifecycle demonstrations. The obsolete shared echo domain
and duplicate panels were removed; the capability laboratories retain their
technical regression coverage. No framework runtime or public API change is
required at that checkpoint. An isolated consumer of Registry core `0.2.0`
produced the same artifact fingerprint as that workspace build. The later
unpublished shared-host input fix is not part of this historical parity claim.

Calibration uses `moon 0.1.20260907`, `moonc v0.10.12+1634b282e`, Node 24.21.0,
and Bun 1.4.2:

| Measure | Baseline bytes | Reviewed bytes | Increase | Fixed ceiling | Headroom |
| --- | ---: | ---: | ---: | ---: | ---: |
| Example runtime | 399,716 | 427,143 | 27,427 | 440,000 | 12,857 |
| Aggregate JavaScript | 433,364 | 461,392 | 28,028 | 480,000 | 18,608 |

The user explicitly approved these two ceilings after the old budget rejected
the implementation. This is an example-scope adjustment, not a framework
release or automatic budget scaling. Core/UI archive limits and allowlists,
Starter limits, shared-host/protocol/initial-tree/WXML/WXSS limits, coverage,
scheduler and timing gates remain unchanged. Core/UI versions remain
`0.2.0`/`0.1.0`. Exactly one byte above either ceiling still fails through the
inclusive-boundary tests in `budgets_wbtest.mbt`. New example artifacts require
fresh WeChat host acceptance; automated checks do not provide that evidence.

## Approved native navigation and layout budget review

This historical review preceded the example-only ceilings above.

The 2026-09-08 independent review compares committed `12c0e8a` with the native
TabBar, page-layout and binary-resource implementation. The committed baseline
was extracted into an isolated directory and repackaged with local
`moon 0.1.20260907` and `moonc v0.10.12+1634b282e`, using frozen dependencies.
This avoids ancestor package exclusions and does not alter the working checkout.

The no-App/App shared hosts grow from 14,976/15,624 to 17,501/18,276 bytes.
Their approved fixed ceilings are 18,000/19,000 bytes, leaving 499/724 bytes.
The common 2,525-byte increase covers synchronous layout sampling and
validation, ordered Load/Show/Resize updates, and Tab route/capability guards.
The Conformance host adds another 127 bytes for its four Tab route literals.
No general-purpose JavaScript runtime or application business logic is added
to the shared host.

The baseline core ZIP measures 288,689 bytes and the reviewed pre-documentation
candidate measures 304,861 bytes: an increase of 16,172 bytes. The compressed
entry ledger attributes that increase as follows:

| Source | Compressed-byte increase |
| --- | ---: |
| Build/verify tooling and PNG validation | 5,610 |
| Documentation and metadata | 4,742 |
| Framework and public API | 2,932 |
| Host templates | 1,237 |
| Public testing harness | 257 |
| ZIP directory overhead | 1,394 |
| Total | 16,172 |

The archive grows from 154 to 164 entries. Inspection found no fixture, UI,
PNG/SVG asset, generated application, test/benchmark or repository-validator
payload. The public testing harness is intentionally packaged; its test files
are not. The implementation explicitly registers the framework's `internal_png`
package and native-navigation guide in the allowlist. The budget adjustment
itself does not expand the allowlist or change package exclusions.

The approved core hard ceiling is 320 KiB (327,680 bytes), with the existing
8 KiB (8,192-byte) reserve and a 319,488-byte operating ceiling. The reviewed
sample leaves 14,627 operating bytes. These fixed repository budgets do not
auto-scale and are not registry service limits. The final archive is measured
again after documentation changes; the values above record the original audit.

The final local candidate calibration, after the disk-host Tab verifier,
documentation updates and layout optimization, measures 308,037 core ZIP bytes
(19,348 above `12c0e8a`), leaving 11,451 bytes below the operating ceiling.
Conformance measures 396,064 runtime bytes, 429,904 aggregate JavaScript bytes
and 7,456 WXSS bytes. Its unchanged runtime/aggregate ceilings retain
3,936/23,096 bytes of headroom. UI's independently packaged archive measures
115,320 bytes; no UI archive threshold changes.

At that review, Conformance runtime/aggregate ceilings remained
400,000/453,000 bytes. Protocol, initial-tree, WXML/WXSS, UI archive, coverage, scheduler and timing ceilings
are unchanged. The no-App host ceiling also applies to the starter; its
runtime/aggregate ceilings receive the separate follow-up review below.
One byte over any applicable ceiling still fails.
Constants and inclusive-boundary tests remain in
[`budgets.mbt`](../../src/cmd/minimoon_check/budgets.mbt) and its white-box tests.

### Independent starter follow-up review

The native navigation/layout review also checks the generated starter
independently, without linking PNG tooling or UI into its runtime and without
adding an opt-in switch. Its measured release sizes are:

| Stage | Runtime bytes | Aggregate JavaScript bytes |
| --- | ---: | ---: |
| Committed baseline | 218,755 | 243,991 |
| Initial native navigation/layout implementation | 227,161 | 254,922 |
| After minimal graph optimization | 226,205 | 253,966 |

Reusing the graph input and removing unnecessary `Option` boxing recovers
956 runtime bytes, also reducing aggregate JavaScript by 956 bytes. The net
increase over the baseline is 7,450 runtime bytes and 9,975 aggregate bytes:
the additional 2,525 bytes are the shared host increase; other JavaScript
artifacts are unchanged. This is framework layout/navigation support, not
accidental PNG or UI linkage.

The independently approved fixed starter runtime/aggregate ceilings are
230,000/258,000 bytes, replacing 220,000/247,000 and leaving 3,795/4,034 bytes
of measured headroom. This follow-up supersedes the initial review's intent
to leave starter runtime/aggregate ceilings unchanged. It does not change any
other ceiling or auto-scale with future builds. Both constants and their exact
inclusive-boundary tests are centralized in `budgets.mbt` and its white-box
tests; generator failures report the measured size and applicable limit.

## Approved authoring budget review

This historical review preceded the native navigation and layout ceilings above.

The comparison baseline is commit `7a57802`: runtime 373,090 bytes, aggregate
JavaScript 442,997 bytes, and core archive 272,346 bytes. Real-input creation,
App-aware testing, typed HTTP and the migrated fixtures add 14,887 runtime
bytes while empty host boot trees reduce aggregate JavaScript by 24,876 bytes.
The approved fixed runtime ceiling was 400,000 bytes; the aggregate ceiling
remained 453,000 bytes. Shared cleanup kept no-App/App host bytes at
14,976/15,624, within the then-unchanged 15,000/16,000-byte ceilings.

The pre-review core archive was 288,166 bytes, up 15,820 bytes. The then-approved
core hard ceiling was 300 KiB (307,200 bytes), retaining the 8 KiB reserve;
the operating ceiling was 299,008 bytes. The calibration sample left 10,842
operating bytes, but the archive gate remeasures after documentation changes.
UI retains its independent 250 KiB hard ceiling, 16 KiB reserve and
239,616-byte operating ceiling; its isolated package measures 115,296 bytes.
These are repository budgets, not registry service limits.

No aggregate-JavaScript, starter, host, protocol, UI, coverage, scheduler or
timing gate was relaxed by that authoring review. Package allowlists and
exclusions were unchanged. The constants and inclusive one-byte boundary tests live
in [`budgets.mbt`](../../src/cmd/minimoon_check/budgets.mbt) and its white-box
tests; further increases require another explicit review.

## Approved application-state budget review

This historical review preceded the authoring ceilings above. Its
calibration used `moon 0.1.20260827` / `moonc v0.10.11` and measured 373,090
runtime bytes, 15,499 App host bytes, 40,204 initial-tree bytes and 442,997
aggregate JavaScript bytes. The then-current 383,000-byte runtime ceiling
left 9,910 bytes of runtime headroom.

The comparison baseline is HTTP commit `561641b`: runtime 350,209 bytes,
host 14,818 bytes, aggregate JavaScript 414,673 bytes, and core archive
246,536 bytes. Optional App ownership adds 22,881 runtime bytes, 681 host bytes
and 28,324 aggregate bytes, including the bounded-drain continuation fix. The
new fixed runtime/aggregate ceilings increase
by 23,000/29,000 bytes, retaining roughly the previous absolute headroom.
Only the App-enabled host receives a 16,000-byte ceiling; no-App output measures
14,851 bytes and keeps the 15,000-byte ceiling used by the starter.

The pre-review core archive was 268,650 bytes, up 22,114 bytes. The then-approved
core hard ceiling was 280 KiB (286,720 bytes), with the existing 8 KiB reserve;
the operating ceiling was 278,528 bytes. UI retained its independent 250 KiB hard
ceiling, 16 KiB reserve and 239,616-byte operating ceiling. These are repository
budgets, not registry service limits. Final archives are measured after all
documentation changes rather than pinned to these calibration samples.

No package allowlist, package exclusion, coverage threshold, scheduler bound,
timing check, starter ceiling or UI archive ceiling is relaxed. UI runtime and
aggregate sizes are observations, not additional byte gates introduced here.
The constants, host-mode selection and inclusive-boundary tests live in
[`budgets.mbt`](../../src/cmd/minimoon_check/budgets.mbt) and its white-box tests.
A one-byte overrun still fails; subsequent increases require another review.

## Approved HTTP budget review

This historical review preceded the application-state ceilings above.

The pre-HTTP baseline is committed `01acb76`, not the older pre-UI calibration.
Its runtime is 334,158 bytes and aggregate JavaScript is 397,590 bytes. Typed
request encoding/validation and ten Home scenarios add 16,051 runtime bytes and
17,083 aggregate bytes. The reviewed runtime ceiling moves from 344,000 to
360,000 and the aggregate ceiling from 406,000 to 424,000: these increases
retain approximately the previous absolute headroom. They do not auto-scale
with future builds. The shared host/protocol delta is 621 bytes. UI runtime
stays at 524,530 bytes; its aggregate only grows by those shared 621 bytes,
from 684,480 to 685,101. UI archive and generated-starter ceilings were unchanged.

Both module archives then retained the repository's 250 KiB hard ceiling.
Core's required reserve changed from 16 KiB to 8 KiB, giving an operating
ceiling of 247,808 bytes (242 KiB); UI retained its 16 KiB reserve and
239,616-byte ceiling.
The pre-review HTTP archive measured 244,875 bytes before this documentation
update, above the old 239,616-byte operating ceiling. The gate measures the
final archive again, including documentation. No allowlist, package exclusion,
coverage threshold, scheduler bound or timing check is relaxed.

```bash
minimoon check --suite perf
```

## Maintained benchmarks

MoonBit JavaScript release benchmarks cover 100, 500, and 2,000 nodes for
bounded scope ownership, scalar/keyed diff, event lookup, no-op dispatch,
creation/mount, retained normalization, and indexed LIS work. A generated host
benchmark compares valid small-patch application with a full-clone reference.

The generated host benchmark takes the median of 25 samples after warmup. A
scalar patch must copy exactly three path containers and beat the full-clone
reference by at least 1.10x at 100 nodes and 1.50x at 500 and 2,000 nodes. These
are work-shape regressions with broad runtime margin, not a general device FPS
claim.

Timing remains diagnostic because runner noise makes wall-clock CI thresholds
unstable. Deterministic gates cover work counters, cache visits, bounded scopes,
generated syntax, scheduler limits, and artifact bytes.

## Runtime/host interpretation

`__minimoonRendererStats()` exposes patch/replacement counts, host writes,
`setData`, acknowledged commits, fallbacks, received/coalesced events, event
batches, maximum batch/queue depth, acknowledgement samples/total/max/last
latency, async drains, scheduler warnings/failures, retries, timeouts, and
shadow copies. Use
these counters with Developer Tools profiling.

The host suite also performs 1,000 mount/dispatch/dispose cycles under Bun with
forced GC. `_build/perf/scheduler_heap.json` reports heap delta and retained
runtime states, timers, and intervals; all resource counts must be zero and the
heap delta has a 16 MiB safety ceiling. This catches deterministic retention but
does not prove physical-device heap stability or real-host correctness.
