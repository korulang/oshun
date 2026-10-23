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
failure. If a consumer wants the minted handle in its status text,
the change belongs at the bridge/wire-reporting level (map verb ok
into `result` carrying the handle), not in a consumer arm.

Ruling written after committing a consumer-side `| ok` arm that could
never compile — the second time this shape was guessed instead of
checked. Check the tor's declared arms before naming a new one.
