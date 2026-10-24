# TOOLKIT SURVEY — the mygo + nanoui component vocabulary

Surveyed 2026-10-23.

- `github.com/egoist/mygo` @ main — 2.8k★, MIT, Go. Desktop apps:
  system webview *or* native UI it draws itself (`package ui`,
  retained-mode; Metal on darwin, GL elsewhere, WebGL2 for wasm).
- `github.com/justrach/nanoui` @ main — MIT, **Zig 0.17**, explicitly
  "after mygo": same native-UI-on-GPU shape in the manner of GPUI.
  Metal+CoreText on macOS/iOS, GTK3+GL3.3 or own CPU raster on Linux,
  Win32 on Windows, NativeActivity+GLES3 on Android — **every platform
  builds from any machine**, no cgo, no C shims, ~0.7MB apps, zero
  polling. Apps (submodules): **nanoterm — a Warp-like terminal with
  ACP agents** — nanomon, nanostudio, nanofly.

**What this file is:** the compiled vocabulary checklist + triage for
the component/material/visualizer challenges. Neither is portable code
— mygo is Go, nanoui is upstream Zig — the value is what two mature
native toolkits carry, and which pieces the custody plane actually
wants. nanoui is the closer read: same language, same instanced-Metal
idiom, GPUI-shaped element grammar that maps almost 1:1 onto tor
grammar.

## Widget vocabulary — merged

| Group | mygo (`ui.*`, ~89 ctors in gallery) | nanoui (`ui` + `kit`) |
|-------|------------------------------------|------------------------|
| Structure | Box, Row, Column, Grid, Scroll(+Both), Split, Sidebar(+Item/Section), Tabs, Accordion(+Item), Collapsible, FitContent, Fixed, Fr, Spacer, View | column, row, card, scroll, spacer, divider, kit.tabs, kit.accordion, kit.collapsible, **div() fluent builder** (row/gap/pad/grow/items/justify/bg/border/rounded/shadow/glass/clip/scroll/absolute/layer/scale/motion/hover/clicked) |
| Text | Text, Textf, EditableText, TextArea, TextInput, SearchField, RichText, FindBar, TokenField | text, textf, rich, heading, label, kbd, **textfield** (selection+IME+clipboard, NSTextInputClient), keymap (emacs+vim) |
| Buttons | Button, PrimaryButton, Back/ForwardButton, Link, Icon, MenuButton, Toolbar, Toggle(+Group), Segmented | pressable, button, toggle, segmented, icon, kit.button variants |
| Input | Checkbox(+Group), Radio(+Group), Switch, Select, Combobox, Autocomplete, Slider, RangeSlider, StepSlider, Stepper, NumberInput, Date/TimeInput, Calendar, ColorWell, Rating, Form/Field/Fieldset | checkbox, toggle, slider, kit.select, kit.radio, kit.number, kit.field, kit.tokens |
| Data display | List, Table, OutlineTable, Tree(+Item), GridView, Breadcrumbs, Badge, Avatar, Meter, Progress, Spinner | **list (virtualized uniform_list)**, badge, progress, kit.breadcrumb, kit.avatar+initials, kit.tag, kit.status, kit.pagination, kit.ring, kit.skeleton, kit.empty |
| Overlay | Modal, AlertDialog, Popover, Toast, Tooltip, Menu, Inspector | kit.dialog, kit.alert, kit.popover, kit.tooltip, kit.menu, kit.sheet, kit.toast |
| Misc | Image, SVG, DragDrop, DragSelect, CellSelect, FocusGroup, Router, Tester | image, texture (BGRA atlas), key, kit.place |

## Subpackage surfaces

**mygo:**
- `ui/chart` — marks+scales grammar: Line, Area, Pie, Plot, Point,
  Rect, Sector, Stack(+Normalized), RuleX/Y, Nearest/Select scrubbing;
  NewLinear/NewBand/NewTime; Axes/Tick/X/Y.
- `ui/editor` — Editor/EditorBase + **DiffView**; Default{Bindings,
  Completions, FindBar, GoToLine, GutterButton, Hover, HunkActions,
  Theme}; LanguageFor/Named.
- `ui/markdown` — View + **Stream**: Reveal AtOnce/ByCharacter/ByWord/
  ByLine/BySentence/ByParagraph — incremental markdown built for
  streamed replies (`markdown-chat` example).
- `ui/richtext` — Document/Paragraph/Run + Attributes, Bullets,
  Numbers, Tasks; Editor.
- `ui/shader` — user fragments: Fragment, LayerEffect, ColorEffect,
  DistortionEffect, **backdrop effects**, Metal+GL+CPU pixel-equal.
