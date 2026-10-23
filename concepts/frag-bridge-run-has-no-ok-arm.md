---
type: belief
id: frag-bridge-run-has-no-ok-arm
provenance: session
ts: 2026-10-23
---

A caller of `std/bridge:run` may not declare `| ok o` — the call's
declared branch set is `result`, `error`, `defined`, `residue`,
`unhandled-branch`, `partial`. KORU021 refuses the arm outright.

When a wire verb like `file-open` succeeds, its own `ok` arm is
surfaced to the caller as `unhandled-branch` with branch name `ok` —
so a status line reading "unhandled ok" is a *successful* mint, not a
failure.

The `ok` is armable — but in the wire source, not the call site.
`file-open(path: "...") | ok h |> say(text: "...")` arms the step's
branch inside the turn string; the handle binds to `h` and the turn
keeps going (440_049 pins both arm shapes). KORU021 only refuses `ok`
on the `run` call itself, where the armable set is the run's declared
outcome branches.

And a multi-item turn never returns `result` — `bridge.run-exec`
hands every multi-step turn back as `partial` carrying the per-step
report, even when every step succeeded. `result` is single-item only.
Boot sequences that mint several resources must hang their
continuation off the `partial` arm; a `| result _ |>` continuation
on a multi-item mint is silently dead code.

Ruling written after committing a consumer-side `| ok` arm that could
never compile — the second time this shape was guessed instead of
checked — then corrected by the wire-arm pinning and the partial
verdict while repairing viz_audio. Check the tor's declared arms
before naming a new one, and check the turn's arity before choosing
which outcome arm carries the continuation.
