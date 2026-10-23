# VISUALIZER_CHALLENGE catalog

Finished kind-dispatched resource renderers from `CHALLENGE.md`. Each
entry is a named component in `components/` + a dispatch arm + a runnable
`metal/tests/viz_*.k` demo.

The catalog is the long-running artifact; each replay is one slice through it.

## Seed — pre-challenge substrate

| Kind | Renderer | Status |
|------|----------|--------|
| * (generic) | silk card + path label | placeholder — the thing this catalog replaces |

## Replays

| Replay | Kind | Renderer | Thesis | Walls |
|--------|------|----------|--------|-------|
| 01 | 2 (audio) | `components:waveform` — 96 min/max peak buckets decoded from WAV bytes at mint; zero buckets draws the bare rail, nothing invented | The card IS the resource: two wavs mint the same kind but draw different bars | WAV/RIFF s16 PCM only — m4a/mp3 classify kind 2 but decode to zero buckets; no playback yet |
| 02 | 0 (document) | `components:docpage` — 14 leading lines decoded from file bytes at mint, drawn as shaped text clipped to the card; a binary mints kind 0 anyway but draws an honest empty card | The card IS the page: two docs mint the same kind but draw different text because the bytes differ | Lines clip at the card edge, no wrapping (the seam carries text, not measures); binary/non-text docs render empty — only `res-doc-n` says why; commander.k exceeds the default 4096MB compile-memory budget with or without this arm (verified against HEAD) — `KORU_COMPILE_MEM_MB=8192` compiles it |
