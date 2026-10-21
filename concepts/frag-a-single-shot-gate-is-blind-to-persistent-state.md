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
  after, while nl (which resolves attach against live element boxes)
  emits 2106 every frame. CAND==REF holds on the gate because the gate
  only ever sees frame 1.

- `koru_clay_measure` builds a CTFont + CFAttributedString + CTLine
  per call — real typographic shaping, microseconds per call. Clay's
  persistent measure cache makes frames 2+ measure-free; nl's
  `measureWords` is "Clay__MeasureTextCached minus the cache" and pays
  ~19ms of Core Text per frame where clay's declaration costs 0.28ms
  (ReleaseFast). Correctness-identical, cost-divergent — invisible to
  the gate either way.

The follow-on ruling for this codebase: "nl matches Clay" currently
means "nl matches Clay's cold-frame stream." Whether the stale-box
behavior is an upstream quirk to mirror or a bug to refuse is a
separate question — but it is unreachable by the gate as constituted.
If multi-frame parity is ever required, the gate needs a warm pass
(layout the same spec twice, diff frame N vs frame N+1 per solver) or
an explicit decision that the dialect owns cold semantics only. And
when a measured claim rides the corpus, say which frame it measured.
