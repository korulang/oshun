// OMNI component gallery — the catalog surface. Same machinery as
// clay/tests/gallery_comp.k (spec rows expanded per frame into view's
// primitive rows, emit walks view blind), promoted into a real app:
// a sidebar lists every catalog component from [entries] and the stage
// renders the selected tor inside a champagne card — components are
// drawn by their real signatures, on a composed surface, never alone
// on black.
//
//   spec row kinds: panel, text (primitive copy-through) and
//   list, stage (composite — expand inline)
//   view row kinds: panel, clip, text — the only vocabulary emit knows
//
//   entries.tork dispatches post-emit: 0 hub, 1 button, 2 caption,
//   3 wordmark, 4 remote, 5 waveform, 6 docpage. Landing a new catalog
//   entry = one insert row + one dispatch arm + one CATALOG.md line.
//
// Resource-kind components (waveform/docpage) draw real minted
// resources: the app file-opens a session wav and SCENE.md at startup
// and scans res-max for their slots — the same custody plane the
// bridge apps use, no stubs.
//
// Scripted twin: input drivers select entries on fixed frames, window
// snaps at each pick, quits at 40. `live` arg holds the window.
//
import libs/metal
import libs/host
import libs/clay
import libs/ui
import libs/components/index
import libs/components/code_codeview
import libs/components/code_diffview
import libs/components/code_turnview
import libs/components/term_termview
import libs/components/flow
import libs/components/dome
import libs/components/glasscard
import libs/components/lens
import libs/components/avatar
import libs/math
import libs/vt
import app/omni_img
import oshun
import std/args
import std/bridge
import std/store
import std/io
import std/string
import std/fmt
import std/ctx

std/store:new(world) {
    frame: 0[i64], sel: -1[i64], hover: -1[i64], down: -1[i64],
    ic: 0[i64], clipn: 0[i64], r0: 0[i64], r1: 32[i64], icount: 0[i64], live: 0[i64],
    mx: -1.0[i64], my: -1.0[i64], pdown: 0[i64],
    stageh: -1[i64], wavslot: -1[i64], docslot: -1[i64],
    codeslot: -1[i64], diffslot: -1[i64], termh: -1[i64], seltork: -1[i64], termsel: -1[i64],
    tex: -1[i64], gtex: -1[i64], face: 0[i64], cface: -1[i64], dface: -1[i64], tface: -1[i64],
    fu: -1[i64], psel: -1[i64], dive: 0[i64], coghot: 0[i64],
    mood: 0[i64], atork: -1[i64],
    v0: -1[i64], v1: -1[i64], v2: -1[i64], v3: -1[i64],
}
std/store:new(fworld) {
    scroll: 0.0[f64],
    lx0: 0.0[f64], ly0: 0.0[f64], lx1: 240.0[f64], ly1: 600.0[f64],
    sx0: 0.0[f64], sy0: 0.0[f64], sx1: 1.0[f64], sy1: 1.0[f64],
    cx0: 0.0[f64], cy0: 0.0[f64], cw: 0.0[f64], ch: 0.0[f64],
    ft: 0.0[f64], fe: 0.0[f64], fx0: 0.0[f64], fy0: 0.0[f64], frt: 0.0[f64], fb: 0.0[f64],
    rx: 0.0[f64], ry: 0.0[f64], rw: 0.0[f64], rh: 0.0[f64], ba: 0.0[f64], ha: 1.0[f64],
    dt: 0.0[f64], da: 0.0[f64], sa: 0.0[f64], shy: 0.0[f64], ft0: 0.0[f64], dt0: -1000.0[f64],
    ddx: 0.0[f64], ddy: 0.0[f64],
}
std/store:new(wins) { w: 1000.0[f64], h: 620.0[f64] }
std/store:new(hit, capacity: 128) { seq: i64, cl: i64, x: f64, y: f64, w: f64, h: f64 }

// Entry-handle set — refilled each frame from the entries query; a click
// on a sidebar row resolves sel by membership here.
std/store:new(uids, capacity: 256) { uid: i64 }

// The catalog — one row per showcased component. tork selects the
// dispatch arm; tx is the tor's name, sub its one-line claim.
std/store:new(entries, capacity: 64) { tx: char[24], sub: char[44], tork: i64 }

// The theme — a blue-tinted paper. std/ctx(theme) fills same-named
// unfilled params at compile time, so ctx-aware components draw from
// the palette instead of hardcoding color. Field names ARE the param
// names: pr/pg/pb paper, kr/kg/kb key, rr/rg/rb rim, ir/ig/ib ink.
std/store:new(theme) {
    pr: 0.90[f64], pg: 0.92[f64], pb: 0.96[f64],
    kr: 0.94[f64], kg: 0.95[f64], kb: 0.98[f64],
    rr: 0.30[f64], rg: 0.50[f64], rb: 0.80[f64],
    ir: 0.14[f64], ig: 0.18[f64], ib: 0.26[f64],
    li: 1.0[f64], lg: 1.0[f64], lb: 1.0[f64],
}

// The AUTHORED tree — spec rows in DFS order.
[tree]std/store:new(spec, capacity: 64) {
    d: i64, kind: char[8], ws: char[8], w: f64, hs: char[8], h: f64,
    dir: char[8], gap: i64, pad: i64, ax: char[8], ay: char[8],
    r: f64, g: f64, b: f64, a: f64,
    n: i64, uid: i64, tx: char[40], fs: f64, ord: i64, hid: i64,
}

// The EXPANDED tree — rebuilt every frame by the pass below.
std/store:new(view, capacity: 512) {
    d: i64, kind: char[8], wk: i64, w: f64, hk: i64, h: f64,
    dir: i64, gap: i64, padl: i64, padr: i64, padt: i64, padb: i64, ax: i64, ay: i64,
    r: f64, g: f64, b: f64, a: f64,
    ox: f64, oy: f64,
    uid: i64, tx: char[40], fs: f64,
}

