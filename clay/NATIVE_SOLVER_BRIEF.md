# Native layout solver — fusion brief

```
kind: commissioned design-attack + build session
status: draft — 2026-10-20

progress 2026-10-20 — the differential gate exists and the candidate passes
it: `clay/tests/fuzz_gate.k` + `fuzz_cmp.py`, CAND==REF over 400 commands,
known-wrong MUT arm rejected with 1420 divergences. Candidate is
`nativelayout/index.kz` (flat arrays, no ID hashing; fit → grow →
align/position port; same CmdView stream). Along the way the gate caught a
real UB in the dialect: `sizing()` built `.percent = f` union inits, leaving
`size.minMax.max` as stack garbage that Clay's propagate pass reads as a
clamp bound — percent elements contributed garbage-clamped content heights
to FIT parents. Both bindings now fully initialize the union
(`minMax = {f, 0}` — percent still reads f at offset 0; CloseElement's
max<=0→MAXFLOAT reset now always fires, deterministically un-capped).

decision 2026-10-20 — STAY ON CLAY as the dialect's solver. nl covers ~2/3
of Clay's capability surface (capability map below); switching now would be
premature optimization on a 48h-old subset. Clay remains oracle + default;
nl remains a gate-verified candidate that grows feature-by-feature: each new
dialect capability lands as binding words + nl port + generator rows + gate
proof on both. nl is faster where measured (decl ~1.35×, solve ~1.3×
ReleaseFast) — a noted property, not the reason to switch.

capability map (Clay surface vs nl): PARITY — fit/grow/pct/fix minMax
semantics (incl. pct>1 in the corpus — Clay logs a diagnostic but still
configures/lays out; nl does the same math without the log), PER-SIDE
padding, gap, ax/ay, ltr/ttb, ROOT+LEFT_TOP floats (panels AND images),
clip + childOffset, image, text (WORDS wrap, fontSize, color), ud,
offscreen cull, OVERLAY_COLOR (START/END pair — ordering + union
layout verified: rectangle.backgroundColor aliases overlayColor.color
in Clay's renderData union, so CmdView needed no new field), CORNER
RADIUS ×4 (crtl/crtr/crbl/crbr → decl.cornerRadius — first CmdView
projection growth: ctl/ctr/cbl/cbr fields + a `cr=` line key; `each`
reads rectangle.cornerRadius for non-text kinds — image/custom share
the {color, radius} prefix, text is guarded to 0; comparator compares
cr= on kinds 1/4 and now counts kind-7 c= as a real aliased payload),
CUSTOM (kind 9 — el.custom/nl.el.custom carry `data` into
decl.custom.customData / El.cd; emitted after IMAGE, before
SCISSOR_START; CmdView +1 field `cd`; comparator compares d=
unconditionally and extends c=/cr= to kind 9 — custom shares the
{color, radius} union head for real), ASPECT RATIO (ar →
decl.aspectRatio / El.ar; chained two-directional solve — close-time
fill, post-X h=w/ar + hmx lock, post-Y w=ar·h, mirroring
Clay__UpdateAspectRatioBox's four call sites; MUT adds +mut to ar on
every element), BORDERS (br..ba + bwl/bwr/bwt/bwb/bwc →
decl.border.{color,width} / El.br..bwc; kind 2 emits on pop before
OVERLAY_END/SCISSOR_END, betweenChildren>0 emits interleaved k=1 RECTs
walking child dims + gap; integer-division halves — childGap and
betweenChildren are u16 so their /2 truncates, nl mirrors; CmdView +5
bw fields; comparator compares c=/cr=/bw= on kind 2),
TEXT CONFIG (fontId/letterSpacing/lineHeight/wrapMode/textAlignment on
el.text + nl.el.text; measure fn widened to width += ls×len per the
upstream renderer contract; lineHeight>0 overrides measured height at
open, per wrapped line, AND halves-into the first-line y offset —
clay.h:2984 centers the natural glyph box inside the line; alignment
offsets each line's x by 0/half/full of the leftover width; wrapMode
gates text resizability only — this vendored clay still wraps on
spaces+newlines regardless, nl mirrors; CmdView +3 fields, comparator
checks fi/ls/lh on kind 3),
FLOATING cluster (fat/fx/fy/fae/fap/exw/exh/zi/fct on every el.* +
nl.el.* — attachTo PARENT/ROOT (the corpus does not draw
ELEMENT_WITH_ID), attachPoints 9x9 element x parent, expand,
clipTo ATTACHED_PARENT/NONE, zIndex).

growth 2026-10-21 — pct>1 diagnostic parity: ninth cycle, and the last
ABSENT additive port. The error stream is now part of the compared
surface. clayErr keeps its stderr line but also emits a normalized
`err t={d}` token on stdout so the dump carries it; nl's four configure
procs fire the identical check on the declared sizing
((wk==PCT and w>1) or (hk==PCT and h>1)) — per configure call, like
ConfigureOpenElementPtr, so reconfigures double-fire exactly as Clay
does. The binding's sizing() union trick matters here: percent values
land in minMax.min, which aliases size.percent — the >1 check reads
the raw value either way. MUT gained a boundary-crossing arm (pct w
<=1 -> +1.5) so rejection now exercises the diagnostic channel too.
Comparator parses per-section ordered err sequences — all diagnostics
precede cmds since declaration strictly precedes drain. Receipt:
GATE PASS — CAND==REF over 2106 cmds + 50 err t=6 lines matching
positionally; MUT rejected with 3293 divergences (363 err lines vs
REF's 50 — the boundary arm alone guarantees err-stream divergence).
growth 2026-10-21 — floating/attach/expand/zIndex: eighth cycle, the
first that was a STRUCTURE port, not a field port. Clay registers a
layoutElementTreeRoots entry on EVERY ConfigureOpenElement call whose
attachTo != NONE — corpus clip rows reconfigure the open element, so
one element can register N times and Clay emits its subtree N times.
nl initially stored element indices in roots and read live fields at
emit; the gate caught it as one subtree emitted 3x vs 1x because each
Clay entry FREEZES {parentId, clipElementId, zIndex} at registration
while nl's emit read final values. roots is now a list of per-
registration Root{el, par, clip, zi} records; a new clipStk mirrors
openClipElementStack exactly — pushed per floating configure (resolved
ancestor) AND per clip configure (own index), popped ONCE at close iff
the FINAL config has clip|floating, so reconfigures leak entries the
way upstream does. Attach resolves against the stored parent's EMITTED
box (a parent not yet emitted — negative zIndex ordering — yields a
zero box, Clay's hashmap-stale-read quirk mirrored). zi sort is
bubble-stable on the ENTRY's zi; commands carry entry zi except
BORDER, betweenChildren rects, and both SCISSOR_ENDs, whose Clay
literals omit zIndex -> 0. Emit reads live attachPoints/offset/expand
but stored par/clip/zi — the exact split Clay makes. Corpus: fat
~20% (1 or 3), 9x9 attach draws, expand 0-11px each axis, zi -4..4,
fct 0/1. Receipt: GATE PASS — CAND==REF over 2106 cmds (625 under
nonzero-z roots, 66 clip-wrapped floating subtrees, negative-z roots
emitting before the implicit root); MUT rejected with 3318
divergences; smoke, gallery, gallery_comp (8GB), bench_solvers,
folder_snap, spec_snap green. Dead-draw audit rerun: first zi draw
was divTrunc(s4,2^32)==0 always -> every zi drew -3 silently.
ABSENT,
structural — element IDs + hover machinery (ud-stamp is our hit-test model
instead), ATTACH_TO_ELEMENT_WITH_ID (wants spec-row refs, not hashes),
internal scroll state (frame-pure by design — childOffset is app-owned),
transitions (cross-frame identity — belongs spec-side if ever wanted).

growth 2026-10-20 — first full capability cycle landed: per-side padding.
The gate's REF walk moved OFF the ui convenience words onto raw
clay:el.* — the raw bracket was widened to the full declaration surface
(el.cfg + eid + padl/r/t/b; el.img + fl/fx/fy/eid; el.clip + pad×4;
new el.text = ui:text's exact OpenTextElement path). nl's El carries
padl/padr/padt/padb; every solver read audited (axis sums vs leading-side
cursor origins). Generator draws ~25% per-side asymmetric pads. Receipt:
GATE PASS — CAND==REF over 405 cmds; MUT rejected with 1388 divergences;
100 Clay pct>1 diagnostics on stderr (non-cmd lines, comparator-ignored).
gallery_comp/spec store keeps authored `pad` (ui words stay uniform) —
the view/expanded store carries the four sides. gallery_comp emits
bit-identical snaps; needs KORU_COMPILE_MEM_MB≈4600 (was already near
the 4096 default before this change — frontend elaboration, not a
blowup; backend bytes identical).

growth 2026-10-20 — overlayColor: second capability cycle, cheaper than
the first because the raw bracket was already the harness. el.cfg/
el.clip/el.img + nl.el.* each gained ovr/ovg/ovb/ova → decl.overlayColor /
El.ovr..ova; emit order matches clay.h exactly (OVERLAY_START before
image/scissor/rect, OVERLAY_END at pop before SCISSOR_END, both under
!offscreen, END carries ud). Corpus: ~20% of rows draw overlay color.
Receipt: GATE PASS — CAND==REF over 539 cmds (134 of them the new
k=7/k=8 pairs); MUT rejected with 1253 divergences. smoke, gallery,
gallery_comp, bench_solvers all green.

growth 2026-10-20 — cornerRadius: third capability cycle, first to grow
the normalized projection contract. el.cfg/el.clip/el.img + nl.el.*
each gained crtl/crtr/crbl/crbr → decl.cornerRadius / El.ctl..cbr;
nl emits radius on RECT (k=1) and IMAGE (k=4) commands, matching
clay.h (both renderData members carry {color, radius} at the head).
CmdView +4 fields; `each` guards is_text (text renderData has no
radius at that offset — unguarded read would be stringContents bytes,
i.e. nondeterministic). Comparator parses `cr=` and compares on
k∈{1,4}; corpus draws ~25% asymmetric per corner — corner-order swaps
diverge. MUT gained a crtr corruption alongside the pad/gap/w/eid
axes. Receipt: GATE PASS — CAND==REF over 539 cmds; MUT rejected
with 1632 divergences. smoke, gallery, gallery_comp, bench_solvers
green.

growth 2026-10-21 — CUSTOM commands: fourth capability cycle, first in
the oshun home. el.custom + nl.el.custom (full el.img decl shape, data →
customData/El.cd); nl emits kind 9 between IMAGE and SCISSOR_START,
matching clay.h:3040. Corpus: kind space redrawn 50/20/10/10/10
(panel/clip/img/custom/text); MUT corrupts data (+mut*7) and w.
Receipt: GATE PASS — CAND==REF over 539 cmds (139 kind-9 lines across
the three sections); MUT rejected with 1581 divergences. smoke,
gallery, gallery_comp, bench_solvers (ReleaseFast), folder_snap green.

growth 2026-10-21 — aspectRatio: fifth capability cycle, first to
change solver MATH rather than command shape, and the first to find a
bug in the oracle. el.cfg/el.clip/el.img/el.custom + nl.el.* gained
`ar`; nl grew an `aspects` index buffer + updAspect and mirrors Clay's
call sites (close-time, percent-expansion, post-wrap h=w/ar + hmx
lock, post-Y w=ar·h). THE FIND: enabling ar in the corpus wedged
Clay__SizeContainersAlongAxis's shrink loop — a negative child dim
(pct>1 chains or ar propagation) never matches `largest` (init 0), so
widthToAdd computes 0 and sizeToDistribute never moves — a real
non-termination bug present in upstream v0.14 main, reachable without
ar too. Vendored clay.h now carries a marked LOCAL PATCH: a
no-progress guard (break when an iteration can't move
sizeToDistribute) in both shrink and grow loops — semantics-identical
on every input upstream actually terminates on. nl's mirrored loops
got the same guard. Corpus: ar drawn 0/~0.5-3.0; MUT corrupts ar on
every element. Receipt: GATE PASS — CAND==REF over 589 cmds; MUT
rejected with 1466 divergences; smoke, gallery, gallery_comp,
bench_solvers, folder_snap green. Operational note: zig caches the
clay_impl.c TU without noticing clay.h edits — bump the .c file when
iterating on the header.

growth 2026-10-21 — borders: sixth capability cycle, the widest emit
path so far. el.cfg/el.clip/el.img/el.custom + nl.el.* each gained
br..ba + bwl/bwr/bwt/bwb/bwc (independent border color, matching
Clay's decl.border.{color,width}). Kind 2 emits at pop before
OVERLAY_END/SCISSOR_END; betweenChildren>0 && color.a>0 emits k=1
RECTs between children, offset = pad - gap/2 - bw/2 accumulated over
child dims — clay.h halves childGap and betweenChildren as INTEGER
division (u16), and nl initially floored differently: four divergences
at exactly ±0.5/±1.0 caught by the gate. First corpus draw had three
of five width columns dead (divisor too large for the mod window) —
gate coverage claims need a draw audit, not just a param. Corpus: 213
BORDER cmds, all five width columns nonzero, 68 betweenChildren.
Receipt: GATE PASS — CAND==REF over 813 cmds; MUT rejected with 2716
divergences; smoke, gallery, gallery_comp, bench_solvers, folder_snap
green.

growth 2026-10-21 — text config: seventh capability cycle, the whole
Clay_TextElementConfig seam in one port (fid/ls/lh/wm/tal on el.text
+ nl.el.text → El.fid/ls/lh/wm/tal). koru_clay_measure widened to
(chars, len, size, ls) applying the upstream renderer contract
(width += ls×len, trailing space measure included); measure.text
tor gained ls. Solver: lineHeight>0 sets open-time dims.height (min
too), each wrapped line's h, the nl dh after wrap — and, the subtle
bit, the EMIT path: clay.h:2984 starts yPosition at
(finalLineHeight − naturalHeight)/2, vertically centering the natural
box inside the line, which the gate caught as constant -4.43/-7.26
y-offsets. textAlignment shifts each line's x by 0/half/full of the
leftover width — the first cluster to move horizontal emission, not
just dims. wrapMode in THIS vendored clay only gates resizability
(clay.h:2366 wm!=WORDS drops the element from the resizable scan);
the wrap routine still splits spaces+newlines for all modes — nl
mirrors exactly rather than the enum's name. Corpus: fid 0-3, ls
0-3, lh 0/10-39, wm/tal 0-2; 47 text cmds — 31 fid>0, 6 ls>0, 13
lh>0, centered lines visible in x variance; MUT adds mut*4 to ls
(lands in the measure fn → guaranteed width divergence). CmdView +3
fields (fi/ls/lh), comparator checks them on kind 3. ui:text keeps
its signature (zeroes the new fields — WORDS+LEFT defaults). Receipt:
GATE PASS — CAND==REF over 786 cmds; MUT rejected with 2495
divergences; smoke, gallery, gallery_comp (8192MB), bench_solvers
(ReleaseFast: clay solve 0.035 vs nl 0.026), folder_snap green.

landmine found 2026-10-20 — nl first lived as `~part native` of libs/clay.
~parts elaborate EAGERLY into every consumer: gallery_comp (never touches
nl.*) blew the 6144MB compile-mem budget with the marker, compiled fine
without it; backend emitted bytes identical → pure frontend dead weight.
Moved nl to its own package `libs/nativelayout` — clay consumers pay zero;
the gate and bench import it directly. fuzz_gate + gallery_comp + smoke +
spec_snap + bench_solvers all re-verified post-move (gate still
CAND==REF 400 cmds; gallery snaps bit-identical).

race 2026-10-20 — `clay/tests/bench_solvers.k`: one climb pass runs BOTH
pipelines per frame (per-frame interleave, 6 laps), same 600-leaf tree.

CORRECTED after a dead measurement basis: the Debug build's ratios
(~3.6× declare, ~4.9× solve) were a codegen artifact — -O0 punishes
Clay's C implementation far harder than nl's lean Zig. ReleaseFast is
the honest basis (and matches every earlier calm absolute). ReleaseFast,
same binary, same frames:

| lap | clay | nl | ratio |
|---|---|---|---|
| declare | 0.062–0.064 | 0.046–0.047 | ~1.35× |
| solve | 0.034 | 0.024–0.027 | ~1.3× |
| drain | ~0 | ~0 | — |

Same-moment nanoui (hillclimb, boxes): build 0.035 + layout 0.014 =
0.049. nl decl+solve ~0.070 — still ~1.4× behind nanoui's build+layout,
not ahead. nl vs clay is a real ~1.35× on declare+solve combined.
Caveats: lap 1 pays ui's word-mapping lap 4 skips (slight nl favor);
nl solve includes Clay-compatible float/wrap bookkeeping nanoui may not
pay. Machine was under memory pressure during measurement (17G wired,
swap active) — absolutes on a calm box may differ; ratios in-binary hold.
trees: koru-libs 4e2f332 (main), koru 4c2f38b30 (main), nanoui ede1eb4 (clone)
```

