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

## Compiled triage — what the custody plane wants, ranked

**P0 — the ACP/session vertical needs these now:**

1. **markdown.Stream + Reveal** (mygo) — session replies stream as
   chunks; kind-3 session card wants incremental markdown, not raw
   appends.
2. **editor + DiffView** (mygo) — reading what an agent produced is
   the work-through-OMNI core loop.
3. **Overlay family** (both) — popover/alert/sheet = the permission
   surface for fs/terminal caps; center-click discharges.
4. **Collection widgets** (both) — list/tree/sidebar/outline: resource
   pool + session registry as navigable collections; nanoui's
   virtualized `list` is the cheap version, mygo's Tree the richer.
5. **nanoterm's ACP shape** — someone already built "agent sessions in
   a native UI" on this stack; worth reading how they seat agents in
   views (submodule, needs a real clone).

**P1 — near-term kinds and materials:**

6. **Liquid Glass material** (nanoui) — the `Material` struct IS our
   material challenge's data shape; bezel/refraction/rim/tint params
   map onto champagne/pearlescent directly, and the Metal+CPU
   pixel-parity pattern is how to test a material honestly.
7. **chart grammar** (mygo) — marks+scales for drift/staleness depth
   and session telemetry as a kind.
8. **motion vocabulary** (nanoui) — springs/keyframes/layout animation:
   card mint/dismiss/focus transitions as a named system, not one-offs.
9. **Toast** (both) — custody events (minted/discharged/wire results)
   as ambient notices.
10. **terminal pattern** (mygo plugin; nanoterm is the lived version) —
    a pty surface as a card kind for an agent's terminal cap.

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
