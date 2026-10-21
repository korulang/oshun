---
type: belief
id: frag-the-solver-is-not-the-frame-s-bottleneck
provenance: session
ts: 2026-10-21
---

On a real `ui` scene, the layout solver is not the frame's bottleneck —
the app-side spec expansion pass is. Measuring a solver swap alone
answers the wrong question; the architecture question is who owns the
row walk.

Measured on `bench_scene.k` (the spec_snap scene — markup-shaped spec
rows, grid-track resolution, text measure — not the fuzz corpus):
the shared expansion pass (seed + measure + deepest→root fold) costs
0.021 ms/frame while the whole solver pipeline costs ~0.014 (clay) /
~0.011 (nl). Expansion is ~60% of the frame. nl leads both solver laps
(~18% solve, ~22% declare) yet that moves only ~2µs — ~7% — of the
frame.

This refines the bet the solver brief was written around. "A solver
that walks the retained rows directly" was always the interesting
claim, and now it is quantified: folding expansion + declare into the
solve attacks ~23µs/frame; swapping solvers inside the current
pipeline attacks ~2. A paused-pump/dirty-gating path attacks all 35.
The solver swap itself is now correctness-complete (gated corpus
cold+warm, consumer-path pixel-identical) and modestly faster — a
closed question, not the next lever.

Corollary for future measurements in this codebase: on scenes small
enough to resemble production (~20-40 elements), fixed per-frame
overheads dominate any solver delta; corpus benches (2.3ms solve on
1200-row fuzz trees) measure the solver, not the product. A bench that
claims to answer "is the switch worth it" must include the expansion
side, or it answers a question nobody asked.
