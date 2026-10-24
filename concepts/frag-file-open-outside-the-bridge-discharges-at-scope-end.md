---
type: belief
id: frag-file-open-outside-the-bridge-discharges-at-scope-end
provenance: session
ts: 2026-10-24
---

`app/omni_img:file-open` returns `string<open!>` — a handle carrying an
obligation. When the binding that received it dies, the compiler
discharges the obligation by emitting `file-close` at scope end. A
direct call whose `| ok h |>` arm ends immediately produces a
mint-then-close: `res-live` reads 0 for every slot even though the
mint printed `ok` and returned a handle.

Resources that must outlive the call have two honest shapes:

- Keep the obligated binding open — `code_codeview.k` mints at program
  top level, so `h` stays in custody until exit.
- Mint through `std/bridge:run` — the bridge's turn string holds
  custody, the resource is bridge-resident, and the file-closes fire
  at `bridge:close`, not at your scope boundary (observed emitted
  Zig: `file_close` inserted as the last statement of the `ok` arm).

The res-* seam (`res-live`, `res-kind`, `res-path`, `res-doc-*`) reads
the pool regardless of who minted, so a bridge-minted slot is the
stable handle for components — scan by `res-path` when two resources
share a kind.