- Plugins: terminal (libghostty-vt/purego), glass, loading(29),
  game/gamepad, sqlite, websocket, updater, fetch, watch.

**nanoui:**
- `ui/glass.zig`+`glass.metal` — **Liquid Glass as a data structure**:
  `Material{bezel,refraction,rim_width,blur,low,high,curve,saturation,
  tint}` — backdrop downsample+Gaussian, lens-bent rim; Metal and CPU
  compute the same steps, measured against AppKit's NSGlassEffectView.
- `ui/motion/` — springs, tweens, presence, keyframes, **layout
  animation**, stagger, channel/store — a motion vocabulary, not
  per-widget ad-hoc.
- `ui/text.zig`+`shaper.zig`+`atlas.zig` — glyph/SF-Symbol atlas,
  cached layouts/wrap, fast ASCII shaper; `ui/tt/` own TrueType stack
  for non-Apple platforms; `png_decode` in-house.
- `ui/tester.zig` — windowless views: scripted input, clock, **PNG
  snapshots**; `--nanoui-snapshot/--nanoui-script/--nanoui-eval` ship in
  every app binary.
- `hillclimb/` — headless benchmark harness *against mygo*, history
  tracked; `tools/reel/` composite example views (board, chat, glass,
  weather, music, trade chart).
- Discipline: 600-line file cap enforced by `zig build lines`; idle
  apps draw zero frames; every fast path must pixel-match its slow path
  (shaper, raster↔Metal, GL↔CPU).

## nanoterm — the ACP reference implementation (deep read)

`apps/nanoterm` (submodule → `github.com/justrach/nanoterm`): a Warp-like
terminal where agent sessions are first-class. The pieces that matter:

- **`acp.zig` (176 lines)** — the whole protocol: JSON-RPC 2.0 over
  ndjson stdio, pending-callback map, `request/notify/respond/
  respondError`. No SDK, pure Zig + `std.json`.
- **`agents.zig`** — dispatch table (graff, claude, codex, opencode,
  grok, **devin**, hermes) with installers + `searchPath()`: appends
  `~/.local/bin`, `~/.harness/bin`, etc. when spawning — the launchd
  PATH hole we patched by hand is already solved machinery here.
- **`agent.zig` — the turn model.** `Turn{prompt, items, sent, done}`
  where `Item = union{ text, thought, tool{kind,status,detail,block},
  plan[], permission{rpc_id, options[], chosen}, command→pty block,
  note, visual }`. Two items map straight onto OMNI law:
  - `permission` — an agent request parked in the turn until answered;
    `answer(p, index)` discharges the rpc. That IS our center-click
    approval surface, already modeled.
  - `visual` (`showVisual(title, script)`) — an agent pushes a *live
    visual* into its own turn. Their escape hatch is our normal case:
    the agent minting a resource on the plane.
- **`session.zig`** — `Entry = union{ block: pty-block, turn: Turn }`:
  a session interleaves shell blocks and agent turns;
  `Mode{terminal, agent}` toggles per session.
- **Views decomposed per concern**: view_turn, view_sidebar (session
  list), view_palette, view_pane, view_signins, view_settings — a
  worked example of session-UI layout without a browser.
- `mcp_server.zig` (150 lines) — they also *host* MCP for the agents.

### Port map — what a Koru-native `libs/acp` actually needs

Dependency-ordered, scouted against our tree (Zig 0.15.2 emitted; nanoterm
targets 0.17 — the externs are stable, `std.Io`/`std.json` call sites need
adapting at the seams):

1. **`proc_posix.zig` (263L)** — `posix_spawnp` + pipe dup2 +
   `O_NONBLOCK` + `Tail` stderr ring. Pure externs; our std only has
   blocking `Child.run` in ~zig bodies, so this is genuinely new
   machinery — and it's a ~proc host-verb shape already.
2. **`acp.zig` (176L)** — ndjson JSON-RPC on the pipes. `std.json` 0.15
   covers parse/stringify inside ~zig bodies; the pending-callback map
   becomes store rows or plain Zig in the proc layer.
3. **`agents.zig` (67L)** — the `searchPath()` extra-dirs list ports
   verbatim; it is the launchd-PATH fix we hand-rolled.
4. **`agent.zig` (~450L) → Koru, not Zig** — Turn/Item is *data*: this
   is the part that wants to be `std/store` rows + a kind-3 card, not a
   ported struct. Adopt the schema, don't translate it.
5. **`fdwatch.zig` (50L) — skippable for v1.** Their wake is GCD
   `dispatch_source`; ours is already the frame pump — commander's
   `! frame` arm drains `cmd-next` per iteration. `acp.drain`
   (nonblocking read → complete lines → pending requests) slots into
   the same seam; no evented fd watch needed until frames go idle.