race 2026-10-21 — `clay/tests/bench_corpus.k`: the full gated surface
as the workload — the fuzz gate's generator + both walks verbatim
(generator and walks diff-verified identical to fuzz_gate.k), MUT
dropped, print-drain swapped for counted drain, 6 interleaved laps per
frame. ReleaseFast, laptop (same basis rule as the race above — Debug
inflates nl's win ~5x on solve since -O0 punishes Clay's C far harder;
the Debug run showed solve 12.1 vs 4.25, ReleaseFast collapses it).
Numbers (frame median, ms):

| lap | clay | nl | ratio |
|---|---|---|---|
| declare | 0.283 | 19.11 | nl ~68x slower |
| solve | 2.33 | 2.14 | nl ~1.09x faster |
| drain | ~0 | ~0 | — |
| cmds (frame 1 / 2+) | 2106 / 2092 | 2106 / 2106 | |

Two findings, both real:
1. nl declare is ~68x SLOWER (ReleaseFast; ~12x under Debug) — the
   missing measure-text cache.
   `koru_clay_measure` builds CTFont+CFAttributedString+CTLine per call
   (real Core Text shaping, ~us each); Clay's measureTextHashMap is
   PERSISTENT memory so frames 2+ measure nothing, while nl's
   measureWords is "MeasureTextCached minus the cache" and pays
   ~600 shaping calls/frame (~120 text rows x ~5 calls: space,
   per-word, whole-string — paid at declare even for later-culled
   elements). Without text rows (bench_solvers' panel tree) nl declare
   wins 0.24 vs 0.72 Debug; on the corpus the uncached measure
   dominates. This is a portable gap, not a verdict.
2. Command counts diverge on WARM frames — RESOLVED by mirroring.
   Clay 2106 on frame 1 then 2092 forever; nl was 2106 always.
   Mechanism: `layoutElementsHashMap` items persist across BeginLayout,
   and emit stamps `hashMapItem->boundingBox` at DFS visit — a floating
   root sorted before its parent reads the parent's STALE last-frame
   box (zero on frame 1), shifting attach positions and cull sets.
   The gate now has warm sections (`==REF2==`/`==CAND2==`, same spec
   re-laid-out on the same context): CAND==REF and CAND2==REF2 are both
   hard checks. nl mirrors via persistent `pboxes` (element index ->
   emitted box, written at DFS visit, read by attach + clip-scissor
   resolution; absent -> zero box). Result: nl drifts identically —
   CAND2==REF2, both 2106->2092 with the same 5516 displaced cmds.
   Keyed by element index (nl's stand-in for Clay's element id —
   element-id machinery is still scoped out; identical declaration
   streams get identical staleness, evolving trees are a noted
   divergence class). See
   concepts/frag-a-single-shot-gate-is-blind-to-persistent-state.md.
   Keeping the quirk is a parity choice for now — the frag records it
   as an open betterment decision.
Verdict on the full corpus: nl's solver is ~9% faster and the frame
LOSES by ~8x end-to-end — the measure cache is the whole story.
FOLLOW-UP (same day): the cache is now ported — nl carries a
persistent `mcache` (Wyhash over contents+fontId+fontSize+letterSpacing,
Clay's exact measure-affecting fields) backed by a `mwords` arena
bounded at Clay's 16384-word cap with sweep-and-refill (no generation
eviction; stale entries are dead weight until the sweep — noted
divergence in Clay's capacity-ERROR path). Post-port numbers, same
workload, ReleaseFast: clay 0.268/2.32/~0 vs nl 0.199/2.14/~0 — nl
ahead on EVERY lap and ~10% on the frame; nl decl fell 19.11 ->
0.199. Post-pboxes numbers: clay 0.262/2.253/~0 cmds 2092 vs nl
0.181/2.080/~0 cmds 2092 — nl ahead on every lap AND emitting the
identical warm stream. Gate: CAND==REF and CAND2==REF2, MUT rejected.
Attribution verified by isolation: same corpus with text rows skipped
(kind==3 undrawn) gives clay 0.251/0.503/~0 vs nl 0.178/0.379/~0 —
nl ahead on every lap and ~25% ahead on the frame. The deficit is the
~600 Core Text shaping calls, nothing else.

UI-DIALECT CENSUS (2026-10-21, answers "which absent features does
production's declaration surface actually touch"): ui/index.kz's whole
Clay surface is Clay__OpenElement (always anonymous — never
OpenElementWithId), ConfigureOpenElement, OpenTextElement, CloseElement.
Fields set: sizing (fit/grow/pct/fix + dock overrides), uniform pad,
gap, ax/ay, dir, backgroundColor, userData (eid -> CmdView.ud, the
hit-testing contract), floating (ATTACH_TO_ROOT + LEFT_TOP/LEFT_TOP +
offset only), image.imageData, text (tx/fontSize/color/userData).
Every one is ported, gated cold+warm in nl — ZERO absent-reachable
features through the dialect path. The scoped-out gaps (element IDs +
hover machinery, ATTACH_TO_ELEMENT_WITH_ID, pointer capture, internal
scroll state, transitions, query APIs — PointerOver/GetElementData:
grep-verified zero call sites outside clay_impl.c/nl/tests) are
reachable only through the raw el.* bracket, which is the dev/test
surface. Hit-testing is consumer-side via CmdView.ud rects — never
Clay__PointerOver. Even the evolving-tree pboxes caveat is unreachable:
ui's only floating path attaches to ROOT (par=0), whose persistent box
is always {0,0,W,H} — index-keying and Clay's id-keying can never
diverge there. (Clay's anonymous ids are HashNumber(siblingIndex,
parentId) — position-derived hashes, same staleness class.)

CONSUMER-PATH PIXEL PARITY (2026-10-21 — the receipt the census
demanded): `clay/tests/spec_snap_nl.k` is the spec_snap twin with nl
swapped in for Clay — same markup→spec→`ui`-shaped declaration walk
(the ui:panel lowering inlined: dock/sizeKind/axis words → codes),
same `nl.each` drain, same `draw.rect` → Metal → BMP at frame 30.
First run FAILED the oracle: 585,360 differing bytes across 328 rows;
the three `fl=1` floating subtrees rendered as solid white boxes —
positions and sizes correct, colors and children visibly absent.
Command streams were byte-identical across all 45 frames; literal-color
probes (red → red, black → black) proved geometry and the render path
fine. The emitted Zig named it: `nl.each`'s proc body iterates
`for (cl.cmds.items) |*rc|` and, inlined into consumer scope, the
`| then |>` branch's `rc.r` resolved to that raw `Cmd` (0-255 channels,
which the shader clamps to opaque white) while the `if` condition and
print correctly bound the yielded `CmdView`. `clay.each` uses `__rc`
and never collides. Fix: `nl.each` loop var `rc` → `__rc` — the
hygiene convention was load-bearing, not stylistic. Result: clean
binaries produce BYTE-IDENTICAL BMPs (`cmp` clean at 4,096,054 bytes).
Gate re-run after the rename: CAND==REF 2106 / CAND2==REF2 2092 /
MUT rejected 3293. The asymmetry (`if`/print bound the yield, `then`
bound the proc-local) is a koru compiler scope-resolution wart worth
reporting — hygiene removes the trigger, not the wart. See
concepts/frag-a-proc-body-name-is-a-consumer-facing-binding.md.
Lesson for the ledger: command-stream parity does not imply paint
parity — the divergence lived below the projection, in what name the
compiler resolved the draw's arguments to. The pixel oracle is now a
standing consumer-path check alongside the stream gate.

SCENE BENCH (2026-10-21 — `clay/tests/bench_scene.k`, the first race on
the REAL ui scene rather than the fuzz corpus): spec_bench's store +
seed rows verbatim, the shared expansion pass as lap 1, both solvers
interleaved per pass (climb warmup 30 + 300 × 3, lowest median),
ReleaseFast. Correctness basis: this exact scene is already
pixel-identical (spec_snap_nl BMP) and cmd counts match 20/20. Numbers
(ms/frame, 3 runs — medians stable, one nl-solve outlier at 0.0151):

| lap | clay | nl |
|---|---|---|
| expand (shared) | 0.021 | (same pass) |
| declare | 0.0019 | 0.0015 |
| solve | 0.0118 | 0.0097 |
| drain | ~0 | ~0 |

nl leads both solver laps (~18% solve, ~22% declare) and ~7%
end-to-end (0.032 vs 0.035 incl. shared expansion). But the finding
that matters more than the ratio: **the expansion pass (0.021) costs
more than either pipeline's decl+solve combined** — on a real scene,
the solver swap moves ~2µs of a ~35µs frame.

EXPANSION DECOMPOSITION (2026-10-21 — `bench_scene_dirty.k`,
`bench_scene_native.kz`; same scene, same protocol, 3 runs each):

| variant | expand | frame |
|---|---|---|
| query expansion, uncached measure | 0.021 | 0.045 |
| dirty-gated (skip expand f>1, retained mw/mh/cw/ch/cc) | 0 | 0.024 |
| native column walk (`~proc|zig` on `__koru_store_spec`), uncached | 0.021 | 0.045 |
| native column walk, memoized measure | 0.0003 | 0.028 |

Three findings, each measured:

1. **The query machinery is free.** A host `~proc|zig` walking the spec
   store's flat column arrays directly — same fold, same sweep, same
   `koru_clay_measure` bridge — costs the same 0.021 as the `std/store`
   query version. Queries, iteration, and aggregation total ~0.3µs.
   A row-walking solver cannot save what isn't spent.
2. **The 21µs is ONE uncached CoreText call.** Gating the measure out
   (`tx.len != 0 and false`) drops the lap to 0.00025. The dialect's
   `measure.text` calls `koru_clay_measure` directly, bypassing BOTH
   solvers' measure caches (clay's hashmap, nl's mcache) — one "auto
   hugs text" row costs ~20µs every frame, every run. On text-heavy
   scenes this scales per text row; it is the worst un-cached surface
   in the pipeline.
3. **Memoizing the measure reaches the dirty ceiling without gating.**
   A module-level `var` AutoHashMap in the proc (persistent state works
   from a main-module `.kz`) keys (tx,fs)→dims: expand 0.0003, frame
   0.028 ≈ the 0.024 dirty-gated number. On a static scene, caching the
   one miss is worth ~60% of the frame; dirty gating then saves only
   the remaining ~0.3µs walk.

Revised §5 implication: the expansion's cost was never the row walk —
it was a cache miss the dialect bridge owns. Levers ranked by measured
payoff on this scene: (a) memoize `measure.text` (~20µs/frame; the
dialect bridge, not either solver); (b) dirty gating (~21µs/frame on
static scenes, subsuming (a) but only while rows are untouched);
(c) solver swap nl↔clay (~2µs, correctness-proven). The row-walking
native solver's marginal gain over nl is now measured ≈ decl + a
0.3µs fold — real but small; it consolidates ownership rather than
unlocking a number.

> **To the session reading this brief**: the numbers below were measured,
> not quoted — every table entry has a reproduction path. Your job is to
> attack the bet in §5 before building it: find the trap the brief missed,
> or strengthen the design until it survives you. Do not ship a solver that
> wins on a workload the gate cannot falsify — an ungated number is worse
> than no number (see §7, the contract).

## 1. The question

koru-libs renders UI through vendored Clay v0.14 (`clay.h`, 5,058 lines,
652 internals) for layout. Nanoui — the Zig framework metal/index.kz
already ports glyphs/atlas/instancing from — solves the same workload
with a purpose-built 318-line flexbox (`src/ui/layout.zig`). Its solve
(0.015) is ~2.2× faster than Clay's EndLayout (0.033), and its
build+layout (0.050) is 1.74× faster than our expand+declare+solve
(0.087). See §2.

**Should the dialect get a narrow native solver** — and if so, does the
combination (retained spec rows + small solver + dirty gating) let us
*beat* nanoui's frame number rather than trail it?

## 2. Measured state (receipts, not claims)

Re-measured 2026-10-20. The first draft of this table was wrong: it put
Clay's whole frame (declare + solve + commands, per hillclimb's own
`clay.zig` header) in the "layout solve" row against nanoui's solve-only
0.015, derived the Koru split by subtraction (0.089 − 0.058), and the
0.089 itself was a mean (`benchmarking:run` = seconds/passes).

