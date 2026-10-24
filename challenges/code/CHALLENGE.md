---
challenge: code
kind: generator
status: standing
yields: one code-surface component — a named tor that renders source, diff, or session-shaped text with real structure, plus a runnable demo
catalog: ../../components/
family: surface
created: 2026-10-23
---

# CODE_CHALLENGE — grow the code-surface catalog

A **replayable generator**, not a task and not a backlog. You run it from
zero, it hands back one **code-surface component** plus any walls it hit,
and it is never used up.

*Walker context:* the ACP session vertical made code display recur —
agent turns carry prompts, thoughts, tool calls, diffs, and file paths,
and the surface needs renderers for all of them. Siblings: `component/`
grows general chrome, `material/` grows what the surface is made of,
`visualizer/` grows resource-kind dispatch. This one grows **the text
organ of agent work** — the vocabulary a CORDIAL-like surface assembles
from. Earned by recurrence 2026-10-23; governed like `SCENE.md`.

## Purpose

Every shape an agent session produces is structured text, and today the
plane renders it as a flat `docpage` (14 uniform lines) or a reply
`.txt` dump. This catalog grows the renderers that know what the text
*is*: a source file is not a document, a diff is not a list of strings,
a turn is not a paragraph.

## Reference library — mygo + nanoterm + nanoui

- `mygo` `ui/editor` — Editor, **DiffView**, FindBar, GoToLine, gutter,
  hover, completions (`github.com/egoist/mygo`, survey: `challenges/TOOLKITS.md`)
- `nanoterm` `agent.zig` — `Item = union{text, thought, tool, plan,
  permission, command, note, visual}` — the turn schema
  (`github.com/justrach/nanoterm`, clone: `/tmp/nanoterm-survey`)
- `nanoui` `src/highlight.zig`, `ui/textfield.zig`, `ui/list.zig`
  (clone: `/tmp/nanoui-survey`)

Port the *job*, not the ceremony. oshun is immediate-mode draw chains;
the boundary is the tor.

## The substrate you inherit (measured)

- `draw.text`/`draw.textface` — per-run color + font faces;
  `text.offset`/`text.index` caret math on the shaped layout;
  `font.load`, glyph atlas. **Colored runs compose today**: a syntax
  span is `draw.textface` at the previous run's `text.offset`.
- `draw.clip.push/pop`, `draw.panel`, scroll input events.
- `components:index.kz` tors — `docpage` is the seed to diverge from
  (it proves the live-bytes rule: card text comes from the file).
- Demos: `metal/tests/viz_*.k`, `comp_*.k` — cheap standalone compiles;
  **do not rebuild commander.k** (`KORU_COMPILE_MEM_MB=8192`, slow).

## You are the contestant

You ARE the contestant. Do **not** ask which component. Read the
catalog, look at what an agent session must show, pick the most missing
shape, build **that** to the bar — or Frontier the wall. Asking negates
the design. Lars judges after you ship.

Known gaps, unordered: `codeview` (syntax spans + gutter + scroll),
`diffview` (add/remove/context + hunks), `filetree` (indent + disclosure),
`pager` (long text + scrollbar), `findbar` (query + match highlight +
count), `turnview` (prompt + streamed items by kind), `markdown`
(headings, fences, emphasis), `statusline`, `snippet` (inline code span).

## THE BAR — derived, never authored (non-negotiable)

1. The component is a **named tor** in `components/` — draw chain over
   `libs/metal` verbs, callable with real input (text/path/handle).
2. Content comes from **real bytes** — a real source file on disk, a
   real diff, a real session sidecar. Lorem ipsum is disqualified.
3. Structure is real, not painted: gutter aligns to lines, diff colors
   follow `+`/`-`, highlights ride actual spans — a colored rect with a
   label is disqualified on sight.
4. It looks finished: measured text, real layout, the champagne language
   unless the job argues otherwise.

## Ship shape (zero-friction)

- **Tor:** `components/` (index.kz or a sibling it re-exports).
- **Demo:** `metal/tests/code_<name>.k` — compiles via koruc, renders a
  real artifact, snapshots via `offscreen.snap` where a window would
  interrupt the walker's screen.
- **Catalog:** one line in `challenges/code/CATALOG.md`.

Touch `metal/index.kz` only for a new primitive. Clean code rejected →
STOP, float, pin, no route-around.

## Done-gates

1. Named tor, called from the demo.
2. Draws real bytes with real structure.
3. Compiles clean; demo produces a visible or snapshotted render.
4. Thesis in one sentence — what *shape* this renders.
5. Walls named or "hit no wall."
6. Catalog line appended only if the bar cleared.

## Self-ground — never invent

- Custody/kind law: `/Users/larsde/src/omni/SCENE.md` (derived, never
  authored), `app/omni_img.kz`, `metal/tests/commander.k`
- The dialect: `components/index.kz`, `metal/index.kz`
- Koru law: `/Users/larsde/src/koru/tests/regression`
- Survey: `challenges/TOOLKITS.md` — the merged vocabulary map
- Compiler: `/Users/larsde/src/koru` → `zig-out/bin/koruc`

## The taste-gate — Lars

Objective gates are necessary, not sufficient. The eye judges whether
the component reads as *that shape* at a glance. Survivors stay; petals
fall.
