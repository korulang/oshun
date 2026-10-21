---
type: belief
id: frag-a-single-shot-gate-is-blind-to-persistent-state
provenance: session
ts: 2026-10-21
---

A differential gate that runs the workload once validates the cold
frame only. Any state the reference keeps across frames — persistent
hash maps, measure caches, generation counters — makes the warm frame
a different program than the one the gate approved.

Measured concretely in the corpus bench. Clay's
`InitializeEphemeralMemory` resets nearly everything per layout, but
`layoutElementsHashMap*` and `measureTextHashMap*` are allocated once
in `InitializePersistentMemory` and never reset. Two consequences the
single-shot gate cannot see:

- A floating root whose z-order emits it before its attach parent
  reads `hashMapItem->boundingBox` — on frame 1 that field is the
  zero-init bytes, on frame 2+ it is the parent's stale last-frame
  emitted box. Attach positions shift (observed: x −104 → 346 on a
  z=−4 subtree), scissor culling changes, and the command stream
  diverges: clay emits 2106 cmds on frame 1 and 2092 on every frame
  after. Before the warm pass existed, nl (which resolved attach
  against live element boxes) emitted 2106 every frame — CAND==REF
  held only because the gate never saw frame 2.

- `koru_clay_measure` builds a CTFont + CFAttributedString + CTLine
  per call — real typographic shaping, microseconds per call. Clay's
  persistent measure cache makes frames 2+ measure-free; nl's
  `measureWords` was "Clay__MeasureTextCached minus the cache" and
  paid ~19ms of Core Text per frame where clay's declaration costs
  0.28ms (ReleaseFast). Correctness-identical, cost-divergent —
  invisible to the gate either way.

Resolution (same day, this frag's follow-on ruling made concrete): the
cure is a warm pass, not a verdict on which behavior is right. The
gate now replays each solver's walk a second time on the same context
(`==REF2==`/`==CAND2==`); CAND==REF and CAND2==REF2 are both hard
checks, and each solver's frame1→frame2 drift is reported. With the
instrument live, mirroring turned out to be bounded, not a rabbit
hole: one persistent `pboxes` map written at DFS visit (clay.h:3100),
read at attach and clip-scissor resolution — absent ⇒ zero box (frame
1), stale ⇒ last frame's box (frame 2+). CAND2==REF2 with identical
drift (both 2106→2092, same 5516 displaced commands). The measure
cache was ported the same way — persistent `mcache`/`mwords`, key on
contents+fontId+fontSize+letterSpacing — and nl's declaration fell
19.11 → 0.199ms, putting nl ahead of clay on every lap of the full
gated corpus (~10% on the frame, 0.181/2.080 vs 0.262/2.253,
ReleaseFast).

The durable belief stands: declare which frame a correctness or
performance claim measured. What changed is the gate's reach — cold
AND warm streams are both certified now, and "nl matches Clay" means
both.

Follow-on ruling (same day): the open betterment decision was taken.
Under "fix bugs over parity — nothing to support yet", the `pboxes`
staleness mirror came back out and the gate's comparison target became
Clay's CONVERGED stream (REF2, verified stable by REF3), not frame 1.
nl resolves attach/clip against the target's RENDERED box — filled by
a silent declaration-order pre-pass, which materializes the rendered
position because a containing root is registered (and walked) before
the clip/floating roots nested inside it, so the detached rendering
pass writes `eb` last for elements in a detached frame. The deeper
finding: Clay's converged map is neither "the hierarchical box" nor
"the emitted box" — it is zi-order last-writer, arbitrarily mixing
document-space and detached-frame boxes for double-visited clip
elements. Two divergences adjudicated in opposite directions proved
it: el438's converged map held hierarchical (clay culls ud=569 whose
parent renders at detached origin — nl's (247,2) emission is correct),
while el375's held detached (clay shows the ud=482 subtree onscreen —
matching the rendered box). The gate encodes this as an explicit
ADJUDICATED set: CAND must equal REF2 PLUS exactly the ud=569 pair —
correctness over parity without giving up the oracle's ability to say
no to anything new.