// The chrome, authored as markup. Sidebar carries the wordmark, the
// manifesto line, and the entry list; the stage is a single clip that
// owns the rest of the window — the component draws there post-emit.
oshun:component(seed, spec) {
    <panel dir="ltr" ws="star" hs="star" gap="0" pad="0" ax="start" ay="start" r="13" g="13" b="18" a="255" ord="0">
        <panel dir="ttb" ws="fix" w="244" hs="star" gap="4" pad="16" ax="start" ay="start" r="21" g="21" b="28" a="255" ord="10">
            <text tx="omni gallery" fs="19" r="240" g="226" b="192" a="255" ord="10"/>
            <text tx="kind-dispatched components" fs="10" r="146" g="142" b="130" a="255" ord="20"/>
            <list uid="1000" ord="30" ws="star" hs="star" gap="4" pad="2" ax="start" ay="start" dir="ttb" r="0" g="0" b="0" a="0"/>
        </panel>
        <stage ord="20" ws="star" hs="star" bind="world.stageh"/>
    </panel>
}

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_gallery_world"): br
|> libs/clay:init(width: 1000, height: 620)
| cl h |> libs/metal:window.open(width: 1000, height: 620, title: "omni gallery — catalog")
    | win w |> libs/metal:window.clear.color(win: w, r: 0.05, g: 0.05, b: 0.07)
            |> seed()
            |> std/args:get(index: 1)
                | arg a |> std/store:stored { world.live: if (a == "live") 1 else 0 }
                | out-of-bounds |> std/store:stored { world.live: 0 }
            // Mint the two resources the resource-kind arms draw — real
            // bytes through the bridge's own wire, so custody stays
            // bridge-resident and the slots outlive this scope.
            |> std/bridge:run(br, source: "file-open(path: \"/tmp/omni_remote_mic_19.wav\") | ok h |> say(text: \"minted wav\")\nfile-open(path: \"/Users/larsde/src/omni/SCENE.md\") | ok h |> say(text: \"minted doc\")\nfile-open(path: \"/Users/larsde/src/oshun/metal/tests/silk_live.k\") | ok h |> say(text: \"minted code\")")
                | result _ |> std/io:print.ln("gallery: resources minted")
                | partial p |> std/io:print.ln("mint partial: {{ p.report:s }}")
                | error e |> std/io:print.ln("mint turn failed: {{ e.message:s }}")
            |> libs/metal:font.load(win: w, path: "/Users/larsde/Downloads/SF-Pro.ttf")
                | font fc |> std/store:stored { world.face: fc }
                | err fe |> std/io:print.ln(fe)
            |> libs/metal:image.load(win: w, path: "/Users/larsde/Downloads/apple-remote.png")
                | img itx |> std/store:stored { world.tex: itx }
                | err ie |> std/io:print.ln(ie)
            // The dome's glass needs a real photograph behind it —
            // frost samples the captured scene, flat fills read as milk.
            |> libs/metal:image.load(win: w, path: "/Users/larsde/Downloads/86474.jpg")
                | img gtx |> std/store:stored { world.gtex: gtx }
                | err ge |> std/io:print.ln(ge)
            // Victoria's faces — the avatar entry's mood set. Four
            // distinct portraits; mood buttons swap the medallion.
            |> libs/metal:image.load(win: w, path: "/Users/larsde/src/armored-rail-assets/output/generated/portraits/victoria/neutral_albedo.png")
                | img v0x |> std/store:stored { world.v0: v0x }
                | err v0e |> std/io:print.ln(v0e)
            |> libs/metal:image.load(win: w, path: "/Users/larsde/src/armored-rail-assets/output/generated/portraits/victoria/smiling_albedo.jpg")
                | img v1x |> std/store:stored { world.v1: v1x }
                | err v1e |> std/io:print.ln(v1e)
            |> libs/metal:image.load(win: w, path: "/Users/larsde/src/armored-rail-assets/output/generated/portraits/victoria/worried_albedo.png")
                | img v2x |> std/store:stored { world.v2: v2x }
                | err v2e |> std/io:print.ln(v2e)
            |> libs/metal:image.load(win: w, path: "/Users/larsde/src/armored-rail-assets/output/generated/portraits/victoria/determined_albedo.png")
                | img v3x |> std/store:stored { world.v3: v3x }
                | err v3e |> std/io:print.ln(v3e)
            // The code-surface components carry their own registry-side
            // font seams — one SF Mono face each, loaded through them.
            |> libs/components/code_codeview:code-font(path: "/tmp/obel/ObelMono-1.002/ObelMono/otf/ObelMono-Regular.otf")
                | font cfn |> std/store:stored { world.cface: cfn }
                | err cfe |> std/io:print.ln(cfe)
            |> libs/components/code_diffview:diff-font(path: "/tmp/obel/ObelMono-1.002/ObelMono/otf/ObelMono-Regular.otf")
                | font dfn |> std/store:stored { world.dface: dfn }
                | err dfe |> std/io:print.ln(dfe)
            |> libs/components/code_turnview:tv-font(path: "/tmp/obel/ObelMono-1.002/ObelMono/otf/ObelMono-Regular.otf")
                | font tfn |> std/store:stored { world.tface: tfn }
                | err tfe |> std/io:print.ln(tfe)
            |> libs/components/code_diffview:diff-load(path: "/tmp/code_diffview_sample.diff")
                | ok dsl |> std/store:stored { world.diffslot: dsl }
                | err dle |> std/io:print.ln(dle)
            |> libs/metal:frames(win: w, count: if (world.live == 1) 999999 else 9999)
                ! frame f
                    |> std/store:stored { world.frame: world.frame + 1, world.clipn: 0 }
                    // TRANSITION CLOCK — flight t (18f), eased lerp of the
                    // flying chip toward the header slot, chip bg dissolve,
                    // header fade-in, and the drill dive's dim/sheet alphas.
                    // stored{} args may not read sibling fields written in
                    // the same call — dependency-ordered calls below.
                    |> std/store:stored { fworld.ft: @min(@max((@as(f64, @floatFromInt(world.frame)) - fworld.ft0) / 36.0, 0.0), 1.0), fworld.dt: @min(@max((@as(f64, @floatFromInt(world.frame)) - fworld.dt0) / 14.0, 0.0), 1.0) }
                    |> std/store:stored { fworld.fe: 1.0 + 2.70158 * (fworld.ft - 1.0) * (fworld.ft - 1.0) * (fworld.ft - 1.0) + 1.70158 * (fworld.ft - 1.0) * (fworld.ft - 1.0) }
                    |> std/store:stored { fworld.rx: fworld.fx0 + (fworld.sx0 + 44.0 - fworld.fx0) * fworld.fe, fworld.ry: fworld.fy0 + (fworld.sy0 + 34.0 - fworld.fy0) * fworld.fe, fworld.rw: (fworld.frt - fworld.fx0) + (150.0 - (fworld.frt - fworld.fx0)) * fworld.fe, fworld.rh: (fworld.fb - fworld.fy0) + (34.0 - (fworld.fb - fworld.fy0)) * fworld.fe }
                    |> std/store:stored { fworld.ba: 0.92 * (1.0 - @min(@max((fworld.ft - 0.5) / 0.5, 0.0), 1.0)), fworld.ha: if (world.fu >= 0) @min(@max((fworld.ft - 0.75) / 0.25, 0.0), 1.0) else 1.0 }
                    |> std/store:stored { fworld.da: (if (world.dive == 1) fworld.dt else 1.0 - fworld.dt) * 0.62, fworld.sa: if (world.dive == 1) fworld.dt else 1.0 - fworld.dt, fworld.shy: (if (world.dive == 1) 1.0 - fworld.dt else fworld.dt) * 26.0 }
                    |> std/store:clear(hit)
                    |> std/store:clear(view)
                    |> std/store:clear(uids)
                    |> libs/metal:window.size(win: w): wh
                    |> std/store:stored { wins.w: wh.w, wins.h: wh.h }
                    |> libs/clay:dims(cl: h, width: wh.w, height: wh.h)
                    // Seed the catalog once; first row's handle is the
                    // landing selection.
                    |> if (world.frame == 1)
                        | then |> std/store:insert(entries) { tx: "flow", sub: "draw.bezier — stroked quadratic curves", tork: 11 }
                            | row h0 |> std/store:stored { world.sel: h0 }
                            |> std/store:insert(entries) { tx: "dome", sub: "neumorphism × glass — soft chrome", tork: 12 }
                                | row _
                            |> std/store:insert(entries) { tx: "glass", sub: "cover-fit photo + frost pane — the minimum", tork: 13 }
                            |> std/store:insert(entries) { tx: "avatar", sub: "round portrait — mood buttons", tork: 14 }
                                | row _
                            |> std/store:insert(entries) { tx: "hub", sub: "the bridge's presence — pearl orb", tork: 0 }
                                | row _
                            |> std/store:insert(entries) { tx: "button", sub: "pressable pill — hover, press, variants", tork: 1 }
                                | row _
                            |> std/store:insert(entries) { tx: "caption", sub: "ink-on-silk centered text", tork: 2 }
                                | row _
                            |> std/store:insert(entries) { tx: "wordmark", sub: "loaded face, measured center", tork: 3 }
                                | row _
                            |> std/store:insert(entries) { tx: "remote", sub: "the input grammar's glyph", tork: 4 }
                                | row _
                            |> std/store:insert(entries) { tx: "waveform", sub: "kind-2 — peaks from the wav's bytes", tork: 5 }
                                | row _
                            |> std/store:insert(entries) { tx: "docpage", sub: "kind-0 — the document's own lines", tork: 6 }
                                | row _
                            |> std/store:insert(entries) { tx: "codeview", sub: "syntax spans off the file's bytes", tork: 7 }
                                | row _
                            |> std/store:insert(entries) { tx: "diffview", sub: "unified diff — hunks, gutters, adds", tork: 8 }
                                | row _
                            |> std/store:insert(entries) { tx: "turnview", sub: "an agent turn — prompt, verdict, tool", tork: 9 }
                                | row _
                            |> std/store:insert(entries) { tx: "term", sub: "ghostty-vt — a live session in a card", tork: 10 }
                                | row ts |> std/store:stored { world.termsel: ts }
                    // Locate the two minted slots by kind — audio kind 2,
                    // doc kind 0; the handles already came back from
                    // file-open, slots derive from the res arrays.
                    |> if (world.frame == 1)
                        | then |> app/omni_img:res-max() : rm
                            |> for(0..@as(usize, @intCast(rm)))
                                ! each si |> app/omni_img:res-live(slot: @as(i64, @intCast(si))) : rl
                                    |> app/omni_img:res-kind(slot: @as(i64, @intCast(si))) : rk
                                        |> app/omni_img:res-path(slot: @as(i64, @intCast(si))) : rp
                                            |> if (rl == 1 and rk == 2)
                                                | then |> std/store:stored { world.wavslot: @as(i64, @intCast(si)) }
                                            |> if (rl == 1 and rk == 0 and rp == "/Users/larsde/src/omni/SCENE.md")
                                                | then |> std/store:stored { world.docslot: @as(i64, @intCast(si)) }
                                            |> if (rl == 1 and rk == 0 and rp == "/Users/larsde/src/oshun/metal/tests/silk_live.k")
                                                | then |> std/store:stored { world.codeslot: @as(i64, @intCast(si)) }
                    // The terminal session — minted once like the other
                    // resources: feed-only + canned bytes for the scripted
                    // twin (pixel-deterministic snaps), a real zsh in live.
                    |> if (world.frame == 1 and world.live == 0)
                        | then |> libs/vt:term-open(cols: 60, rows: 16, cmd: "") : th
                            |> std/store:stored { world.termh: th }
                            |> libs/vt:term-feed(h: th, bytes: "\x1b[1;32momni\x1b[0m \x1b[90m~/src/oshun\x1b[0m\r\n\x1b[32m$\x1b[0m ls components/\r\ncode_codeview.kz   code_diffview.kz   code_turnview.kz\r\nterm_termview.kz  index.kz\r\n\x1b[32m$\x1b[0m ./gallery term\x1b[90m --live\x1b[0m\r\n\x1b[1mterminal surface armed\x1b[0m — ghostty-vt emulation, oshun's own paint\r\n\x1b[32m$\x1b[0m ") : fed
                                |> std/io:print.ln("gallery: term fed {{ fed:d }} bytes")
                    |> if (world.frame == 1 and world.live == 1)
                        | then |> libs/vt:term-open(cols: 60, rows: 16, cmd: "zsh -i") : th2
                            |> std/store:stored { world.termh: th2 }
                            |> std/io:print.ln("gallery: term live session {{ th2:d }}")
                    |> std/store:query(entries)
                        ! query { [row]er, [id]ih } |> std/store:insert(uids) { uid: ih }
                            | row _
                    |> std/store:query(entries)
                        ! query { [row]er2, [ordinal]io } |> std/store:stored { world.icount: io }
                    // The virtual window reads LAST frame's clip box.
                    |> std/store:stored {
                        world.r0: @max(0, @as(i64, @intFromFloat(@floor(fworld.scroll / 56.0)))),
                        world.r1: @min(world.icount, @as(i64, @intFromFloat(@floor((fworld.scroll + fworld.ly1 - fworld.ly0) / 56.0))))
                    }
                    // EXPANSION PASS — spec rows walk in order.
                    |> std/store:preorder(spec, order: "ord")
                        ! preorder s
                            |> if (s.kind == "panel")
                                | then |> std/store:insert(view) { d: s.d, kind: "panel", wk: if (s.ws == "star") 1 else if (s.ws == "fix") 3 else 0, w: s.w, hk: if (s.hs == "star") 1 else if (s.hs == "fix") 3 else 0, h: s.h, dir: if (s.dir == "ttb") 1 else 0, gap: s.gap, padl: s.pad, padr: s.pad, padt: s.pad, padb: s.pad, ax: if (s.ax == "end") 1 else if (s.ax == "center") 2 else 0, ay: if (s.ay == "end") 1 else if (s.ay == "center") 2 else 0, r: s.r, g: s.g, b: s.b, a: s.a, ox: 0.0, oy: 0.0, uid: s.hid, tx: "", fs: 0.0 }
                                    | row _
                            |> if (s.kind == "text")
                                | then |> std/store:insert(view) { d: s.d, kind: "text", wk: 0, w: 0.0, hk: 0, h: 0.0, dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: s.r, g: s.g, b: s.b, a: s.a, ox: 0.0, oy: 0.0, uid: s.hid, tx: s.tx, fs: s.fs }
                                    | row _
                            // list — entry rows from the catalog store, one
                            // pearl card per component, sel/hover baked in.
                            |> if (s.kind == "list")
                                | then |> std/store:insert(view) { d: s.d, kind: "clip", wk: if (s.ws == "star") 1 else if (s.ws == "fix") 3 else 0, w: s.w, hk: if (s.hs == "star") 1 else if (s.hs == "fix") 3 else 0, h: s.h, dir: if (s.dir == "ttb") 1 else 0, gap: s.gap, padl: s.pad, padr: s.pad, padt: s.pad, padb: s.pad, ax: if (s.ax == "end") 1 else if (s.ax == "center") 2 else 0, ay: if (s.ay == "end") 1 else if (s.ay == "center") 2 else 0, r: s.r, g: s.g, b: s.b, a: s.a, ox: 0.0, oy: 0.0 - fworld.scroll, uid: s.hid, tx: "", fs: 0.0 }
                                    | row _ |> if (world.r0 > 0)
                                        | then |> std/store:insert(view) { d: s.d + 1, kind: "panel", wk: 1, w: 0.0, hk: 3, h: @as(f64, @floatFromInt(world.r0)) * 56.0 - @as(f64, @floatFromInt(s.gap)), dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: 0.0, g: 0.0, b: 0.0, a: 0.0, ox: 0.0, oy: 0.0, uid: 0, tx: "", fs: 0.0 }
                                            | row _
                                    |> std/store:query(entries)
                                        ! query { [row]en, [ordinal]io, [id]ih } when @as(i64, @intCast(io)) >= world.r0 and @as(i64, @intCast(io)) <= world.r1
                                            |> std/store:insert(view) { d: s.d + 1, kind: "panel", wk: 1, w: 0.0, hk: 3, h: 52.0, dir: 1, gap: 0, padl: 10, padr: 10, padt: 6, padb: 6, ax: 0, ay: 0, r: 30.0 + (if (ih == world.sel) @as(f64, 52.0) else if (ih == world.hover) @as(f64, 20.0) else @as(f64, 0.0)), g: 30.0 + (if (ih == world.sel) @as(f64, 46.0) else if (ih == world.hover) @as(f64, 18.0) else @as(f64, 0.0)), b: 40.0 + (if (ih == world.sel) @as(f64, 22.0) else if (ih == world.hover) @as(f64, 10.0) else @as(f64, 0.0)), a: 255.0 * (if (ih == world.fu and world.fu >= 0 and fworld.ft < 1.0) 1.0 - fworld.ft else 1.0), ox: 0.0, oy: 0.0, uid: ih, tx: "", fs: 0.0 }
                                                | row _ |> std/store:insert(view) { d: s.d + 2, kind: "text", wk: 0, w: 0.0, hk: 0, h: 0.0, dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: if (ih == world.sel) @as(f64, 246.0) else 216.0, g: if (ih == world.sel) @as(f64, 230.0) else 210.0, b: if (ih == world.sel) @as(f64, 196.0) else 224.0, a: 255.0 * (if (ih == world.fu and world.fu >= 0 and fworld.ft < 1.0) 1.0 - fworld.ft else 1.0), ox: 0.0, oy: 0.0, uid: ih, tx: en.tx, fs: 14.0 }
                                                    | row _ |> std/store:insert(view) { d: s.d + 2, kind: "text", wk: 0, w: 0.0, hk: 0, h: 0.0, dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: 132.0, g: 128.0, b: 118.0, a: 255.0 * (if (ih == world.fu and world.fu >= 0 and fworld.ft < 1.0) 1.0 - fworld.ft else 1.0), ox: 0.0, oy: 0.0, uid: ih, tx: en.sub, fs: 9.5 }
                                                        | row _
                                    |> if (world.r1 < world.icount)
                                        | then |> std/store:insert(view) { d: s.d + 1, kind: "panel", wk: 1, w: 0.0, hk: 3, h: @as(f64, @floatFromInt(world.icount - world.r1)) * 56.0 - @as(f64, @floatFromInt(s.gap)), dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: 0.0, g: 0.0, b: 0.0, a: 0.0, ox: 0.0, oy: 0.0, uid: 0, tx: "", fs: 0.0 }
                                            | row _
                            // stage — a clip whose solved rect the emit arm
                            // captures into fworld.s*; the selected tor draws
                            // inside it after the tree drains.
                            |> if (s.kind == "stage")
                                | then |> std/store:insert(view) { d: s.d, kind: "clip", wk: if (s.ws == "star") 1 else if (s.ws == "fix") 3 else 0, w: s.w, hk: if (s.hs == "star") 1 else if (s.hs == "fix") 3 else 0, h: s.h, dir: if (s.dir == "ttb") 1 else 0, gap: s.gap, padl: s.pad, padr: s.pad, padt: s.pad, padb: s.pad, ax: if (s.ax == "end") 1 else if (s.ax == "center") 2 else 0, ay: if (s.ay == "end") 1 else if (s.ay == "center") 2 else 0, r: s.r, g: s.g, b: s.b, a: s.a, ox: 0.0, oy: 0.0, uid: s.hid, tx: "", fs: 0.0 }
                                    | row _
                    // Scripted twin — click entry rows, snap each pick.
                    |> if (world.frame == 6 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 120.0, y: 100.0)
                    |> if (world.frame == 7 and world.live == 0)
                        | then |> libs/metal:input.up(x: 120.0, y: 100.0)
                    |> if (world.frame == 9 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_pick0.bmp")
                            |> std/io:print.ln("gallery: snapped pick0 (sel {{ world.sel:d }})")
                    |> if (world.frame == 12 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 120.0, y: 380.0)
                    |> if (world.frame == 13 and world.live == 0)
                        | then |> libs/metal:input.up(x: 120.0, y: 380.0)
                    |> if (world.frame == 15 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_pick1.bmp")
                    |> if (world.frame == 18 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 120.0, y: 436.0)
                    |> if (world.frame == 19 and world.live == 0)
                        | then |> libs/metal:input.up(x: 120.0, y: 436.0)
                    |> if (world.frame == 21 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_pick2.bmp")
                    |> if (world.frame == 24 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 120.0, y: 492.0)
                    |> if (world.frame == 25 and world.live == 0)
                        | then |> libs/metal:input.up(x: 120.0, y: 492.0)
                    |> if (world.frame == 27 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_pick3.bmp")
                    |> if (world.frame == 30 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 120.0, y: 548.0)
                    |> if (world.frame == 31 and world.live == 0)
                        | then |> libs/metal:input.up(x: 120.0, y: 548.0)
                    |> if (world.frame == 33 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_pick4.bmp")
                    // select the term entry by handle, snap the pick
                    |> if (world.frame == 34 and world.live == 0)
                        | then |> std/store:stored { world.sel: world.termsel }
                    |> if (world.frame == 39 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_pick_term.bmp")
                    // EMIT — blind over view. el.clip carries no eid, so
                    // clip cmds are discriminated by DFS emission order:
                    // clip 0 is the sidebar list, clip 1 the stage.
                    |> libs/clay:layout(cl: h)
                        ! tree t
                            |> std/store:query(view)
                                ! query { [row]v }
                                    |> if (v.kind == "panel")
                                        | then |> libs/clay:el.close-to(t, v.d)
                                            |> libs/ui:panelx(t, dock: "", ws: if (v.wk == 1) "star" else if (v.wk == 3) "fix" else "", v.w, hs: if (v.hk == 1) "star" else if (v.hk == 3) "fix" else "", v.h, dir: if (v.dir == 1) "ttb" else "ltr", v.gap, pad: v.padl, ax: if (v.ax == 2) "center" else if (v.ax == 1) "end" else "start", ay: if (v.ay == 2) "center" else if (v.ay == 1) "end" else "start", v.r, v.g, v.b, v.a, fl: 0, fx: 0.0, fy: 0.0, eid: v.uid)
                                    |> if (v.kind == "clip")
                                        | then |> libs/clay:el.close-to(t, v.d)
                                            |> libs/clay:el.open(t)
                                            |> libs/clay:el.clip(t, v.wk, v.w, v.hk, v.h, v.dir, v.gap, v.padl, v.padr, v.padt, v.padb, v.r, v.g, v.b, v.a, v.ox, v.oy, horiz: 0, vert: 1, ovr: 0.0, ovg: 0.0, ovb: 0.0, ova: 0.0, crtl: 0.0, crtr: 0.0, crbl: 0.0, crbr: 0.0, ar: 0.0, br: 0.0, bg: 0.0, bb: 0.0, ba: 0.0, bwl: 0, bwr: 0, bwt: 0, bwb: 0, bwc: 0, fat: 0, fx: 0.0, fy: 0.0, fae: 0, fap: 0, exw: 0.0, exh: 0.0, zi: 0, fct: 0)
                                    |> if (v.kind == "text")
                                        | then |> libs/clay:el.close-to(t, v.d)
                                            |> libs/ui:text(t, v.tx, v.fs, v.r, v.g, v.b, v.a, eid: v.uid)
                        | solved cls |> libs/clay:each(cl: cls)
                            ! cmd rc |> if (rc.kind == 1)
                                | then |> std/store:insert(hit) { seq: rc.ud, cl: world.ic, rc.x, rc.y, rc.w, rc.h }
                                    |> libs/metal:draw.rect(f, x: @round(rc.x), y: @round(rc.y), w: @round(rc.x + rc.w) - @round(rc.x), h: @round(rc.y + rc.h) - @round(rc.y), rc.r, rc.g, rc.b, rc.a)
                            ! cmd rc |> if (rc.kind == 3)
                                | then |> std/store:insert(hit) { seq: rc.ud, cl: world.ic, rc.x, rc.y, rc.w, rc.h }
                                    |> libs/metal:draw.text(f, x: @round(rc.x), y: @round(rc.y), size: rc.fs, rc.r, rc.g, rc.b, rc.a, text: rc.tx)
                            ! cmd rc |> if (rc.kind == 5)
                                | then |> if (world.clipn == 0)
                                    | then |> std/store:stored { world.ic: 1, world.clipn: 1 }
                                        |> std/store:stored { fworld.lx0: rc.x, fworld.ly0: rc.y, fworld.lx1: rc.x + rc.w, fworld.ly1: rc.y + rc.h }
                                        |> libs/metal:draw.clip.push(f, rc.x, rc.y, rc.w, rc.h)
                                    | else |> std/store:stored { world.clipn: world.clipn + 1 }
                                        |> std/store:stored { fworld.sx0: rc.x, fworld.sy0: rc.y, fworld.sx1: rc.x + rc.w, fworld.sy1: rc.y + rc.h }
                                        |> libs/metal:draw.clip.push(f, rc.x, rc.y, rc.w, rc.h)
                            ! cmd rc |> if (rc.kind == 6)
                                | then |> libs/metal:draw.clip.pop(f)
                                    |> std/store:stored { world.ic: 0 }
                            | drained |> std/store:stored { world.frame: world.frame }
                    // THE STAGE — the selected component drawn on its own
                    // champagne card, inside the stage clip, by its real
                    // signature. One arm per catalog tork.
                    |> std/store:query(entries)
                        ! query { [row]se, [id]sid } when sid == world.sel
                            |> std/store:stored { world.seltork: se.tork }
                            |> libs/metal:draw.shadow(f, x: fworld.sx0 + 24.0, y: fworld.sy0 + 34.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0, radius: 18.0, blur: 22.0, r: 0.38, g: 0.45, b: 0.58, a: 0.35)
                            |> libs/metal:draw.roundrect(f, x: fworld.sx0 + 24.0, y: fworld.sy0 + 24.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0, radius: 18.0, r: 0.90, g: 0.92, b: 0.96, a: 0.97)
                            |> libs/metal:draw.text(f, x: fworld.sx0 + 44.0, y: fworld.sy0 + 64.0, size: 10.5, r: 0.38, g: 0.45, b: 0.58, a: 0.72, text: se.sub)
                            |> if (se.tork == 0)
                                | then |> libs/components:hub(win: w, f, text: "bridge", cx: (fworld.sx0 + fworld.sx1) / 2.0, cy: (fworld.sy0 + fworld.sy1) / 2.0 - 10.0, r: 64.0, glow: 0.75)
                            |> if (se.tork == 1)
                                | then |> libs/components:button(win: w, f, text: "mint resource", size: 14.0, face: 0, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 - 18.0, variant: 1, mx: @as(f64, @floatFromInt(world.mx)), my: @as(f64, @floatFromInt(world.my)), down: world.pdown, disabled: 0)
                                    |> libs/components:button(win: w, f, text: "secondary", size: 14.0, face: 0, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 28.0, variant: 0, mx: @as(f64, @floatFromInt(world.mx)), my: @as(f64, @floatFromInt(world.my)), down: world.pdown, disabled: 0)
                                    |> libs/components:button(win: w, f, text: "ghost", size: 14.0, face: 0, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 74.0, variant: 2, mx: @as(f64, @floatFromInt(world.mx)), my: @as(f64, @floatFromInt(world.my)), down: world.pdown, disabled: 0)
                            |> if (se.tork == 2)
                                | then |> libs/components:caption(win: w, f, text: "custody is a first-class value", cx: (fworld.sx0 + fworld.sx1) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0, a: 0.85)
                            |> if (se.tork == 3)
                                | then |> libs/components:wordmark(win: w, f, world.face, text: "OMNI", size: 34.0, cx: (fworld.sx0 + fworld.sx1) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0 - 20.0, r: 0.14, g: 0.18, b: 0.26, a: 0.95)
                            |> if (se.tork == 4 and world.tex >= 0)
                                | then |> libs/components:remote(f, world.tex, cx: (fworld.sx0 + fworld.sx1) / 2.0, cy: (fworld.sy0 + fworld.sy1) / 2.0, h: 300.0, glow: 0.7)
                            |> if (se.tork == 5 and world.wavslot >= 0)
                                | then |> libs/components:waveform(f, slot: world.wavslot, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 - 60.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: 140.0, a: 1.0)
                            |> if (se.tork == 6 and world.docslot >= 0)
                                | then |> libs/components:docpage(f, slot: world.docslot, x: fworld.sx0 + 60.0, y: fworld.sy0 + 80.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: fworld.sy1 - fworld.sy0 - 150.0, a: 1.0)
                            |> if (se.tork == 7 and world.codeslot >= 0 and world.cface >= 0)
                                | then |> libs/components/code_codeview:codeview(f, slot: world.codeslot, face: world.cface, x: fworld.sx0 + 60.0, y: fworld.sy0 + 80.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: fworld.sy1 - fworld.sy0 - 150.0, scroll: 0.0, t: 1.0, a: 1.0)
                            |> if (se.tork == 8 and world.diffslot >= 0 and world.dface >= 0)
                                | then |> libs/components/code_diffview:diffview(f, slot: world.diffslot, face: world.dface, x: fworld.sx0 + 60.0, y: fworld.sy0 + 80.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: fworld.sy1 - fworld.sy0 - 150.0, scroll: 0.0, t: 1.0, a: 1.0)
                            |> if (se.tork == 9 and world.tface >= 0)
                                | then |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_33.gate.json", face: world.tface, x: fworld.sx0 + 60.0, y: fworld.sy0 + 80.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: 130.0, t: 30.0, a: 1.0)
                                    |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_36.gate.json", face: world.tface, x: fworld.sx0 + 60.0, y: fworld.sy0 + 224.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: 130.0, t: 38.0, a: 1.0)
                                    |> libs/components/code_turnview:turnview(f, path: "/tmp/omni_remote_mic_17.gate.json", face: world.tface, x: fworld.sx0 + 60.0, y: fworld.sy0 + 368.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: 130.0, t: 46.0, a: 1.0)
                            |> if (se.tork == 10 and world.termh >= 0 and world.cface >= 0)
                                | then |> libs/components/term_termview:termview(f, term: world.termh, face: world.cface, x: fworld.sx0 + 60.0, y: fworld.sy0 + 80.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: fworld.sy1 - fworld.sy0 - 150.0, t: 1.0, a: 1.0)
                            // atork mirrors the live selection so mouse-down
                            // can hit-test stage buttons (mood pills) that
                            // aren't in the sidebar hit store.
                            |> std/store:stored { world.atork: se.tork }
                            |> if (se.tork == 11)
                                | then |> libs/components/flow:flow(f, cx: (fworld.sx0 + fworld.sx1) / 2.0, cy: (fworld.sy0 + fworld.sy1) / 2.0, w: fworld.sx1 - fworld.sx0 - 120.0, h: fworld.sy1 - fworld.sy0 - 160.0, t: @as(f64, @floatFromInt(world.frame)) / 60.0, a: 1.0)
                            |> if (se.tork == 12 and world.gtex >= 0)
                                | then |> std/ctx(theme)
                                    |> libs/components/dome:dome(win: w, f, tex: world.gtex, cx: (fworld.sx0 + fworld.sx1) / 2.0, cy: (fworld.sy0 + fworld.sy1) / 2.0, w: fworld.sx1 - fworld.sx0 - 160.0, h: fworld.sy1 - fworld.sy0 - 180.0, label: "dome", world.face, t: @as(f64, @floatFromInt(world.frame)) / 60.0, a: 1.0)
                            // THE DRIFT — the backdrop rect wanders ±~25pt
                            // on ~2-minute sines; large amplitude, glacial
                            // pace. Caller owns it so frost capture and
                            // lens refraction sample the SAME moving photo.
                            |> if (se.tork == 13 and world.gtex >= 0)
                                | then |> libs/math:sin(x: @as(f64, @floatFromInt(world.frame)) / 60.0 * 0.21) : d1
                                    |> libs/math:sin(x: @as(f64, @floatFromInt(world.frame)) / 60.0 * 0.14 + 2.1) : d2
                                    |> libs/math:sin(x: @as(f64, @floatFromInt(world.frame)) / 60.0 * 0.19 + 1.7) : d3
                                    |> libs/math:sin(x: @as(f64, @floatFromInt(world.frame)) / 60.0 * 0.12 + 0.6) : d4
                                    |> std/store:stored { fworld.ddx: d1 * 60.0 + d2 * 15.0, fworld.ddy: d3 * 45.0 + d4 * 12.0 }
                                    |> std/ctx(theme)
                                    // the drifting backdrop bleeds past the stage
                                    // card — clip it back inside or it paints over
                                    // the sidebar. Containment, not z-order.
                                    |> libs/metal:draw.clip.push(f, x: fworld.sx0 + 24.0, y: fworld.sy0 + 24.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0)
                                    |> libs/components/glasscard:glasscard(win: w, f, tex: world.gtex, cx: (fworld.sx0 + fworld.sx1) / 2.0 - 115.0, cy: (fworld.sy0 + fworld.sy1) / 2.0, w: 210.0, h: 58.0, bx: fworld.sx0 + 24.0 - 110.0 + fworld.ddx, by: fworld.sy0 + 24.0 - 110.0 + fworld.ddy, bw: fworld.sx1 - fworld.sx0 - 48.0 + 220.0, bh: fworld.sy1 - fworld.sy0 - 48.0 + 220.0, rad: 29.0, label: "frost", world.face, a: 1.0, li: 1.0, lg: 1.0, lb: 1.0)
                                    |> libs/components/lens:lens(win: w, f, tex: world.gtex, cx: (fworld.sx0 + fworld.sx1) / 2.0 + 115.0, cy: (fworld.sy0 + fworld.sy1) / 2.0, w: 210.0, h: 58.0, bx: fworld.sx0 + 24.0 - 110.0 + fworld.ddx, by: fworld.sy0 + 24.0 - 110.0 + fworld.ddy, bw: fworld.sx1 - fworld.sx0 - 48.0 + 220.0, bh: fworld.sy1 - fworld.sy0 - 48.0 + 220.0, rad: 29.0, label: "lens", world.face, a: 1.0, tr: 0.10, tg: 0.12, tb: 0.17, ta: 0.55, li: 1.0, lg: 1.0, lb: 1.0)
                                    |> libs/metal:draw.clip.pop(f)
                            // AVATAR — the medallion swaps faces on world.mood;
                            // four pills below are the mood buttons (hit-tested
                            // in mouse-down against the same rects drawn here).
                            |> if (se.tork == 14)
                                | then |> std/ctx(theme)
                                    // blurred portrait backdrop — her neutral
                                    // face frosted heavy; the medallion stays crisp
                                    |> libs/metal:draw.imagecover(f, tex: world.v0, x: fworld.sx0 + 24.0, y: fworld.sy0 + 24.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0)
                                    |> libs/metal:draw.capture(f)
                                    |> libs/metal:draw.frost(f, x: fworld.sx0 + 24.0, y: fworld.sy0 + 24.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0, radius: 20.0, rough: 18.0, edge: 16.0, grain: 0.16, milk: 0.55, r: 0.82, g: 0.88, b: 0.96, a: 0.9)
                                    |> libs/components/avatar:avatar(win: w, f, tex: if (world.mood == 0) world.v0 else (if (world.mood == 1) world.v1 else (if (world.mood == 2) world.v2 else world.v3)), cx: (fworld.sx0 + fworld.sx1) / 2.0, cy: (fworld.sy0 + fworld.sy1) / 2.0 - 40.0, d: 150.0, name: "victoria", world.face, a: 1.0)
                                    // mood pills — frost over the blurred portrait;
                                    // selected gets a rim. Same rects mouse-down tests.
                                    |> libs/metal:draw.frost(f, x: (fworld.sx0 + fworld.sx1) / 2.0 - 202.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, rough: 8.0, edge: 8.0, grain: 0.10, milk: 0.30, r: 0.85, g: 0.90, b: 0.97, a: 0.85)
                                    |> if (world.mood == 0)
                                        | then |> libs/metal:draw.panel(f, x: (fworld.sx0 + fworld.sx1) / 2.0 - 202.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, r: 1.0, g: 1.0, b: 1.0, a: 0.0, bw: 1.5, br: theme.rr, bg: theme.rg, bb: theme.rb, ba: 0.9)
                                    |> libs/metal:text.offset(win: w, text: "neutral", size: 13.0, world.face, index: 7) : pw0
                                        |> libs/metal:draw.textface(f, x: (fworld.sx0 + fworld.sx1) / 2.0 - 202.0 + (92.0 - pw0) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 103.5, size: 13.0, font: world.face, r: theme.ir, g: theme.ig, b: theme.ib, a: 0.95, text: "neutral")
                                    |> libs/metal:draw.frost(f, x: (fworld.sx0 + fworld.sx1) / 2.0 - 98.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, rough: 8.0, edge: 8.0, grain: 0.10, milk: 0.30, r: 0.85, g: 0.90, b: 0.97, a: 0.85)
                                    |> if (world.mood == 1)
                                        | then |> libs/metal:draw.panel(f, x: (fworld.sx0 + fworld.sx1) / 2.0 - 98.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, r: 1.0, g: 1.0, b: 1.0, a: 0.0, bw: 1.5, br: theme.rr, bg: theme.rg, bb: theme.rb, ba: 0.9)
                                    |> libs/metal:text.offset(win: w, text: "smiling", size: 13.0, world.face, index: 7) : pw1
                                        |> libs/metal:draw.textface(f, x: (fworld.sx0 + fworld.sx1) / 2.0 - 98.0 + (92.0 - pw1) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 103.5, size: 13.0, font: world.face, r: theme.ir, g: theme.ig, b: theme.ib, a: 0.95, text: "smiling")
                                    |> libs/metal:draw.frost(f, x: (fworld.sx0 + fworld.sx1) / 2.0 + 6.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, rough: 8.0, edge: 8.0, grain: 0.10, milk: 0.30, r: 0.85, g: 0.90, b: 0.97, a: 0.85)
                                    |> if (world.mood == 2)
                                        | then |> libs/metal:draw.panel(f, x: (fworld.sx0 + fworld.sx1) / 2.0 + 6.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, r: 1.0, g: 1.0, b: 1.0, a: 0.0, bw: 1.5, br: theme.rr, bg: theme.rg, bb: theme.rb, ba: 0.9)
                                    |> libs/metal:text.offset(win: w, text: "worried", size: 13.0, world.face, index: 7) : pw2
                                        |> libs/metal:draw.textface(f, x: (fworld.sx0 + fworld.sx1) / 2.0 + 6.0 + (92.0 - pw2) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 103.5, size: 13.0, font: world.face, r: theme.ir, g: theme.ig, b: theme.ib, a: 0.95, text: "worried")
                                    |> libs/metal:draw.frost(f, x: (fworld.sx0 + fworld.sx1) / 2.0 + 110.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, rough: 8.0, edge: 8.0, grain: 0.10, milk: 0.30, r: 0.85, g: 0.90, b: 0.97, a: 0.85)
                                    |> if (world.mood == 3)
                                        | then |> libs/metal:draw.panel(f, x: (fworld.sx0 + fworld.sx1) / 2.0 + 110.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 94.0, w: 92.0, h: 32.0, radius: 16.0, r: 1.0, g: 1.0, b: 1.0, a: 0.0, bw: 1.5, br: theme.rr, bg: theme.rg, bb: theme.rb, ba: 0.9)
                                    |> libs/metal:text.offset(win: w, text: "determined", size: 13.0, world.face, index: 10) : pw3
                                        |> libs/metal:draw.textface(f, x: (fworld.sx0 + fworld.sx1) / 2.0 + 110.0 + (92.0 - pw3) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 103.5, size: 13.0, font: world.face, r: theme.ir, g: theme.ig, b: theme.ib, a: 0.95, text: "determined")
                    // THE FLIGHT — the clicked row's pill travels to the
                    // header slot; its fill dissolves into bare text.
                    |> if (world.fu >= 0 and fworld.ft < 1.0)
                        | then |> std/store:query(entries)
                            ! query { [row]fe2, [id]fid } when fid == world.fu
                                |> libs/metal:draw.roundrect(f, x: fworld.rx, y: fworld.ry, w: fworld.rw, h: fworld.rh, radius: 12.0, r: 0.16, g: 0.16, b: 0.24, a: fworld.ba)
                                |> libs/metal:draw.text(f, x: fworld.rx + 13.0, y: fworld.ry + 9.0, size: 12.0 + fworld.ft * 4.0, r: 0.94 - fworld.ft * 0.49, g: 0.89 - fworld.ft * 0.53, b: 0.78 - fworld.ft * 0.56, a: 1.0, text: fe2.tx)
                    // THE HEADER — persistent: drawn every frame at the
                    // stage's top slot regardless of browse/drill state.
                    |> std/store:query(entries)
                        ! query { [row]he, [id]hid3 } when hid3 == world.sel
                            |> libs/metal:draw.text(f, x: fworld.sx0 + 60.0, y: fworld.sy0 + 46.0, size: 16.0, r: 0.40, g: 0.47, b: 0.60, a: fworld.ha, text: he.tx)
                    |> std/store:query(entries)
                        ! query { [row]pe, [id]pid3 } when pid3 == world.psel and world.psel != world.sel and world.fu >= 0 and fworld.ft < 1.0
                            |> libs/metal:draw.text(f, x: fworld.sx0 + 60.0, y: fworld.sy0 + 46.0, size: 16.0, r: 0.48, g: 0.54, b: 0.64, a: (1.0 - fworld.ft) * 0.8, text: pe.tx)
                    // THE COG — drill affordance, top-right of the stage card.
                    |> std/store:stored { fworld.cx0: fworld.sx1 - 62.0, fworld.cy0: fworld.sy0 + 34.0, fworld.cw: 34.0, fworld.ch: 24.0 }
                        |> libs/metal:draw.roundrect(f, x: fworld.sx1 - 62.0, y: fworld.sy0 + 34.0, w: 34.0, h: 24.0, radius: 8.0, r: 0.24 + @as(f64, @floatFromInt(world.coghot)) * 0.10, g: 0.24 + @as(f64, @floatFromInt(world.coghot)) * 0.10, b: 0.32 + @as(f64, @floatFromInt(world.coghot)) * 0.10, a: 0.92)
                        |> libs/metal:draw.text(f, x: fworld.sx1 - 51.0, y: fworld.sy0 + 39.0, size: 13.0, r: 0.82, g: 0.78, b: 0.70, a: 0.95, text: "i")
                    // THE DIVE — content recedes under a dim veil; the detail
                    // sheet rises. The header stays pinned above it all.
                    |> if (fworld.da > 0.01 or fworld.sa > 0.01)
                        | then |> libs/metal:draw.roundrect(f, x: fworld.sx0 + 52.0, y: fworld.sy0 + 88.0, w: fworld.sx1 - fworld.sx0 - 104.0, h: fworld.sy1 - fworld.sy0 - 160.0, radius: 16.0, r: 0.05, g: 0.05, b: 0.08, a: fworld.da)
                            |> std/store:query(entries)
                                ! query { [row]de, [id]did } when did == world.sel
                                    |> libs/metal:draw.roundrect(f, x: fworld.sx0 + 84.0, y: fworld.sy0 + 118.0 + fworld.shy, w: fworld.sx1 - fworld.sx0 - 168.0, h: fworld.sy1 - fworld.sy0 - 230.0, radius: 14.0, r: 0.11, g: 0.11, b: 0.15, a: fworld.sa * 0.97)
                                    |> libs/metal:draw.text(f, x: fworld.sx0 + 108.0, y: fworld.sy0 + 148.0 + fworld.shy, size: 20.0, r: 0.95, g: 0.90, b: 0.80, a: fworld.sa, text: de.tx)
                                    |> libs/metal:draw.text(f, x: fworld.sx0 + 108.0, y: fworld.sy0 + 178.0 + fworld.shy, size: 11.0, r: 0.72, g: 0.68, b: 0.60, a: fworld.sa, text: de.sub)
                                    |> libs/metal:draw.text(f, x: fworld.sx0 + 108.0, y: fworld.sy0 + 226.0 + fworld.shy, size: 10.0, r: 0.50, g: 0.48, b: 0.44, a: fworld.sa, text: "kind-dispatched component — catalog family: surface")
                                    |> libs/metal:draw.text(f, x: fworld.sx0 + 108.0, y: fworld.sy0 + 250.0 + fworld.shy, size: 10.0, r: 0.50, g: 0.48, b: 0.44, a: fworld.sa, text: "registered in components/ — replay-grown via challenges/")
                                    |> libs/metal:draw.text(f, x: fworld.sx0 + 108.0, y: fworld.sy0 + 274.0 + fworld.shy, size: 10.0, r: 0.50, g: 0.48, b: 0.44, a: fworld.sa, text: "esc or the cog returns to the showcase")
                    // scripted twin — continued: drill dive, return, re-flight
                    |> if (world.frame == 42 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 955.0, y: 46.0)
                    |> if (world.frame == 43 and world.live == 0)
                        | then |> libs/metal:input.up(x: 955.0, y: 46.0)
                    |> if (world.frame == 46 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_drill_mid.bmp")
                    |> if (world.frame == 60 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_drill.bmp")
                    |> if (world.frame == 64 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 955.0, y: 46.0)
                    |> if (world.frame == 65 and world.live == 0)
                        | then |> libs/metal:input.up(x: 955.0, y: 46.0)
                    |> if (world.frame == 70 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_back.bmp")
                    |> if (world.frame == 72 and world.live == 0)
                        | then |> libs/metal:input.mouse(x: 120.0, y: 436.0)
                    |> if (world.frame == 73 and world.live == 0)
                        | then |> libs/metal:input.up(x: 120.0, y: 436.0)
                    |> if (world.frame == 78 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_flight.bmp")
                    |> if (world.frame == 112 and world.live == 0)
                        | then |> libs/metal:window.snap(path: "/tmp/gallery_landed.bmp")
                    |> if (world.frame == 115 and world.live == 0)
                        | then |> libs/host:quit()
                ! key-down k when k.code == 53 and world.dive == 0 |> libs/host:quit()
                ! key-down k when k.code == 53 and world.dive == 1
                    |> std/store:stored { world.dive: 0 }
                    |> std/store:stored { fworld.dt0: @as(f64, @floatFromInt(world.frame)) }
                ! key-down k when world.seltork == 10 and world.termh >= 0
                    |> std/io:print.ln("key code={{ k.code:d }} chars=|{{ k.chars:s }}|")
                    |> libs/vt:term-key(h: world.termh, k.code, k.chars) : _
                ! mouse-move e
                    |> std/store:stored { world.mx: @as(i64, @intFromFloat(e.x)), world.my: @as(i64, @intFromFloat(e.y)), world.hover: -1, world.coghot: 0 }
                    |> if (e.x >= fworld.cx0 and e.x < fworld.cx0 + fworld.cw and e.y >= fworld.cy0 and e.y < fworld.cy0 + fworld.ch)
                        | then |> std/store:stored { world.coghot: 1 }
                    |> std/store:query(hit)
                        ! query hi when (hi.cl == 0 or e.y >= fworld.ly0 and e.y < fworld.ly1) and e.x >= hi.x and e.x < hi.x + hi.w and e.y >= hi.y and e.y < hi.y + hi.h
                            |> std/store:stored { world.hover: hi.seq }
                ! mouse-down e
                    |> std/store:stored { world.pdown: 1, world.down: -1 }
                    // AVATAR mood pills — same rects the tork-14 arm draws.
                    |> if (world.atork == 14 and e.x >= (fworld.sx0 + fworld.sx1) / 2.0 - 202.0 and e.x < (fworld.sx0 + fworld.sx1) / 2.0 - 110.0 and e.y >= (fworld.sy0 + fworld.sy1) / 2.0 + 94.0 and e.y < (fworld.sy0 + fworld.sy1) / 2.0 + 126.0)
                        | then |> std/store:stored { world.mood: 0 }
                    |> if (world.atork == 14 and e.x >= (fworld.sx0 + fworld.sx1) / 2.0 - 98.0 and e.x < (fworld.sx0 + fworld.sx1) / 2.0 - 6.0 and e.y >= (fworld.sy0 + fworld.sy1) / 2.0 + 94.0 and e.y < (fworld.sy0 + fworld.sy1) / 2.0 + 126.0)
                        | then |> std/store:stored { world.mood: 1 }
                    |> if (world.atork == 14 and e.x >= (fworld.sx0 + fworld.sx1) / 2.0 + 6.0 and e.x < (fworld.sx0 + fworld.sx1) / 2.0 + 98.0 and e.y >= (fworld.sy0 + fworld.sy1) / 2.0 + 94.0 and e.y < (fworld.sy0 + fworld.sy1) / 2.0 + 126.0)
                        | then |> std/store:stored { world.mood: 2 }
                    |> if (world.atork == 14 and e.x >= (fworld.sx0 + fworld.sx1) / 2.0 + 110.0 and e.x < (fworld.sx0 + fworld.sx1) / 2.0 + 202.0 and e.y >= (fworld.sy0 + fworld.sy1) / 2.0 + 94.0 and e.y < (fworld.sy0 + fworld.sy1) / 2.0 + 126.0)
                        | then |> std/store:stored { world.mood: 3 }
                    |> std/store:query(hit)
                        ! query hi when (hi.cl == 0 or e.y >= fworld.ly0 and e.y < fworld.ly1) and e.x >= hi.x and e.x < hi.x + hi.w and e.y >= hi.y and e.y < hi.y + hi.h
                            |> std/store:stored { world.down: hi.seq }
                ! mouse-up e
                    |> std/store:stored { world.pdown: 0 }
                    |> std/store:query(hit)
                        ! query hi when (hi.cl == 0 or e.y >= fworld.ly0 and e.y < fworld.ly1) and world.down == hi.seq and e.x >= hi.x and e.x < hi.x + hi.w and e.y >= hi.y and e.y < hi.y + hi.h
                            |> std/store:query(uids)
                                ! query u when u.uid == world.down
                                    // FLIGHT CAPTURE — union the clicked row's
                                    // hit rects into the chip's source box,
                                    // then retarget sel/psel/fu/dive.
                                    |> std/store:stored { fworld.fx0: 1000000.0, fworld.fy0: 1000000.0, fworld.frt: -1000000.0, fworld.fb: -1000000.0 }
                                    |> std/store:query(hit)
                                        ! query { [row]hf } when hf.seq == world.down
                                            |> std/store:stored {
                                                fworld.fx0: @min(fworld.fx0, hf.x),
                                                fworld.fy0: @min(fworld.fy0, hf.y),
                                                fworld.frt: @max(fworld.frt, hf.x + hf.w),
                                                fworld.fb: @max(fworld.fb, hf.y + hf.h),
                                            }
                                    |> std/store:stored { world.psel: world.sel, world.fu: world.down }
                                    |> std/store:stored { fworld.ft0: @as(f64, @floatFromInt(world.frame)), fworld.dt0: if (world.dive == 1) @as(f64, @floatFromInt(world.frame)) else fworld.dt0 }
                                    |> std/store:stored { world.dive: 0 }
                                    |> std/store:stored { world.sel: world.down }
                    // THE COG — manual bounds (stage chrome isn't in hit).
                    |> if (e.x >= fworld.cx0 and e.x < fworld.cx0 + fworld.cw and e.y >= fworld.cy0 and e.y < fworld.cy0 + fworld.ch)
                        | then |> std/store:stored { world.dive: 1 - world.dive }
                            |> std/store:stored { fworld.dt0: @as(f64, @floatFromInt(world.frame)) }
                    |> std/store:stored { world.down: -1 }
                ! scroll e
                    |> if (e.x >= fworld.lx0 and e.x < fworld.lx1 and e.y >= fworld.ly0 and e.y < fworld.ly1)
                        | then |> std/store:stored { fworld.scroll: @min(@max(0.0, fworld.scroll - e.dy), @max(0.0, @as(f64, @floatFromInt(world.icount + 1)) * 56.0 + 10.0 - (fworld.ly1 - fworld.ly0))) }
                ! close |> libs/host:quit()
                | done w2 |> libs/clay:drop(cl: h) |> libs/metal:window.close(win: w2) |> std/io:print.ln("gallery: closed (snapped)")
    | err e |> std/io:print.ln("metal init failed: {{ e:s }}")
| err e3 |> std/io:print.ln("clay init failed: {{ e3:s }}")
