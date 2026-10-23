---
challenge: component
kind: generator
status: standing
yields: one reusable Metal-surface component — a named tor/draw-chain in the oshun component vocabulary with a runnable demo
catalog: ../../components/
family: surface
created: 2026-10-23
---

# COMPONENT_CHALLENGE — grow the oshun component catalog

A **replayable generator**, not a task and not a backlog. You run it from
zero, it hands back one **reusable component** plus any walls it hit, and it
is never used up.

**Singular contestant is the default.** One sealed contestant per replay;
variance accumulates across replays, not inside a fleet.

## Purpose — explicit, and it is NOT a prettier todo

This challenge exists for exactly two things:

1. **Grow a pristine catalog of idiomatic oshun components** — draw-chain
   tors you can drop into an OMNI surface. Context-candy for how Metal-
   surface components are written well in Koru.
2. **Stress the draw / text / layout / image substrate** until something
   breaks. A pinned hole beats a demo that compiled by dodging.

The koru-libs `COMPONENT_CHALLENGE` grows TTY widgets for vaxis. This
generator grows the **GPU surface organ**. OMNI's kind-dispatched resource
cards drink from this catalog; they are not the goal.

## Reference library — nanoui (not Charm)

The koru-libs generator ports Charm Bubbles. Ours ports **nanoui**
(`github.com/justrach/nanoui`, MIT — a Zig GPUI-style native UI):

- `src/ui/widgets.zig` — boxes, text, icons, buttons, toggles, sliders
- `src/kit/` — components after GPUI Kit: overlays, tabs, forms
- `src/ui/list.zig` — the virtualized list
- `src/ui/textfield.zig` — the text field (selection, composition)

Port the *look and job* into oshun's tor grammar (a named draw chain over
`libs/metal` + `libs/components` primitives). Do **not** port nanoui's
retained box-tree ceremony — oshun is immediate-mode draw chains; the
component boundary is the tor, not a widget object.

## The substrate you inherit (measured, not aspirational)

Already ported from nanoui and working: instanced rounded-rect quads,
borders, R8 glyph atlas + CoreText shaping, image atlas, Gaussian shadows,
scroll/mouse/keyboard events, the silk material. **Missing organs**: text
field/IME, virtualized list, springs, hit-testing beyond ASCII caret.

A component that needs a missing substrate piece → **Frontier** (below).

## You are the contestant

You ARE the contestant. Do **not** ask which component. Read the catalog
(`challenges/component/CATALOG.md`), see what exists, pick the gap that most
moves the surface toward real chrome — and build **that** to the polish
bar, or Frontier the wall. Asking negates the design. Lars judges *after*
you ship.

## THE BAR — component boundary (non-negotiable)

A catalog entry is a **named reusable component**, not a mini-app.

**Required:**

1. The component is a **named tor** in `components/` (or a new file under
   it if the vocabulary is splitting) — `~pub tor <name> { f: *libs/metal:Frame<frame>, ... }`
   with a draw chain, the same shape as `remote`/`wordmark`/`caption`/`hub`.
2. The demo **calls the tor** — a reader points at the tor declaration and
   says: that is the component. Chrome, measurement, state — inside the
   boundary, not in the demo's top-level frame loop.
3. It looks **finished in a real window** — measured text, real layout
   (nativelayout or clay, not magic constants where layout exists), the
   champagne/pearlescent material language unless the component's job
   argues otherwise. A colored rect with a label under a nanoui name is
   **disqualified**.

**Disqualified on sight:**

- Demo-shaped entries where the frame loop *is* the component and the tor
  only names leaf chrome.
- nanoui **name** without nanoui **craft** (a "button" with no hover/down
  states is a rect).

## Ship shape (zero-friction)

- **Tor:** appended to `components/index.kz` (or a sibling file it
  re-exports) with a kind-registry comment line.
- **Demo:** `metal/tests/comp_<name>.k` — a standalone window demo that
  renders the component alone, compiles via koruc, runs on screen.
- **Catalog:** one line in `challenges/component/CATALOG.md` under Replays —
  name, thesis, walls hit.

Touch `metal/index.kz` **only** for a new *primitive* (a draw verb, an
event source). Clean code rejected → **STOP**, float, pin, no route-around.

## Holes — float and pin, never fix, never route around

~50% chance it's you. Float exact program + compiler error. Pin a failing
repro when real. Stop. Toolchain fixes happen between replays, never as a
detour inside one.

## Done-gates — self-checked before you ship

1. **Component boundary** — named tor, called from the demo.
2. **nanoui-class polish** for the chosen component.
3. **Compiles clean** through `koruc` (`-c` minimum; the demo actually
   renders — screenshot or the silk_snap/headless path where it exists).
4. **Thesis in one sentence** — what *component* claim this proves.
5. **Walls named or "hit no wall".**
6. **Catalog line appended** only if polish cleared.

## Self-ground — never invent

- Koru law: `/Users/larsde/src/koru/tests/regression`
- The dialect: `/Users/larsde/src/oshun/components/index.kz`,
  `metal/index.kz` (draw verbs), `nativelayout/index.kz`, `ui/index.kz`
- Reference: `/tmp/nanoui` clone (or re-clone `justrach/nanoui`) —
  `src/ui/widgets.zig`, `src/kit/`
- Compiler: `/Users/larsde/src/koru` → `zig-out/bin/koruc`
- Do not turn this into an OMNI feature or a metal/ primitive fork

## The taste-gate — Lars

Objective gates are necessary, not sufficient. "It compiles" does not mean
it looks like chrome. Survivors stay; the rest evaporate. Petals falling is
the point.

## Slow-clock

Governed like `SCENE.md` — read-many, write-rarely, deliberate, logged.

- 2026-10-23 · planted. Seed catalog = the four tors in `components/index.kz`
  (remote, wordmark, caption, hub) + `metal/tests/` demos as ground to
  diverge from.
