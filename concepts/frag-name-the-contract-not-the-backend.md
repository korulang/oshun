---
type: belief
id: frag-name-the-contract-not-the-backend
provenance: session
ts: 2026-10-14
---

A package's name names the contract, never one of its backends.
`libs/metal` carried Apple's API name while hosting two platform bodies —
`index.macos.kz` (ObjC/Metal) and `index.koru-native.kz` (freestanding
software rasterizer over `koruos/surface`, proven compositing on the
T590). The name described whichever backend happened to be written
first, and lied about every other arm the part gate could select.

Renamed to `libs/canvas`: the verbs (`window.*`, `frames`, `draw.*`,
`clip.*`, `input.*`) are a 2D window/draw/input surface; "canvas" is the
role, and `index.<platform>.kz` parts remain the indirection. The same
convention `libs/host` already embodied — host services, platform parts.

The rejected alternative was a second, differently-named native package.
That forks the contract at the import line: consumers would write
`import libs/metal` on macOS and `import libs/raster` on native, leaking
platform awareness into every call site — exactly what
`~[build == X]part` selection exists to eliminate. One contract, many
bodies, dormant bytes for the unselected arm; the directory name is
cosmetic to that mechanism but must not re-import the backend's name.

Open question: Omni's surfaces are not window-centric, so this contract
will likely grow surface-level verbs. The rename was done *before* that
design lands deliberately — naming once with the full contract in view,
rather than twice.
