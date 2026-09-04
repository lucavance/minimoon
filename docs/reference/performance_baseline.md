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
| Conformance application runtime | 344,000 bytes |
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
| committed Conformance fixture | 406,000 bytes |
| generated starter | 247,000 bytes |

Release generation minifies the host and runtime syntax. On `moon
0.1.20260824` / `moonc v0.10.10` with Bun 1.4.0, the ABI v10 authoring
checkpoint measured 325,978 runtime bytes, 14,247 host bytes, 38,558
initial-tree bytes, and 385,574 aggregate JavaScript bytes. The 344,000,
15,000, 41,000, and 406,000 ceilings were set by the deterministic
1,000-byte-rounded `measured / 0.95` rule.

The graph-lifetime candidate now measures 328,915 runtime bytes and 388,511
aggregate JavaScript bytes; host and initial-tree bytes are unchanged. The
existing ceilings were not raised: 15,085 runtime bytes and 17,489 aggregate
bytes remain. Unrelated protocol, WXML, and WXSS budgets are unchanged.

A controlled rebuild of the pre-change source measured 317,892 runtime bytes
with this toolchain versus its previously committed 283,839-byte output: a net
34,053-byte toolchain change. On the same unminified bundle, the Moon compiler
contributed 34,263 bytes while Bun 1.4.0 was 210 bytes smaller than Bun 1.3.14.
The current cumulative feature delta is 11,023 bytes, including 2,937 bytes for
the graph-owned lifetime registry. The supported Moon toolchain floor is
unchanged.

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
