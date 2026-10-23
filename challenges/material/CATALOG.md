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
| replay-material-02 | 6 | `draw.frost` (+ `draw.capture`) | frosted glass — ground-glass scatter of the REAL framebuffer: `draw.capture` ends the pass, blit-copies the target into a persistent scene texture, and reopens it LoadActionLoad, so kind-6 panes blur/bend/milk the live scene (silk, text, images), not an atlas stand-in — the replay-01 wall attacked and passed | capture costs a pass split + full-target blit per call; panes don't refract panes (post-capture draws aren't in the texture); `draw.frost` before `draw.capture` panics — the ordering obligation is runtime, not typestate; blur is a 13-tap fragment disc — very large `rough` goes grainy where nanoui pre-filters into a downsampled backdrop |
