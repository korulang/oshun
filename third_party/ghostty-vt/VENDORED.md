# Vendored: libghostty-vt

Ghostty's virtual-terminal emulation core, consumed as a static C archive.
Oshun owns painting (the renderer is ours); this supplies the emulation
brain — vt parsing, screen/scrollback state, styles, cursor.

## Pin

- upstream: github.com/ghostty-org/ghostty
- commit:   cec8b92f1ecd176a20a56aa405021e7ae991b996 (tip, 2026-10-25)
- API:      unstable per upstream header — "breaking changes are expected".
            The pin is deliberate; bumping it is a reviewed act, not a pull.

## Artifacts

- `lib/libghostty-vt.a`      — arm64 static archive (12.6 MB)
- `include/ghostty/**`       — installed C headers
- `LICENSE`                  — MIT, verbatim from upstream

## Rebuild

Ghostty tip requires Zig 0.17.0 (the repo's zig 0.15.2 cannot build it —
`minimum_zig_version` in build.zig.zon). The archive is a plain C-ABI
artifact once built: the consumer toolchain version does not matter.

    git clone https://github.com/ghostty-org/ghostty && cd ghostty
    git checkout cec8b92f1ecd176a20a56aa405021e7ae991b996
    /path/to/zig-0.17.0 build -Demit-lib-vt -Doptimize=ReleaseFast
    cp zig-out/lib/libghostty-vt.a lib/
    cp -R zig-out/include/ghostty include/

The xcframework packaging step fails on a bare macOS box (xcodebuild
exit 70); the artifacts above are produced before it — ignore it.
