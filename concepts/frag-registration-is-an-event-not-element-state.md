---
type: belief
id: frag-registration-is-an-event-not-element-state
provenance: session
ts: 2026-10-21
---

When a reference API performs a registration per call, the registration
is an event record, not a property of the element — porting it as
element state silently collapses multiplicity.

The floating port caught this concretely. Clay's
`Clay__ConfigureOpenElementPtr` appends one `Clay__LayoutElementTreeRoot`
to `layoutElementTreeRoots` on EVERY configure whose `attachTo` is not
NONE, freezing `{parentId, clipElementId, zIndex}` into the entry while
leaving `attachPoints`/`offset`/`expand` to be read live at emit. The
gate's own corpus reconfigures open elements (a clip row configures the
stack top), so one element legitimately registers three times — and Clay
emits its subtree three times, once per frozen entry. nl's first cut
kept `roots` as a list of element indices and read `e.fat`/`e.fpar`/
`e.zi` at emit: the duplicates registered as duplicate indices but all
three emitted the same live state — the gate saw one subtree rendered
3x at identical coordinates where the oracle renders it at the three
frozen attach resolutions.

The fix was to port the data shape, not the behavior description:
`roots` became `Root{el, par, clip, zi}` records appended inside the
configure seam, and a `clipStk` replicates `openClipElementStack`
push-on-every-configure / pop-once-at-close accounting — including the
leaks upstream produces when an element is reconfigured (the stale
entries feed later clip-ancestor resolution; "fixing" them would
diverge).

Corollary for future ports in this codebase: before modeling a field on
the element, check WHERE the reference writes it. Anything stored on a
per-call record — `layoutElementTreeRoots`, hash-map bbox items, the
clip stack — belongs in a parallel structure with the same cardinality,
and the differential gate is the only thing that reliably surfaces the
difference, because per-element-state and per-call-record are
indistinguishable on corpora that configure each element exactly once.
