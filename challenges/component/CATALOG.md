# COMPONENT_CHALLENGE catalog

Finished oshun surface components from `CHALLENGE.md`. Each entry is a
named tor in `components/` plus a runnable `canvas/tests/comp_*.k` demo;
the line names the component, the thesis, and walls floated.

The catalog is the long-running artifact; each replay is one slice through it.

## Seed — pre-challenge substrate (not scored replays)

These existed before the generator; contestants **read** them to diverge.
Do not clone them.

| Component | Home | Thesis |
|-----------|------|--------|
| remote | components/index.kz | input grammar made visible — glyph + shadow + glow |
| wordmark | components/index.kz | measured-centered text in a loaded face |
| caption | components/index.kz | measured-centered small system-face text |
| hub | components/index.kz | a bridge's presence — pearl orb + id caption |

## Replays

| Replay | Component | Thesis | Walls |
|--------|-----------|--------|-------|
| replay-component-01 | button | A nanoui button is a measured, self-hit-testing pill — the tor takes raw pointer scalars and derives hover/press/disabled against its own text-measured rect | runtime `if` arms need f64-typed literals (`@as(f64, …)`), bare comptime floats die at zig codegen; no mid-chain `let` — pointer predicates repeat verbatim per arg |
| gallery-02 | flow | The first non-quad paint primitive: `draw.bezier` strokes a quadratic Bézier as inst kind 7 — fragment-side distance-to-curve, round caps, constant width | Metal stdlib has no `cbrt`; distance-to-curve is a cubic in t — solved by multi-start Newton, the production bezier-SDF approach (the closed-form cubic's f32 edge cases punched traveling holes) |
| gallery-03 | dome | Neumorphism corrected: twin same-hue shadows extrude a rimmed card, `draw.frost` glasses its own captured surface, a micro-shadowed key is the pressable tell — palette ctx-injected from a theme store | `draw.frost` needs `draw.capture` earlier in the frame; `std/ctx(store)` fills unfilled params by name+type at compile time — field names ARE param names |
| gallery-04 | glasscard | The Apple-glass minimum: cover-fit photo (`image.width`/`height` → uniform scale, center crop) + `draw.capture` + `draw.frost` + hairline rim + measured label — no extrusion, no key | `draw.image` stretches; cover-fit is caller-side math off `image.width`/`image.height`; mid-chain values go through a module-scope scratch store |
| gallery-05 | avatar | Round portrait medallion: `clip.push.round` (new — clip stack now carries radius, shader's `clip_round` finally fed) cuts `imagecover` to a true circle; mood pills swap faces via `world.mood`, hit-tested in mouse-down against drawn rects | `stored{}` can't hold labelled tor calls — bind results via `: name` first; stage buttons that aren't sidebar hits need their own mouse-down rect test (`world.atork` mirrors `se.tork`) |
