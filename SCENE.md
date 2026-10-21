# SCENE.md — Oshun

Read-many, write-rarely. Two clocks: this scene is slow and sticky; the
existing scene is fast and live (see `.claude/skills/oshun-toolchain/`).
Scouts get the ideal user, never this file. The scene condenses from the
membrane (`concepts/`) — this seed was written at plant time from a
conversation that already surfaced the north star; expect it to thicken.

## North star

Oshun is OMNI's whole host surface — every pixel and every verb between
a Koru desktop application and its host: the markup that authors
content, the solver that lays it out, the renderers and backends that
paint it, the component library that makes it feel finished, and the
host chrome (tray, menus, dialogs, notifications) that makes it a
desktop citizen. `import oshun` is the only line an app's UI needs.

## Ideal user

The OMNI author — a Koru programmer building a real desktop application
who refuses to learn AppKit. They write markup, click things work, the
app looks native, and they never once think about `NSStatusItem`. Their
loyalty is to their own app; oshun is infrastructure they should forget
they have.

## Loose directions (beds, not blueprints)

- **Content dialect** — markup → spec seeds → solver → CmdView → paint.
  The core pipeline; correctness-gated against vendored Clay.
- **Host verbs** — `oshun:tray`, `oshun:menu`, `oshun:dialog`, and kin:
  procedural tor APIs over the same backend bridge, per-platform and
  honest about gaps. NOT markup — host chrome doesn't enter the spec
  store or the solver.
- **Component library** — real widgets grown from the dialect, when the
  dialect proves it can carry them.
- **Component library of oracles** — gates, comparators, and the
  benchmark harness that keep every shipped claim honest; they travel
  with the code they guard.

## What it says no to

- The Electron-shaped life — no webview, no bundled browser, no
  "rebuild Electron" ambition. A native app, not a hosted one.
- Config-soup — host chrome does not become markup just because markup
  is pleasant. Two API families, kept distinct.
- Ungated performance claims — a number without a falsifying oracle is
  advocacy, not measurement. The bench harness is an instrument, not a
  marketing asset.
- Fallbacks — a real surface or a loud refusal; never a degraded path
  labeled default.
- Pretending the route-around — a `koruc` wall is a compiler bug, not a
  library design constraint; the fix lands in koru.

## Tending log

- 2026-10-20 — planted at repo birth (`arbiters-init`), seed written
  from the conversation that carved oshun out of koru-libs: OMNI is the
  app, oshun is its host surface. Absorption of libs/{metal,clay,ui}
  and the native solver is the first walk.
