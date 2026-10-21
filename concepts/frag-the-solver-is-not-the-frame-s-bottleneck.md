---
type: belief
id: frag-the-solver-is-not-the-frame-s-bottleneck
provenance: session
ts: 2026-10-21
---

On a real `ui` scene, the layout solver is not the frame's bottleneck —
and neither is the row walk that feeds it. The dominant per-frame cost
is a single *uncached text measure* in the dialect's expansion bridge.
Measuring a solver swap, or a walk rewrite, answers the wrong question;
the architecture question is who owns the measure cache.

Measured on `bench_scene.k` (the spec_snap scene — markup-shaped spec
rows, grid-track resolution, one text row — not the fuzz corpus): the
shared expansion pass costs 0.021 ms/frame vs ~0.014 (clay) / ~0.011
(nl) for the whole solver pipeline. Then the decomposition
(`bench_scene_dirty.k`, `bench_scene_native.kz`):

- Skipping expansion on static frames (retained `mw/mh/cw/ch/cc`):
  frame 0.045 → 0.024 — ~60% was re-derivation.
- A host `~proc|zig` walking the store's flat columns directly, same
  fold: still 0.021 — queries and aggregation are ~0.3µs total.
- Gating out the measure call: 0.00025. The 21µs is ONE
  `koru_clay_measure` — CoreText — called per frame by `measure.text`,
  which bypasses both solvers' caches.
- Memoizing it in the proc: expand 0.0003, frame 0.028 — the dirty
  ceiling reached without any gating.

This refines the bet the solver brief was written around. "A solver
that walks the retained rows directly" survives as ownership
consolidation, not as a number: the walk it would absorb is already
~free. The measured levers, in order: memoize the dialect's measure
bridge (~20µs/frame here, scaling per text row), dirty gating (all of
it, while rows are static), solver swap (~2µs, correctness-complete
cold+warm, pixel-identical consumer path).

Corollary for future measurements in this codebase: cache misses at C
boundaries hide inside passes that look like "machinery" until you
attribute them. A lap that covers query + FFI + fold will be read as
the cost of whichever layer the reader already suspects — bisect the
lap before ranking the levers. And on scenes small enough to resemble
production (~20-40 elements), fixed per-frame overheads dominate any
solver delta; corpus benches (2.3ms solve on 1200-row fuzz trees)
measure the solver, not the product.
