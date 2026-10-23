---
challenge: visualizer
kind: generator
status: standing
yields: one kind-dispatched resource renderer — a component that draws what a bridge resource IS, registered to a custody kind
catalog: ../../components/
family: surface
created: 2026-10-23
---

# VISUALIZER_CHALLENGE — grow the kind-dispatched renderer catalog

A **replayable generator**, not a task and not a backlog. You run it from
zero, it hands back one **resource-kind renderer** plus any walls it hit,
and it is never used up.

**Singular contestant is the default.** One sealed contestant per replay;
variance accumulates across replays.

## Purpose — this is the charter organ

OMNI's law is *derived, never authored*: the surface renders what the
bridge enumerates. Today every resource — an image, a voice memo, a doc —
rides the same silk card with a path label. That is the prototype's
placeholder, not the design. This generator grows the **kind-dispatched
renderers**: a component that draws what a resource *is*, not that it
exists.

A waveform for audio. A live thumbnail for images. A text preview for
docs. A spectral field for streams. Each replay adds one kind → renderer
mapping and retires a little more of "silk box for everything."

Sibling generators: `component/` grows general chrome (reusable tors),
`material/` grows what the surface is *made of*. This one grows what
resources *look like by kind*.

## You are the contestant

You ARE the contestant. Do **not** ask which kind. Read the catalog, look
at which resource kinds reach the bridge (audio is minted today via the
remote mic; images via file-open), pick the kind whose renderer is most
missing, and build **that** to the bar — or Frontier the wall. Asking
negates the design. Lars judges after you ship.

## THE BAR — derived, never authored (non-negotiable)

**Required:**

1. The renderer draws **from the resource's actual content** — samples,
   pixels, bytes, metadata — not from the path string or a static icon.
   A waveform painted from fake data is **disqualified** (the law is the
   law: derived, never authored).
2. It is a **named component** in `components/` (or a sibling it
   re-exports), callable with a custody handle + frame, like the
   resource-card render path in commander.k uses today.
3. Kind **dispatch is explicit** — the resource's kind field selects this
   renderer; the demo mints or stubs a resource of that kind and proves
   the dispatch arm fires.
4. It looks **finished**: measured where text rides it, honest about what
   it doesn't render (a half-drawn spectrogram is a Frontier, not an
   entry).

**Disqualified on sight:** a kind renderer that ignores the resource's
bytes; dispatch bolted to filename matching (the bridge's kind field is
the law, the path is a label).

## The substrate you inherit

- `app/omni_img.kz` + commander.k — custody handles, kind tags, the card
  render path where your dispatch arm lands
- `libs/metal` — instanced quads, image atlas, text, silk
- `components/index.kz` — the tor grammar (remote/wordmark/caption/hub)
- `/tmp/omni_remote_mic_*.wav` — real audio resources on disk RIGHT NOW,
  decoded by `siri_mic_bridge.zig` — a waveform renderer has live data
  waiting

## Ship shape (zero-friction)

- **Component:** `components/` (tor + kind-registry line).
- **Dispatch arm:** where kind dispatch lives today (commander.k's card
  render, or `app/omni_img.kz` — follow the existing structure).
- **Demo:** `metal/tests/viz_<kind>.k` — renders a resource of that kind
  through the real dispatch path.
- **Catalog:** one line in `challenges/visualizer/CATALOG.md`.

## Holes — float and pin, never fix, never route around

Can't read wav bytes from Koru, no audio decode in-process, kind field
doesn't carry what you need — float exact failure + program, pin, stop.

## Done-gates

1. Named component, kind-dispatched (not path-sniffed).
2. Draws from real resource content.
3. Compiles clean; demo renders a real minted or stubbed resource.
4. Thesis in one sentence — what *kind* this now renders.
5. Walls named or "hit no wall."
6. Catalog line appended only if the bar cleared.

## Self-ground — never invent

- Custody/kind law: `/Users/larsde/src/omni/SCENE.md` (law 5: derived,
  never authored), `app/omni_img.kz`, `metal/tests/commander.k`
- The dialect: `components/index.kz`, `metal/index.kz`
- Koru law: `/Users/larsde/src/koru/tests/regression`
- Compiler: `/Users/larsde/src/koru` → `zig-out/bin/koruc`

## The taste-gate — Lars

Objective gates are necessary, not sufficient. The eye judges whether the
card now *is* the resource. Survivors stay; petals fall.

## Slow-clock

Governed like `SCENE.md`.

- 2026-10-23 · planted. Seed catalog = the silk card (kind-generic
  placeholder). First obvious targets: audio waveform (real wavs on disk),
  image thumbnail (already texture-loaded), text/doc preview.