Machine: M2 Pro, both sides ReleaseFast, load avg 3.5–9 across the runs.
Protocol on both sides: 30 warmup + 300 measured × 3 reps, lowest median
retained. Koru side: `std/benchmarking:climb` + `lap` (koru main
1dbc71cf3), ranges over 5 interleaved rounds.

| | nanoui | koru (`bench_boxes_split1.k`) | koru with paint (`bench_boxes_paint.k`) | upstream Clay (`/tmp/clay-split/split.c`) |
|---|---|---|---|---|
| build / expand (spec query + HSL) | 0.035 ms | ~0.020 (inferred: lap 1 0.052–0.056 minus declare) | (in lap 1: 0.059–0.060) | n/a |
| declare (tree into Clay) | (in build) | 0.033–0.036 (declare-only arm, in `bench_boxes_split.k`) | ↑ | 0.0335 |
| layout solve (EndLayout incl. commands) | 0.014–0.015 | 0.032–0.035 | 0.032–0.033 | 0.0331–0.0335 |
| paint | 0.016 | **0** (no paint work) | 0.0154–0.0163 (draw.* → instPush, incl. pass/encoder setup) | 0.002 (cmd read) |
| encode CPU (upload + encode + commit) | 0.012–0.014 | — | 0.0056–0.0062 with the instance ring (was 0.0230–0.0249 with a buffer per flush); instFlush + endEncoding + commit | — |
| **CPU total** | **0.077–0.081** (frame + encode) | 0.084–0.091 (no paint, no encode) | **0.107–0.109** (sum of phase medians; 0.112–0.114 before the single walk, 0.131–0.134 before the ring) | 0.069–0.070 |
| GPU (GPUEnd − GPUStart, same method) | median 0.423–0.424; **min 0.4178–0.4195** | — | **min 0.4145–0.4152** (0.606 before the shadow-σ fix) | — |