Total transport lift: ~440 lines of Zig adapted to 0.15.2, plus the
agent-model portion *rewritten* in Koru where it belongs.

## Already built — where the custody plane is ahead

The gap list is shorter than a raw vocabulary diff suggests. From
`metal/index.kz` + `components/index.kz` + `commander.k`:

- **Materials exist**: `draw.silk` (champagne/pearlescent — the founding
  shader), `draw.glass` (backdrop texture + bezel/refract/rim/aberration
  — nanoui's `Material` shape, already parameterized), `draw.frost`
  (rough/edge/grain/milk), `draw.panel`, `draw.shadow`, `draw.roundrect`,
  `draw.clip.push/pop`. The material challenge builds ON this, not
  toward it.
- **Components exist**: `remote`, `wordmark`, `caption`, `hub`,
  `button`, `waveform` (kind-2, real WAV bytes), `docpage` (kind-0,
  real file bytes) — the visualizer catalog's two entries.
- **Input exists**: key/type/mouse/move/up/drag/scroll + `RemoteData`
  (Siri Remote buttons as events — neither toolkit has this).
- **Headless verification exists**: `offscreen` surfaces + `snap` —
  nanoui's `--nanoui-snapshot` doctrine, already ours.
- **Text exists**: `draw.text` + `text.offset` measurement; the
  transcript seam re-reads `.txt` sidecars per frame — live-updating
  documents for free (what nanoui needs a widget for, we get from the
  file+re-read rule).
- **The custody plane itself** — neither toolkit has it: resources,
  kinds, minted-by-bridge, drift. Their `Item.visual` escape hatch is
  our front door.

## Compiled triage — what the custody plane wants, ranked

**P0 — the ACP/session vertical needs these now:**

1. **nanoterm's Turn/Item model** — `Item = union{text, thought, tool,
   plan, permission, command, note, visual}` is the schema our
   `omni_session_<name>.txt` append-loop should adopt instead of
   flat `you:`/`devin:` lines; `permission{rpc_id, options}` parked in
   a turn is exactly the center-click discharge surface.
2. **`acp.zig` (176 lines, pure Zig)** — the protocol port's reference:
   JSON-RPC over ndjson, pending callbacks, `searchPath()` for agent
   discovery. When the Python scaffold moves to Koru this file is the
   shape.
3. **markdown.Stream + Reveal** (mygo) — session replies stream as
   chunks; a session card wants incremental markdown, not raw appends.
4. **Overlay family** (both) — popover/alert/sheet: the permission
   prompt's visual form.
5. **Collection widgets** (both) — list/tree/sidebar/outline: resource
   pool + session registry as navigable collections; nanoui's
   virtualized `list` is the cheap version, mygo's Tree the richer.

**P1 — near-term kinds and materials:**

6. **editor + DiffView** (mygo) — reading what an agent produced;
   lands once session turns carry tool calls with detail.
7. **chart grammar** (mygo) — marks+scales for drift/staleness depth
   and session telemetry as a kind.
8. **motion vocabulary** (nanoui) — springs/keyframes/layout animation:
   card mint/dismiss/focus transitions as a named system, not one-offs.
9. **Toast** (both) — custody events (minted/discharged/wire results)
   as ambient notices.
10. **pty block as a card kind** — nanoterm's `command→blocks.Block`
    (a live terminal in a turn) mapped to a minted resource kind for an
    agent's terminal cap.
11. **CPU-twin pixel parity** (nanoui `raster.zig` ↔ Metal) — the honest
    pattern for testing `draw.silk`/`draw.glass`/`draw.frost`
    headlessly; a material-challenge testing discipline, not a widget.

**P2 — generic chrome (component-challenge fodder):** text inputs &
IME field, select/combobox/autocomplete, sliders/steppers/number,
checkbox/radio/switch, calendar/date/time, rating, badge/avatar,
progress/meter/spinner/skeleton, breadcrumbs, toolbar, segmented, forms.

**P3 — not ours:** Router, locale/i18n, menus/trays/updater, webview
path, iOS/Android shells (until a platform family day).

## What the pair proves for us

Two independent teams shipped full retained-mode toolkits on their own
GPU backends, no browser. nanoui additionally proves it in **our
language** at 0.7MB binaries with a pixel-parity CPU twin — the honest
materials-testing pattern — and its nanoterm app already seats ACP
agents in views. Where we diverge from both: their widgets are authored
content on a canvas; ours are kind-dispatched renderers on a custody
plane. Their catalogs are checklists; ours is a law — but the checklist
tells us which kinds to dispatch next.
