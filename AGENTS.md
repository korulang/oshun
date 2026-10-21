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
