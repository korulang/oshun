# Oshun

Oshun is OMNI's host surface. `SCENE.md` is the north star;
`.claude/skills/oshun-toolchain/SKILL.md` is the fast-clock orientation
map — read it first.

## Sibling: the toolchain — `../koru`

Oshun does not build standalone. Consumers compile through `koruc`, which
lives in the sibling repo at `../koru` (`~/src/koru`,
`zig-out/bin/koruc`, symlinked to `/usr/local/bin/koruc`). Its own
orientation material:

- `../koru/.claude/skills/koru-toolchain/SKILL.md` — the toolchain
  description: how to compile, how the four-stage metacircular pipeline
  runs, where the suite lives, what bites.
- `../koru/koru-tutorial.md` — the language in a page; read before
  writing Koru.
- `../koru/AGENTS.md` and `../koru/CLAUDE.md` — the rules this repo
  inherits: a `koruc` wall is a compiler bug and the fix lands in koru,
  never a consumer workaround; syntax is Lars's; the regression suite is
  the spec, not prose.

Module resolution from here is `koru.json` `paths`:
`"std": "../koru/koru_std"`, `"koru"`/`"libs": "../koru-libs"`,
`"oshun": "."` — a consumer's own koru.json sets `"oshun"` to this repo.

## Dictate workstream (branch dictate-overlay)

Native macOS dictation agent — the Koru/Oshun toolchain exercise.
Commits: `3fa31d7` overlay · `a19c704` hotkey · `c07a15a` mic ·
`c3a4e78` paste · `e5a9f94` spike+pump arbitration · `98c1bac` stale
singleton fix + mic.dump + rebind.

### Run

    cd ~/src/oshun/.claude/worktrees/dictate
    ~/src/koru/zig-out/bin/koruc run host/tests/dictate.k

Focus a text field. HOLD Ctrl+Option+Period to dictate (overlay shows,
bar = live RMS, `stream:` JSON per chunk); release → `stream.stop` JSON
→ `paste.text`. Ctrl+Option+Q quits. Needs mic permission; paste needs
AX/Input-Monitoring for the host terminal.

### API surfaces added

- `window.overlay { width, height, radius }` + `window.show`/`hide` —
  borderless floating click-through, opens hidden, policy-neutral;
  `windowCore` shared with `window.open`. `frames` exits when
  isVisible=false → show→frames→hide is the summon lifecycle.
- `hotkey.watch { key, mods }` + `unwatch` + `action` (synthetic) —
  Carbon RegisterEventHotKey, no AX grant; `HostEvent.hotkey` on the
  shared ring; both `host.run` and `frames` dispatch `! hotkey`.
- `mic.start/stop/level/read/dump` — VPIO (auou/vpio), BOTH elements
  enabled + BOTH edges formatted (paired unit; Initialize rejects
  half-open -10875), 16k f32 mono negotiated+readback, render callback
  on output elem pulls bus-1 via AudioUnitRender, 30s f32 ring. err =
  OSStatus*100+step. `mic.dump` writes f32le — the zeros oracle.
- `paste.text`/`paste.read` — NSPasteboard + CGEventPost Cmd+V;
  pasteboard verified; keystroke needs AX grant, silent when denied.
- `drain_paused` in host — nested pump (frames inside a host.run arm)
  owns the drain while it runs; set/cleared by `frames`.
- `live_win`/`frame_cb` now cleared on window.close / frames exit —
  second-press UAF crash fixed (98c1bac).

### Worktree wiring (uncommitted, consumer-side)

- `needle` → symlink to koru-libs worktree package
  (`~/src/koru-libs/.claude/worktrees/needle/needle`, vendor dylib inside).
- `host/vendor` → symlink to `../needle/vendor` — satisfies needle's
  `.cwd_relative="../vendor"` requires. REAL GAP: build:requires has no
  package-relative anchor; vendored-dylib packages force consumers to
  arrange `../vendor`. Belongs in koru build:requires.

### needle (koru-libs worktree, branch needle-pkg @ 63f30b5)

`libs/needle`: `load(path) | ready *Engine<ready!>` →
`transcribe`/`stream.process`/`stream.stop` → `unload`. Whistle
weights: `~/.cache/cactus-needle/whistle/2.0.0/whistle.cact`.
VERIFIED: live streamed dictation — committed words w/ timestamps at
15-40ms per 0.5s chunk. Chunk JSON: `text` = committed BY THAT CHUNK,
`pending` = unconfirmed tail; transcript = JOIN of chunk texts + final
pending. stop JSON carries only the tail — do not paste it raw.

### SOLVED: KORU031 choke merge

The rule (src/ast_transform.zig:581-600): choke handlers replicate at
EVERY stage of a `|>` chain and same-name variants across stages must
carry agreeing payloads — `stream.stop`'s `| ok` (string) collided with
`paste.text`'s `| ok` (none) at one level. Legal shape: keep each
chain's same-name variants homogeneous (all `(none)`-ok inside
`stop`'s `| ok` continuation; `string`-ok only at stop's level).
`content` was ruled illegal by KORU095 (borrows flow down, never up —
the consumer takes the handle): `paste.string` takes `*String` directly.
Uncommitted in `~/src/koru` awaiting ruling, NOT route-arounds:
- `string.make { text } -> *String<instance!>` — single-yield ctor
  (from-page/new are `| ok`|err`; a ctor doesn't need branches).
- `json.get.string.opt { json: string<*>, key } -> string<allocated!>`
  — owned "" on miss; chains stay point-free.
Both are needed by dictate.k's accumulate+paste (now compiling).

### Deferred

- fn/globe modifier-only keys: not Carbon-expressible — needs NSEvent
  flagsChanged or IOHID verb (separate path, not approximated).
- `remote.watch`: hidEnsure only runs in `frames`; tray-only host.run
  agents never start the remote listener.
- App repo + measured hotkey→visible latency claim.
