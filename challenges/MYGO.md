# MYGO SURVEY — the egoist/mygo component vocabulary

Surveyed 2026-10-23 → `github.com/egoist/mygo` @ main, 2.8k★, MIT.
Source-of-truth inventory: `/tmp` clone `examples/gallery/*.go`
(the toolkit tour) + public constructors in `ui/*.go` and the
`ui/{chart,editor,markdown,richtext,shader}` subpackages.

**What mygo is:** a Go desktop-app framework — windows hosting either
system webviews or **native UI it draws itself** (`package ui`,
retained-mode, per-platform GPU backends: Metal on darwin, GL on
linux/windows, WebGL2 for `GOOS=js/wasm`). Same architectural family as
OMNI: own renderer, own widgets, no browser in the middle.

**What this file is:** a vocabulary checklist + triage for the
component/material/visualizer challenges. Not portable code — mygo is
Go/stdlib-shaped; the value is what a mature native toolkit carries and
which pieces the custody plane actually wants.

## Core widgets (ui/, ~89 public ctors in the gallery)

| Group | Widgets |
|-------|---------|
| Structure | Box, Row, Column, Grid, Scroll, ScrollBoth, Split, Sidebar(+Item/Section), Tabs, Accordion(+Item), Collapsible, FitContent, Fixed, Fr, Spacer, View |
| Text | Text, Textf, EditableText, TextArea, TextInput, SearchField, RichText, FindBar, TokenField |
| Buttons/actions | Button, PrimaryButton, BackButton, ForwardButton, Link, Icon, MenuButton, Toolbar, Toggle(+Group), Segmented |
| Input | Checkbox(+Group), Radio(+Group), Switch(+Base), Select(+Base), Combobox, Autocomplete, Slider, RangeSlider, StepSlider, Stepper, NumberInput, DateInput, TimeInput, Calendar, ColorWell, Rating, Form, Field, Fieldset, Key |
| Data display | List, Table, OutlineTable, Tree(+Item), GridView, Breadcrumbs, Badge, Avatar, Meter, Progress, Spinner |
| Overlay | Modal, AlertDialog, Popover, Toast, Tooltip, Menu, Inspector |
| Misc | Image, SVG (MustParseSVG), DragDrop, DragSelect, CellSelect, FocusGroup, Router, Tester, TesterClick |

## Subpackage surfaces

- **`ui/chart`** — Line, Area, Pie, Plot, Point, Rect, Sector, Stack
  (+Standard/Normalized), RuleX/Y, Anchor, Extent, MinMax, Nearest,
  Select, SliceAt; scales NewLinear/NewBand/NewTime; Axes, Tick, X/Y,
  Side, CurveMonotone. A small grammar of marks+scales, not chart types.
- **`ui/editor`** — Editor/EditorBase, DiffView; Default{Bindings,
  Completions, FindBar, GoToLine, GutterButton, Hover, HunkActions,
  Separator, Theme}; LanguageFor/LanguageNamed — a real code editor
  with diff viewer (the `code-editor` example).
- **`ui/markdown`** — View + **Stream** with Reveal modes: AtOnce,
  ByCharacter, ByWord, ByLine, BySentence, ByParagraph — incremental
  streaming markdown, the `markdown-chat` example's whole trick.
- **`ui/richtext`** — Document/Paragraph/Run, Attributes, Bullets,
  Numbers, Tasks, Editor, FormatOn — the `notes` example.
- **`ui/shader`** — user fragment shaders: Compile/MustCompile,
  Fragment, LayerEffect, ColorEffect, DistortionEffect, **backdrop
  effects** (shader over what's already drawn), wide color, Metal +
  OpenGL + CPU-twin codegen tested pixel-equal.

## Plugins (mygo-plugins/*, Go + optional npm twin)

terminal (libghostty-vt via purego, in native UI), glass (backdrop-blur
scene effect, Metal/HLSL/GLSL + CPU twin), loading (loading.dev's 29
indicators via `ui.Painter`), game (loop, camera, gamepad), sqlite,
websocket, updater, fetch, watch.

## Architecture notes worth lifting

- No cgo anywhere — purego FFI; OMNI's Zig layer is already freestanding.
- "Apps pay only for what they use" — binary-size gates in CI,
  linker-keep discipline via registered constructors (no reflect.Method).
- `ui.Tester` + fake backend + `internal/e2e` real-GUI tests; tests never
  wait on wall-clock — deterministic clock advance (our snap probes are
  the same doctrine, weaker).
- Inspector overlay + framestats shipped in-tree (`mygo_noinspector`
  build tag for release).
- Input-latency benchmark as a first-class internal tool
  (`internal/inputlatency` — input-to-screen on macOS).

## Triage — what the custody plane wants, ranked

**P0 — the ACP/session vertical needs these now:**

1. **markdown.Stream + Reveal modes** — session replies stream as
   chunks; a kind-3 session card wants incremental markdown, not raw
   text appends. Closest thing to "the missing piece" this week.
2. **ui/editor + DiffView** — working through OMNI means reading code
   and diffs an agent produced. FindBar/GoToLine/Hover/Gutter already
   exist as a coherent grammar to copy.
3. **Popover / AlertDialog / Menu** — the fs/terminal capability
   permission surface: agent asks, focused card prompts, center-click
   discharges. mygo's modal family is the vocabulary for it.
4. **List / Tree / Sidebar / OutlineTable** — the resource pool and the
   session registry as navigable collections; today's pool is a flat
   orbit with no hierarchy.

**P1 — kinds the visualizer challenge will hit soon:**

5. **chart grammar** (marks + scales, Select/Nearest scrubbing) —
   drift/staleness depth, session token use, capture health. A kind for
   structured data, not a widget.
6. **Toast** — custody events (minted/discharged/wire results) as
   ambient notices instead of cards.
7. **shader effect model** — Fragment/LayerEffect/DistortionEffect with
   *backdrop* reads + CPU-twin pixel parity: the material challenge's
   compositional shape (champagne is a material; an *effect stack* is
   what silk-over-sessions wants).
8. **terminal plugin pattern** — a libghostty-vt surface as a card kind
   would let an ACP session's terminal cap render into the plane.

**P2 — generic chrome, component-challenge fodder:**

9. Text inputs/textarea/search, Select/Combobox/Autocomplete,
   Slider/Stepper/NumberInput, Checkbox/Radio/Switch family,
   Calendar/Date/Time, Rating, Badge/Avatar, Progress/Meter/Spinner,
   Breadcrumbs, Toolbar, Segmented, form scaffolding.

**P3 — app-shell concerns OMNI doesn't share:** Router, locale/i18n,
window/menu management, updater plugin, webview path (we draw our own
always).

## What mygo proves for us

A single binary can carry a full retained-mode widget set on its own
GPU backend without a browser — the "impossible" version of OMNI is a
*smaller* version of this. Where we'd diverge: every one of their
widgets is authored content on a canvas; ours is kind-dispatched
resource rendering on a custody plane. Their catalog is a checklist;
ours is a law.
