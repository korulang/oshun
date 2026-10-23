# COMPONENT_CHALLENGE catalog

Finished oshun surface components from `CHALLENGE.md`. Each entry is a
named tor in `components/` plus a runnable `metal/tests/comp_*.k` demo;
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