- **We are behind on CPU, at parity on GPU**: CPU 0.108 vs 0.079 (1.37×;
  1.44× before the single-walk expansion, 1.67× before the instance ring). GPU min 0.415 vs nanoui min 0.418: a
  0.8% difference, inside the ±5% noise band, so parity, not a win. Same
  1201 instances at 2× backing. The earlier 1.43× GPU gap was our bug,
  not a renderer gap: the bench drew shadows at σ = 4 where nanoui uses
  σ = blur/2 = 2 (paint.zig:66). The instance gate missed it because
  nanoui's dump didn't print border_width. The dump and the comparator
  now carry bw/bc; the σ = 4 candidate fails with 600 divergences, σ = 2
  passes 1201/1201. Before paint existed on our
  side the comparison read 0.087 vs 0.066 (1.32×) — that number flattered
  us by omitting paint + encode. Like for like, expand + declare + solve
  (0.087) vs nanoui build + layout (0.050) is still 1.74×.
- Paint + encode together: **ahead**, 0.021 vs nanoui's 0.028–0.030
  (0.74×), after replacing the per-flush `newBufferWithBytes` with a
  3-slot instance ring (nanoui's model). Before the ring it was 0.039–0.041
  (1.4× behind). The phase boundary differs (our pass/encoder setup falls
  inside the paint lap, nanoui's inside encode), so only the sum compares —
  our encode alone (0.006) is not a like-for-like win over theirs (0.013).
  Both sides' sums are sums of per-phase medians. The ring's slot
  synchronisation (wait on the slot's last command buffer before reuse) is
  correct by construction but not test-gated: a static scene can't expose
  a race.
- The paint path is gated: `metal/tests/offscreen_scene.k` (offscreen
  surface) and `offscreen_twin.k` (same scene through a window) produce
  byte-identical 1280×800 BMPs. A +1/255 colour mutation makes `cmp`
  fail. The window path's `snap.k` is byte-identical before and after the
  metal refactor. `bench_boxes_paint.k` reports 1201 instances flushed per
  frame.
- Expansion, measured step by step (paint binary, gate-verified at each
  step): replacing 20 `when lf.gr == rr` scans with one ordered walk took
  lap 1 from ~0.060 to ~0.055. Moving the HSL intermediates from scratch
  store columns into a `capture` local was a wash. Spelling each `@mod`
  once (nanoui's 4 per leaf) was also a wash: the disassembly shows LLVM
  had already shared the duplicates, with the same 10 `fmod` call sites in
  both binaries. In a no-paint profile (`sample`, 3174 samples,
  top-of-stack), `fmod` is ~32% and nanoui pays the same 4 per leaf (f32
  `@mod`). Clay is ~64%: declare (`Clay__OpenElement` /
  `AddHashMapItem` / `ConfigureOpenElementPtr` / `CloseElement`) plus
  `Clay_EndLayout` / `CalculateFinalLayout` / `SizeContainersAlongAxis`.
  Koru's own frames are ~3%.
- The binding adds nothing measurable: Koru's declare-only arm matches raw
  C Clay's declare, and Koru's EndLayout matches raw C's.
- `bench_boxes.k`'s drain does no work that survives: the tail phase is 0
  at a 41 ns clock in every run. Probable cause (not verified in the
  disassembly): nothing reads the per-command writes, so LLVM collapses the
  loop. Either way, the measured binary has **no paint equivalent**. The
  gate binary doesn't paint either: it prints the instance stream as text
  in nanoui's dump format. Neither binary runs metal's `draw.*` →
  `instPush`, which needs a `*Frame` that today only exists inside a
  windowed `frames` pump.
- hillclimb's own Clay arm reads 0.059–0.060 for the same declare twin my
  C harness reads at 0.069. Not reconciled (possibly a different `clay.h`
  revision). Trust the ratios, not the absolute numbers.
- Instrument note: putting a second pipeline (the declare-only arm) in the
  same binary slowed the full arm's lap 1 from 0.053 to 0.069, while
  EndLayout stayed the same. One pipeline per binary for absolute numbers.
  `split1` (full arm only, with laps) matches the lap-free `climb` binary
  (0.086–0.089), so laps cost nothing measurable.

Scene: `boxes` — 600 rounded+shadowed boxes, 20×30 grid, sine-offset +
HSL colors at frame 100/120. 1201 painted instances.

**Correctness gate ran first** (`clay/tests/bench_boxes_gate.k` +
`bench_boxes_cmp.py`): a patched hillclimb `dump` exe prints nanoui's
painted instance stream; the Koru candidate reproduces it 1201/1201 with
0 divergences at 0.005pt/0.002 tolerances. Mutation-tested: a gr/gc-swapped
seed fails with 2247 divergences + 200 orphans. The gate can say no.

What the table implies for the bet: Clay accounts for ~0.067 of our 0.087
(declare ~0.034 + solve ~0.033). A solver that walks the retained rows
directly replaces **both** halves, not just EndLayout. The expansion pass
(~0.020) is a separate target: `std/store:query(leaves) when lf.gr == rr`
inside `for(0..20)` visits 12,000 rows per frame to emit 600. With paint
and encode measured, encode was a target too and is now closed: the
instance ring took paint + encode from 0.040 to 0.021, ahead of nanoui's
0.029. GPU is at parity once the shadow σ matches. The paint binary's lap 1 reads 0.059–0.060
against split1's 0.052–0.056 for identical code, the binary-composition
effect again, so lap 1 absolutes are per-binary.

## 3. Architecture as it stands

```
spec store (retained rows, stable handles, [tree] parent stamps)
  → expansion pass (queries spec, emits element decls each frame)
  → Clay: BeginLayout → open/cfg/close × N → EndLayout → render commands
  → CmdView drain (kind, x/y/w/h, rgba, img, ud=eid, tx, fs)
  → metal/index.kz draw ops → instance stream → GPU
```

Per frame today: everything runs, unconditionally, ~60fps polling pump
(`frames|zig` in metal/index.kz: pump events → dispatch → `! frame` →
sleep 16ms). Nothing is skipped; nothing is cached across frames except
metal's glyph/text caches.

Nanoui is the inverse: ephemeral per-frame box tree, retained caches
below it, and **a paused CADisplayLink at idle** (their measured idle
CPU: 0.00%; ours polls).

## 4. The dialect census — the Clay surface actually reachable

Everything our bindings can spell (`clay/index.kz` el.cfg/el.img/el.clip,
`ui/index.kz` panel/panelx/text/imgpanel):

| Clay feature | status |
|---|---|
| sizing: fit / grow / percent / fixed, per axis | **reachable** |
| padding | uniform only (`pad` → all 4 sides) |
| childGap, childAlignment x/y, direction LTR/TTB | **reachable** |
| backgroundColor | **reachable** |
| floating | narrow: offset + ATTACH_TO_ROOT + LEFT_TOP/LEFT_TOP only |
| image (imageData → IMAGE command) | **reachable** |
| clip (horiz/vert + childOffset — scroll) | **reachable** |
| text (CLAY_TEXT: color, fontSize, userData) | **reachable** — default wrap, no config exposed |
| userData (eid → CmdView.ud — hit-testing depends on it) | **reachable, load-bearing** |
| borders, aspectRatio, per-side padding, zIndex, attach matrix, expand offsets, pointer capture, element ids, multi-font, wrap config, debug | **unreachable** |
| corner radius | **not a Clay concept** — lives paint-side in metal's instance format |

The reachable set is close to nanoui's 318-line vocabulary plus
percent-sizing, alignment, and the text measure callback.

## 5. The bet (attack this)

A narrow solver covering §4's reachable surface, ~318-line-class,
emitting the same CmdView contract, with two possible wins:

1. **Constant factor** — no generality tax. The target is Clay's
   declare + solve together (~0.067, §2) if the solver reads spec rows
   directly, or EndLayout alone (~0.033) if it is fed by the same
   per-frame declaration pass.
2. **Incrementality Clay structurally cannot offer** — Clay has no
   partial-solve API; retained spec + stable row identity + `[tree]`
   parent chains means dirty-subtree re-solve is expressible. This is
   the win beyond nanoui (which also re-solves globally) — but see trap 6.

Known traps, ranked:

1. **Grow/fit semantics are subtle.** Fit-then-grow with per-sibling grow
   distribution, alignment, percent-of-parent, minMax — 95%-correct ships
   a subtly wrong solver. Defense exists: gate vs Clay's CmdView stream
   on identical trees (a *second* oracle, same repo, no cloning) AND vs
   nanoui's instance dump.
2. **Text is the hard case.** The measure bridge (`koru_clay_measure`,
   CoreText, installed as Clay's MeasureTextFunction) must be called by
   the native solver or text sizes diverge. Wrapping is reachable-by-
   default (ui:text exposes no wrap config) — whether any spec actually
   wraps is **unmeasured**; census it first. If nothing wraps, a solver
   may still handle wrapped text by refusing or falling back (see trap 3).
   Two Clay behaviours the Clay oracle will hold us to: it caches
   measurements across frames (`Clay__MeasureTextCached`, clay.h:1639),
   and under the default WORDS wrap it measures **word by word plus a
   separate `spaceWidth`** (clay.h:1717, 1741), not the whole string.
   Kerning across spaces differs, so a whole-string CoreText width will
   not gate identical. A solver without its own cache loses the text
   scene. Hillclimb's Clay twin uses `WRAP_NONE` and our `ui:text` uses
   the default, so the two Clay oracles already measure differently.
3. **The hybrid boundary.** Per-scene routing (whole tree native iff
   every element in vocabulary, else whole tree Clay) is honest and
   simple. Subtree-level routing embeds a foreign-solved subtree inside a
   global fit/grow pass — sizing feedback makes it a real problem, not a
   seam. Do not pick the subtree hybrid without solving the feedback.
4. **CmdView is a contract.** Command order, `ud` (eid) stamps, SCISSOR
   pairs around clip children, TEXT command fields — consumers
   (hit-testing, metal drain) depend on all of it. The solver must emit
   the stream, not a lookalike.
5. **Where it runs.** `~proc |zig` host code inside `clay/index.kz` —
   same surface as el.cfg, compiled with the exe, fastest honest path.
   A surface-`.kz` solver is better dogfood but its perf on the row-walk
   + math is unmeasured. Decide deliberately; "Koru-native" that loses
   the race it was built to win is a contradiction.
6. **Incremental relayout validity.** A dirty child's grow/percent can
   resize siblings and bubble up through ancestors' fit pass. Subtree
   re-solve is only sound under a real invalidation rule (probably:
   dirty bubbles to nearest sizing-independent ancestor). Nanoui doesn't
   attempt it; if we do, the invalidation rule IS the contribution —
   gate it as hard as the solver itself. Cheaper first: most dirty
   frames during interaction only change paint (hover recolor). A
   paint-only vs layout dirty split that patches rgba into a cached
   CmdView needs no invalidation proof. Boxes moves every frame, so
   neither form shows anything on boxes.
7. **Gate coverage.** Boxes only exercises fixed leaves, fit rows and a
   grow root. Grow distribution, percent sizing, alignment, clip and
   floating go untested. Clay runs in-process, so trap 1's real
   defense is differential fuzzing: random trees over the §4
   vocabulary, CmdView streams compared Clay vs native, plus a
   known-wrong mutant the fuzzer must catch. Scene gates then cover the
   nanoui side.

## 6. Orthogonal steals (smaller, separable, still worth it)

- **Hillclimb protocol → koru-side harness.** Protocol half done
  (koru main 1dbc71cf3):
  `std/benchmarking:climb(warmup, frames, reps)` returns the lowest
  median, and `lap(k)` / `lap.ms(k)` split a pass into phases. It panics
  if a pass skips, repeats or reorders a lap. Still to do: `--label` +
  append-only `bench/history.jsonl`.
  Makes every future number protocol-comparable to nanoui's published
  table and turns regression into a ledger diff.
- **Paused pump** — store-watch → dirty flag → skip expansion/solve/drain
  when clean; nanoui pauses the display link itself. Idle frame cost
  0.087 → 0 beats any solver constant-factor. Watch out: hover writes
  every mouse-move (dirty under interaction is correct); `stored` writes
  inside `! frame` mean write→fire recursion — flag-and-drain, not
  recursive fire.
- **Scene catalog** — boxes done; text (300 changing labels — exercises
  measure bridge), scroll (1000 rows + clip), dashboard, list
  (virtualized 100k) remain. Each port = upstream dump mode + comparator
  + Koru scene, gate first.

## 7. The contract (non-negotiable)

- **Gate before numbers.** Any solver races only workloads whose
  instance/cmd streams were verified identical first. A solver that
  can't be gated identical doesn't get measured.
- **Two oracles, both live.** Clay's CmdView stream (same repo, cheap)
  and nanoui's painted instances (clone + dump patch, authoritative).
- **Mutation-test the gate.** The boxes gate proved it rejects a
  known-wrong candidate (gr/gc swap → 2247 divergences). Every new gate
  needs its own known-wrong.
- **Estimator: lowest median, never means.** Same rule as upstream.
- **Report asymmetry is disqualifying.** Behind says "behind" first.
- **Regression-pin everything** — the dialect has snap/pixel oracles
  (`spec_snap.k`, `spec_tree.k` byte-identical BMPs); a solver swap must
  leave them byte-identical.
- **No perf claim leaves the session without its workload + gate named.**

## 8. File map

| path | role |
|---|---|
| `clay/index.kz` | bindings: init/layout/el.cfg/el.img/el.clip/measure.text/each/cmd.count; `~proc |zig` host procs compile with the exe (`exe.addCSourceFile` → same opt level) |
| `clay/clay.h`, `clay_impl.c` | vendored Clay v0.14 + CoreText measure bridge (`koru_clay_measure`) |
| `ui/index.kz` | dialect layer: panel/panelx/text/imgpanel — dock coercions, eid→userData |
| `clay/tests/bench_boxes.k` | measured candidate (benchmarking:run wrapper) |
| `clay/tests/bench_boxes_gate.k` | gate candidate — prints instance stream |
| `clay/tests/bench_boxes_cmp.py` | comparator, 0.005pt/0.002 tolerances |
| `clay/tests/spec_snap.k`, `spec_tree.k` | pixel oracles (byte-identical BMP requirement) |
| `clay/tests/spec_snap_nl.k` | consumer-path pixel oracle: spec_snap twin through nl (byte-identical BMP vs spec_snap) |
| `clay/tests/bench_scene.k` | scene bench: real ui scene (spec_bench store+rows), interleaved clay/nl, climb laps |
| `metal/index.kz` | draw ops, instance format (kind 0 quad/1 text/2 shadow/3 image), `frames|zig` pump |
| nanoui clone `/tmp/nanoui-check` | `hillclimb/` harness (may need re-clone — /tmp is scratch); `src/ui/layout.zig` = the 318-line reference |

Repro: `cd /tmp/nanoui-check/hillclimb && zig build run -- --scene boxes
--only nanoui` (baseline), `dump` exe for the reference stream — the
gate file's header documents the full path including the patch.

## 9. Open questions the session must resolve

1. Whole-tree native-with-vocabulary-check vs subtree hybrid — and if
   hybrid, the sizing-feedback story.
2. Text: does anything in the corpus actually wrap? If yes, does the
   solver own wrapping or route those subtrees to Clay?
3. Where the solver runs (`|zig` host vs surface .kz) — decide with a
   measurement, not a preference.
4. The incremental invalidation rule, if incremental is attempted at
   all — including the proof obligation that a skipped re-solve cannot
   change output.
5. Whether `el.clip`'s childOffset semantics and floating's root-offset
   are cheap in the native solver or whether they force a second pass.
6. What the history ledger's schema is (scene/commit/machine/protocol
   version) so runs stay comparable as the machine changes.
