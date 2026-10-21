---
name: oshun-toolchain
description: Orientation map for the oshun repo — what it is, how it builds/tests, where the source of truth lives, and what bites. Read FIRST in any /arbiters walk, Scout, or Contestant run here.
---

# oshun-toolchain — existing-scene instrument (fast clock)

**Oshun is OMNI's host surface** — the markup language, solver, renderers,
backends, host verbs, and component library a Koru desktop app consumes.
Today it holds the markup transform (`index.kz` → spec-row seeds); the
UI subtree (metal/clay/ui/solver) is inbound from koru-libs.

## Build / test

- No standalone build — consumers compile programs through it:
  `koruc <prog>.k -o <prog>` (koruc lives in the sibling `../koru` repo,
  `zig-out/bin/koruc`).
- Resolution: `koru.json` `paths` — `"oshun": "../oshun"` in the
  consumer's own koru.json; `import oshun` then finds `index.kz` via
  `koru.entry`.
- Tests/probes currently live in `../koru-libs/clay/tests/` (the spec
  corpus: spec_tree, spec_snap, theme_preview, probes, bench gates) —
  they move here with the UI subtree.
- Source of truth: **the spec-dialect test corpus + gate harness**
  (pixel/instance comparators) — a probe that compiles green proves
  nothing until its output is inspected (pixels, printed handles).

## Canonical standard

- `SCENE.md` (repo root) — the north star: oshun is OMNI's whole host
  surface, two API families (content dialect + host verbs), the no-list.
- koru's `CLAUDE.md`/`AGENTS.md` in `../koru` — the toolchain rules this
  repo inherits: fix koruc, never route around it; no fallbacks; verify
  before presenting; measured claims carry falsifying oracles.

## What bites

- **A compile is not a verification** — markup lowers to store seeds;
  wrong seeds compile fine. Check the seeded rows/pixels.
- The transform emits `std.store` inserts — markup-only consumers pull
  no `@cImport`; keep it solver-free until the solver lands here.
- `~zig`/`~proc` blocks are Zig, not Koru — this file is a host-layer
  transform; read the standard library's `store.*.kz` family for style.
- Commit gate: `## World Model` + `## Membrane` sections required —
  `Signals:`/`Evolution:` or `acknowledged-none`, never silence.
