---
type: belief
id: frag-a-zig-ref-inside-a-proc-body-does-not-emit-the-target-module
provenance: session
ts: 2026-10-21
---

koruc emits a module's `koru_<name>` struct when the program's AST
references that module's decls or types. A `@import("root").koru_libs.X`
inside a `~proc` body is invisible to that pass — so a cross-module Zig
dependency only survives if something in the *Koru layer* of the same
program already forces the target module to emit.

Found the hard way splitting oshun/host out of metal: metal aliased
host's bridge through `const H = @import("root").koru_libs.koru_host`,
with `import libs/host` beside it. A frames-using program compiled
(`frames`'s `! ?tray-action libs/host:TrayActionData` signature forced
emission); an offscreen-only program loaded the host AST — 290 merged
items — and emitted `koru_libs` containing only `koru_metal`, so the
`H` reference failed in Zig with `no member named 'koru_host'`. The
import being *loaded* is not the import being *emitted*.

The design consequence that survived: keep cross-module Zig refs on
paths whose tor signature names the target module (the signature is
the emission proof), or on paths a phantom obligation makes
co-obligatory (`window.open` may reach `H` because KORU030 forces
`frames`, and `frames` forces host). A module-scope `const H =
@import(...)` is lazily analyzed — harmless to leave at top level —
but any *alias chain* (`const sel = H.sel`) pulls the reference onto
every path that uses the alias, which is what broke offscreen.

Open question, filed for the koru work it predicts: whether koruc
should treat a resolved `@import("root").<ns>.<mod>` inside an emitted
proc body as a module-edge for its collector. Until it does, the
signature-forces-emission discipline above is the contract.
