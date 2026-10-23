# MATERIAL_CHALLENGE catalog

Finished surface materials from `CHALLENGE.md`. Each entry is a new
instanced kind in `metal/index.kz`'s shader, a `draw.<name>` verb, and a
runnable `metal/tests/mat_*.k` demo.

The catalog is the long-running artifact; each replay is one slice through it.

## Seed — pre-challenge substrate

| Kind | Verb | Thesis |
|------|------|--------|
| 4 | `draw.silk` | champagne/pearlescent silk — folds + sheen + breathing |

## Replays

| Replay | Kind | Verb | Thesis | Walls |
|--------|------|------|--------|-------|
| replay-material-01 | 5 | `draw.glass` | liquid glass — the bezel is a lens that refracts the real image-atlas pixels beneath the pane (nanoui optics, instanced, + chromatic aberration) | backdrop must be an image-atlas draw — a true framebuffer backdrop needs a scene texture; the single instanced pass can't read its own target |
