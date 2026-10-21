---
type: belief
id: frag-a-proc-body-name-is-a-consumer-facing-binding
provenance: session
ts: 2026-10-21
---

A `~proc |zig` body's internal identifiers become part of the consumer's
scope after inlining — an internal name as generic as `rc` is a
consumer-facing binding and can silently capture the consumer's own
`! cmd` binding in `then` branches. Proc-internal names must be
hygienic (`__`-prefixed); the compiler currently does not enforce this.

The nl pixel oracle caught this concretely. `spec_snap_nl.k` binds the
drained command as `! cmd rc`, then draws inside `| then |> draw.rect(
..., rc.r, ...)`. `nl.each`'s proc body iterates `for (cl.cmds.items)
|*rc|` — the raw internal `Cmd`, whose color channels are 0-255. The
emitted code materialized the yielded `CmdView` as `__koru_bind_217_20`
and bound the `if` condition and the print to it correctly — but inside
the `then` branch, `rc.x`/`rc.r` resolved to the loop variable instead.
Every command drew with raw 0-255 channels, which the shader clamps to
opaque white: three floating subtrees rendered as white boxes while the
printed command stream was byte-identical to Clay's.

The diagnosis path matters: identical command streams, identical draw
call sites, divergent pixels. Literal-color probes (red → red, black →
black) proved the draw path and geometry were fine; the emitted Zig
(`output_emitted.zig`) then showed the two resolutions side by side —
`__koru_bind_217_20.r` for print/`if`, raw `rc.r` for `then`. `clay.each`
never hits this because its loop variable is `__rc`.

Two distinct defects sit under one symptom, and they should not be
merged. The first is a library-hygiene invariant: inlined proc bodies
must not export non-`__` names into consumer scope — fixed in `nl.each`
(`rc` → `__rc`), matching `clay.each`. The second is a compiler
scope-resolution inconsistency: `rc` bound differently in the `if`
condition (the `! cmd` yield) versus the `then` branch (the proc-local
loop variable) inside the SAME arm — worth reporting to the koru
session as a wart even though the hygiene fix removes the trigger.

Corollary for proc authors and reviewers in this codebase: when a proc
yields via `cmd(...)`, grep the proc body for bare identifiers that
collide with plausible consumer binding names (`rc`, `cmd`, `c`, `el`,
`f`, `w`, `h`) — the collision is invisible in the proc's own tests and
only fires when a consumer binds the same name inside a `then` arm.
The check that could have falsified this earlier is the pixel oracle
itself: command-stream equality is necessary but not sufficient, since
the capture happens below the stream's projection.
