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
| Conformance application runtime | 400,000 bytes |
| generated starter runtime | 220,000 bytes |
| App-enabled shared host | 16,000 bytes |
| no-App shared host (including starter) | 15,000 bytes |
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
| committed Conformance fixture | 453,000 bytes |
| generated starter | 247,000 bytes |

Release generation minifies the host and runtime syntax. The 2026-09-08
authoring calibration uses `moon 0.1.20260907`, `moonc v0.10.12`, Node
24.20.0, and Bun 1.4.2. Its Conformance release measures 387,977 runtime bytes,
15,624 host bytes, 9,492 protocol bytes, 303 initial-tree bytes, and 418,121
aggregate JavaScript bytes, including the 3,464-byte application helper.
Remaining headroom is respectively 12,023, 376, 508, 40,697, and 34,879 bytes.

## Approved authoring budget review

The comparison baseline is commit `7a57802`: runtime 373,090 bytes, aggregate
JavaScript 442,997 bytes, and core archive 272,346 bytes. Real-input creation,
App-aware testing, typed HTTP and the migrated fixtures add 14,887 runtime
bytes while empty host boot trees reduce aggregate JavaScript by 24,876 bytes.
The approved fixed runtime ceiling is 400,000 bytes; the aggregate ceiling
remains 453,000 bytes. Shared cleanup keeps no-App/App host bytes at
14,976/15,624, within the unchanged 15,000/16,000-byte ceilings.

The pre-review core archive is 288,166 bytes, up 15,820 bytes. The approved
core hard ceiling is 300 KiB (307,200 bytes), retaining the 8 KiB reserve;
the operating ceiling is 299,008 bytes. The calibration sample leaves 10,842
operating bytes, but the archive gate remeasures after documentation changes.
UI retains its independent 250 KiB hard ceiling, 16 KiB reserve and
239,616-byte operating ceiling; its isolated package measures 115,296 bytes.
These are repository budgets, not registry service limits.

No aggregate-JavaScript, starter, host, protocol, UI, coverage, scheduler or
timing gate is relaxed. Package allowlists and exclusions are unchanged by
this budget review. The constants and inclusive one-byte boundary tests live
in [`budgets.mbt`](../../src/cmd/minimoon_check/budgets.mbt) and its white-box
tests; further increases require another explicit review.

## Approved application-state budget review

This historical review preceded the current authoring ceilings above. Its
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
