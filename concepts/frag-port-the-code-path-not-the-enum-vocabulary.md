---
type: belief
id: frag-port-the-code-path-not-the-enum-vocabulary
provenance: session
ts: 2026-10-21
---

When porting a vendored library's config surface, the enum's name is
not the semantic — the code path in THIS revision is. Clay's
`Clay_TextElementConfigWrapMode` advertises WORDS / NEWLINES / NONE,
suggesting NEWLINES wraps only on explicit breaks and NONE never wraps.
The vendored implementation does neither: `wrapMode` is consulted at
exactly one site — the resizability scan in `Clay__SizeContainersAlongAxis`
(clay.h:2366), where non-WORDS modes drop a text element out of the
resizable set — while the actual wrap routine in
`Clay__CalculateFinalLayout` splits on spaces and newlines identically
for all three modes.

A port written from the enum's vocabulary (or from upstream
documentation, or from a newer revision where the semantics may have
been filled in) would implement three different wrap behaviors and
diverge from the oracle on every corpus input that exercises them.
The correct surface to mirror is what the pinned code DOES: read every
use site of the field, port those branches, and record the gap between
name and behavior so a future vendor sync can re-audit it.

Same cycle's corollary: the measure callback is part of the solver
contract, not a rendering detail. `letterSpacing` only reaches the
layout engine through the installed `MeasureTextFunction`, so widening
it is a coordinated change across the C bridge, both solver call
sites, and the standalone `measure.text` verb — a field that only
reaches the command stream without affecting measure produces boxes
that disagree with what the callback thinks the text occupies.
