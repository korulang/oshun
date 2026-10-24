# CODE_CHALLENGE catalog

Finished code-surface components from `CHALLENGE.md`. Each entry is a
named component in `components/` + a runnable `metal/tests/code_*.k`
demo.

The catalog is the long-running artifact; each replay is one slice
through it.

## Seed — pre-challenge substrate

| Shape | Renderer | Status |
|-------|----------|--------|
| document | `components:docpage` — 14 leading lines, uniform color | placeholder — flat text, no structure |
| transcript | `.txt` sidecar under a card — re-read per frame | live but unshaped |
| input line | commander's caret/history buffer in `commander.k` | embedded, not a component |

## Replays

| Replay | Shape | Component | Thesis | Walls |
|--------|-------|-----------|--------|-------|
| code-01 | source view | `code_codeview:codeview` | doc-slot lines re-tokenized into syntax spans (comment/string/number/keyword/sigil), SF Mono gutter, staggered line arrival | KORU112 — effect-spliced bodies need `$mod.` for module helpers |
| code-02 | unified diff | `code_diffview:diffview` | `diff-load` parses hunks at mint; old/new gutters, add/remove/context tint, `+adds −dels in N hunks` stat, truncation counted | PARSE005 — redundant label on punned field |
| code-03 | agent turn | `code_turnview:turnview` | gate.json sidecar → pearl turn card: prompt, verdict chip, tool receipt; honest empty/no-match states | `tvpiece` store declared mid-iteration — arm needed the same file |

Gallery dispatch: `metal/tests/gallery.k` torks 7–9 showcase all three
on the champagne stage card, clicked from the sidebar catalog.
