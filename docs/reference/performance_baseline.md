# Performance and artifact budgets

Run-specific timings belong in ignored `_build/perf/` reports. Fixture status
and fingerprints belong in generated reports. This document owns deterministic
ceilings and their byte calibration, not transient benchmark samples.

## Release layout and byte ceilings

Each application has one runtime, one host, one protocol/COW helper, one compact
initial-tree module, one shared recursive WXML file, one global WXSS file, and
small indexed page registration/template stubs.

| Artifact | Ceiling |
| --- | ---: |
| Conformance application runtime | 360,000 bytes |
| generated starter runtime | 220,000 bytes |
| shared host | 15,000 bytes |
| shared protocol | 10,000 bytes |
| compact initial trees | 41,000 bytes |
| each page JavaScript bridge | 2,048 bytes |
| shared `minimoon.templates.wxml` | 20,000 bytes |
| global `app.wxss` | 9,500 bytes |
| each page WXML | 1,024 bytes |
| each page WXSS | exactly 0 bytes |

Aggregate JavaScript includes `app.js`, runtime, host, protocol, initial trees,
and all page bridges:

| Application | Ceiling |
| --- | ---: |
| committed Conformance fixture | 424,000 bytes |
| generated starter | 247,000 bytes |

Release generation minifies the host and runtime syntax. The HTTP calibration
on 2026-09-07 uses `moon 0.1.20260827`, `moonc v0.10.11`, Node 24.20.0, and
Bun 1.4.2. Its Conformance release measures 350,209 runtime bytes, 14,818 host
bytes, 9,492 protocol bytes, 38,981 initial-tree bytes, and 414,673 aggregate
JavaScript bytes. Remaining headroom is respectively 9,791, 182, 508, 2,019,
and 9,327 bytes. Host remains the tightest proportional budget.

## Approved HTTP budget review

The pre-HTTP baseline is committed `01acb76`, not the older pre-UI calibration.
Its runtime is 334,158 bytes and aggregate JavaScript is 397,590 bytes. Typed
request encoding/validation and ten Home scenarios add 16,051 runtime bytes and
17,083 aggregate bytes. The reviewed runtime ceiling moves from 344,000 to
360,000 and the aggregate ceiling from 406,000 to 424,000: these increases
retain approximately the previous absolute headroom. They do not auto-scale
with future builds. The shared host/protocol delta is 621 bytes. UI runtime
stays at 524,530 bytes; its aggregate only grows by those shared 621 bytes,
from 684,480 to 685,101. UI and generated-starter ceilings are unchanged.

Both module archives retain the repository's 250 KiB hard ceiling. Core's
required reserve changes from 16 KiB to 8 KiB, so its operating ceiling is
247,808 bytes (242 KiB); UI retains its 16 KiB reserve and 239,616-byte ceiling.
The pre-review HTTP archive measured 244,875 bytes before this documentation
update, above the old 239,616-byte operating ceiling. The gate measures the
final archive again, including documentation. No allowlist, package exclusion,
coverage threshold, scheduler bound or timing check is relaxed.

The three reviewed limits and inclusive-boundary tests live in
[`budgets.mbt`](../../src/cmd/minimoon_check/budgets.mbt) and its white-box tests.
Every future increase requires another implementation/size review; a one-byte
overrun still fails. The gate recalculates current bytes rather than treating
these calibration samples as permanent expected outputs.

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
