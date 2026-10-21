---
type: belief
id: frag-a-differential-gate-needs-a-terminating-oracle
provenance: session
ts: 2026-10-21
---

A differential gate proves nothing while its oracle can fail to answer.
The fuzz gate found a latent upstream Clay bug: in
`Clay__SizeContainersAlongAxis`'s shrink loop, `largest` is initialized
to 0, so a child whose dimension went negative (pct>1 overflow chains,
or aspect-ratio propagation of a negative axis) is never selected for
shrinking — `widthToAdd` computes 0, `sizeToDistribute` never moves, and
`Clay_EndLayout` spins forever. Verified present in upstream v0.14 main.

The gate can only diff runs that terminate, so the vendored oracle
itself needed a patch: a no-progress guard that breaks when an
iteration cannot move `sizeToDistribute`. That guard is
semantics-identical on every input upstream actually terminates on — it
only fires inside the region where the reference produces no output at
all. Both solver loops (shrink and grow) carry it, and the native
solver's mirrored loops carry the same guard so the candidate matches
the patched reference.

The discipline this adds: when the oracle hangs, the fix belongs in the
oracle — marked, minimal, and provably confined to the non-terminating
region — not in the corpus (avoiding the input hides a real reachable
state) and not in a watchdog (a gate that gives up has no verdict).
Every patch to the vendored reference is a place upstream drift can
re-break us; mark them `LOCAL PATCH` so a future vendor sync can find
them.

Operational corollary: zig caches the `clay_impl.c` translation unit
without noticing edits to `clay.h` — iterating on the vendored header
requires bumping the .c file or the change silently doesn't rebuild.
Instrumentation that "didn't fire" may never have been compiled.
