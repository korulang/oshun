---
challenge: material
kind: generator
status: standing
yields: one new GPU material — a shader-backed draw verb in libs/metal plus a demo that shows it on instanced quads
catalog: ../../metal/tests/mat_*.k
family: surface
created: 2026-10-23
---

# MATERIAL_CHALLENGE — grow the surface material catalog

A **replayable generator**, not a task and not a backlog. You run it from
zero, it hands back one **new material** plus any walls it hit, and it is
never used up.

**Singular contestant is the default.** One sealed contestant per replay;
variance accumulates across replays.

## Purpose

The champagne/pearlescent silk (`draw.silk`, instanced kind 4) was OMNI's
founding material — one shader, one mood, the whole identity. This
generator grows the **material organ**: new instanced kinds in the Metal
shader, each a distinct substrate the surface can be made of. A material is
not a color scheme — it is a physical behavior (fold, sheen, refraction,
grain, glow) sampled per-instance.

The second purpose is the usual one: **stress the shader / instancing /
uniform substrate** until something breaks. A pinned hole beats a material
that exists only because the shader dodged its hard part.

## Reference menu — steal, don't invent reasons

- nanoui `src/ui/glass.metal` + `glass.zig` — Liquid Glass: backdrop
  kernels, optics, refraction. The obvious sibling to silk (and its CPU
  twin pattern is the discipline to copy: same pixels, two paths).
- mygo `ui/shader` + `internal/gpu/metal` — per-platform shader packaging.
- The silk itself: `metal/index.kz` kind-4 — read how `silk_field`, the
  normal-from-field lobes, `ftime` breathing, and the instanced uniform
  layout work before writing a second kind.

## You are the contestant

You ARE the contestant. Do **not** ask which material. Read the catalog,
pick the gap that most earns its keep — glass is the named first target
because it is the documented one, but any material that justifies itself
visually is legal — and build **that** to the bar, or Frontier the wall.
Asking negates the design. Lars judges after you ship.

## THE BAR — a material, not a tint

**Required:**

1. A **new instanced kind** (kind 5, 6, …) in `metal/index.kz`'s shader +
   a `draw.<name>` verb that records it — same uniform/instance plumbing
   the silk rides.
2. The material **behaves** — it has a physical property the eye can test:
   silk folds + sheen + breathing; glass refracts a backdrop. A flat
   gradient labeled "marble" is **disqualified**.
3. **Animated or parameter-honest**: it responds to `ftime` or to real
   instance parameters (angle, folds, sheen, pearl are the vocabulary —
   extend, don't hardcode).
4. A demo shows it on **multiple instances** — a grid of varying
   parameters, not one hero quad.

**Disqualified on sight:** a material that only differs from silk by
constants; a "material" that is a static texture lookup with no field.

## Ship shape (zero-friction)

- **Shader + verb:** in `metal/index.kz` — new kind branch in the fragment
  shader, new `draw.<name>` proc, kind-registry comment updated.
- **Demo:** `metal/tests/mat_<name>.k` — window demo, grid of parameter
  variation, compiles via koruc.
- **Catalog:** one line in `challenges/material/CATALOG.md` under Replays.

## Holes — float and pin, never fix, never route around

Shader won't express it, instance buffer can't carry the parameter,
uniform layout fights back — float the exact failure, pin a repro, stop.

## Done-gates

1. New kind registered + `draw.<name>` verb.
2. Visible physical behavior (not constants-off-silk).
3. Compiles clean; demo renders (screenshot where possible).
4. Thesis in one sentence — what *material* claim this proves.
5. Walls named or "hit no wall."
6. Catalog line appended only if the bar cleared.

## Self-ground — never invent

- The silk: `/Users/larsde/src/oshun/metal/index.kz` (kind-4 shader, uniform
  layout, `draw.silk` plumbing)
- Koru law: `/Users/larsde/src/koru/tests/regression`
- Reference: `/tmp/nanoui/src/ui/glass.metal`, `/tmp/mygo/ui/shader`
- Compiler: `/Users/larsde/src/koru` → `zig-out/bin/koruc`

## The taste-gate — Lars

The eye is the judge. "It compiles" does not mean it looks like a
material. Survivors stay; petals fall.

## Slow-clock

Governed like `SCENE.md`.

- 2026-10-23 · planted. Seed catalog = silk (kind 4). First named target:
  glass (nanoui's glass.metal is the reference).
