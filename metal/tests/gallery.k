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
import app/omni_img
import oshun
import std/args
import std/bridge
import std/store
import std/io
import std/string
import std/fmt

std/store:new(world) {
    frame: 0[i64], sel: -1[i64], hover: -1[i64], down: -1[i64],
    ic: 0[i64], clipn: 0[i64], r0: 0[i64], r1: 32[i64], icount: 0[i64], live: 0[i64],
    mx: -1.0[i64], my: -1.0[i64], pdown: 0[i64],
    stageh: -1[i64], wavslot: -1[i64], docslot: -1[i64],
    codeslot: -1[i64], diffslot: -1[i64],
    tex: -1[i64], face: 0[i64], cface: -1[i64], dface: -1[i64], tface: -1[i64],
}
std/store:new(fworld) {
    scroll: 0.0[f64],
    lx0: 0.0[f64], ly0: 0.0[f64], lx1: 240.0[f64], ly1: 600.0[f64],
    sx0: 0.0[f64], sy0: 0.0[f64], sx1: 1.0[f64], sy1: 1.0[f64],
}
std/store:new(wins) { w: 1000.0[f64], h: 620.0[f64] }
std/store:new(hit, capacity: 128) { seq: i64, cl: i64, x: f64, y: f64, w: f64, h: f64 }

// Entry-handle set — refilled each frame from the entries query; a click
// on a sidebar row resolves sel by membership here.
std/store:new(uids, capacity: 256) { uid: i64 }

// The catalog — one row per showcased component. tork selects the
// dispatch arm; tx is the tor's name, sub its one-line claim.
std/store:new(entries, capacity: 64) { tx: char[24], sub: char[44], tork: i64 }

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
            |> libs/metal:font.load(win: w, path: "/tmp/archivo/Archivo_Black/ArchivoBlack-Regular.ttf")
                | font fc |> std/store:stored { world.face: fc }
                | err fe |> std/io:print.ln(fe)
            |> libs/metal:image.load(win: w, path: "/Users/larsde/Downloads/apple-remote.png")
                | img itx |> std/store:stored { world.tex: itx }
                | err ie |> std/io:print.ln(ie)
            // The code-surface components carry their own registry-side
            // font seams — one SF Mono face each, loaded through them.
            |> libs/components/code_codeview:code-font(path: "/System/Library/Fonts/SFNSMono.ttf")
                | font cfn |> std/store:stored { world.cface: cfn }
                | err cfe |> std/io:print.ln(cfe)
            |> libs/components/code_diffview:diff-font(path: "/System/Library/Fonts/SFNSMono.ttf")
                | font dfn |> std/store:stored { world.dface: dfn }
                | err dfe |> std/io:print.ln(dfe)
            |> libs/components/code_turnview:tv-font(path: "/System/Library/Fonts/SFNSMono.ttf")
                | font tfn |> std/store:stored { world.tface: tfn }
                | err tfe |> std/io:print.ln(tfe)
            |> libs/components/code_diffview:diff-load(path: "/tmp/code_diffview_sample.diff")
                | ok dsl |> std/store:stored { world.diffslot: dsl }
                | err dle |> std/io:print.ln(dle)
            |> libs/metal:frames(win: w, count: if (world.live == 1) 999999 else 9999)
                ! frame f
                    |> std/store:stored { world.frame: world.frame + 1, world.clipn: 0 }
                    |> std/store:clear(hit)
                    |> std/store:clear(view)
                    |> std/store:clear(uids)
                    |> libs/metal:window.size(win: w): wh
                    |> std/store:stored { wins.w: wh.w, wins.h: wh.h }
                    |> libs/clay:dims(cl: h, width: wh.w, height: wh.h)
                    // Seed the catalog once; first row's handle is the
                    // landing selection.
                    |> if (world.frame == 1)
                        | then |> std/store:insert(entries) { tx: "hub", sub: "the bridge's presence — pearl orb", tork: 0 }
                            | row h0 |> std/store:stored { world.sel: h0 }
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
                                            |> std/store:insert(view) { d: s.d + 1, kind: "panel", wk: 1, w: 0.0, hk: 3, h: 52.0, dir: 1, gap: 0, padl: 10, padr: 10, padt: 6, padb: 6, ax: 0, ay: 0, r: 30.0 + (if (ih == world.sel) @as(f64, 52.0) else if (ih == world.hover) @as(f64, 20.0) else @as(f64, 0.0)), g: 30.0 + (if (ih == world.sel) @as(f64, 46.0) else if (ih == world.hover) @as(f64, 18.0) else @as(f64, 0.0)), b: 40.0 + (if (ih == world.sel) @as(f64, 22.0) else if (ih == world.hover) @as(f64, 10.0) else @as(f64, 0.0)), a: 255.0, ox: 0.0, oy: 0.0, uid: ih, tx: "", fs: 0.0 }
                                                | row _ |> std/store:insert(view) { d: s.d + 2, kind: "text", wk: 0, w: 0.0, hk: 0, h: 0.0, dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: if (ih == world.sel) @as(f64, 246.0) else 216.0, g: if (ih == world.sel) @as(f64, 230.0) else 210.0, b: if (ih == world.sel) @as(f64, 196.0) else 224.0, a: 255.0, ox: 0.0, oy: 0.0, uid: ih, tx: en.tx, fs: 14.0 }
                                                    | row _ |> std/store:insert(view) { d: s.d + 2, kind: "text", wk: 0, w: 0.0, hk: 0, h: 0.0, dir: 0, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: 132.0, g: 128.0, b: 118.0, a: 255.0, ox: 0.0, oy: 0.0, uid: ih, tx: en.sub, fs: 9.5 }
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
                            |> libs/metal:draw.shadow(f, x: fworld.sx0 + 24.0, y: fworld.sy0 + 34.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0, radius: 18.0, blur: 22.0, r: 0.30, g: 0.22, b: 0.10, a: 0.35)
                            |> libs/metal:draw.silk(f, x: fworld.sx0 + 24.0, y: fworld.sy0 + 24.0, w: fworld.sx1 - fworld.sx0 - 48.0, h: fworld.sy1 - fworld.sy0 - 48.0, radius: 18.0, r: 0.94, g: 0.89, b: 0.78, a: 0.97, angle: 0.35, folds: 2.0, sheen: 0.7, pearl: 0.65)
                            |> libs/metal:draw.text(f, x: fworld.sx0 + 44.0, y: fworld.sy0 + 40.0, size: 13.0, r: 0.42, g: 0.34, b: 0.20, a: 0.9, text: se.sub)
                            |> if (se.tork == 0)
                                | then |> libs/components:hub(win: w, f, text: "bridge", cx: (fworld.sx0 + fworld.sx1) / 2.0, cy: (fworld.sy0 + fworld.sy1) / 2.0 - 10.0, r: 64.0, glow: 0.75)
                            |> if (se.tork == 1)
                                | then |> libs/components:button(win: w, f, text: "mint resource", size: 14.0, face: 0, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 - 18.0, variant: 1, mx: @as(f64, @floatFromInt(world.mx)), my: @as(f64, @floatFromInt(world.my)), down: world.pdown, disabled: 0)
                                    |> libs/components:button(win: w, f, text: "secondary", size: 14.0, face: 0, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 28.0, variant: 0, mx: @as(f64, @floatFromInt(world.mx)), my: @as(f64, @floatFromInt(world.my)), down: world.pdown, disabled: 0)
                                    |> libs/components:button(win: w, f, text: "ghost", size: 14.0, face: 0, x: fworld.sx0 + 60.0, y: (fworld.sy0 + fworld.sy1) / 2.0 + 74.0, variant: 2, mx: @as(f64, @floatFromInt(world.mx)), my: @as(f64, @floatFromInt(world.my)), down: world.pdown, disabled: 0)
                            |> if (se.tork == 2)
                                | then |> libs/components:caption(win: w, f, text: "custody is a first-class value", cx: (fworld.sx0 + fworld.sx1) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0, a: 0.85)
                            |> if (se.tork == 3)
                                | then |> libs/components:wordmark(win: w, f, world.face, text: "OMNI", size: 34.0, cx: (fworld.sx0 + fworld.sx1) / 2.0, y: (fworld.sy0 + fworld.sy1) / 2.0 - 20.0, r: 0.16, g: 0.12, b: 0.08, a: 0.95)
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
                    |> if (world.frame == 40 and world.live == 0)
                        | then |> libs/host:quit()
                ! key-down k when k.code == 53 |> libs/host:quit()
                ! mouse-move e
                    |> std/store:stored { world.mx: @as(i64, @intFromFloat(e.x)), world.my: @as(i64, @intFromFloat(e.y)), world.hover: -1 }
                    |> std/store:query(hit)
                        ! query hi when (hi.cl == 0 or e.y >= fworld.ly0 and e.y < fworld.ly1) and e.x >= hi.x and e.x < hi.x + hi.w and e.y >= hi.y and e.y < hi.y + hi.h
                            |> std/store:stored { world.hover: hi.seq }
                ! mouse-down e
                    |> std/store:stored { world.pdown: 1, world.down: -1 }
                    |> std/store:query(hit)
                        ! query hi when (hi.cl == 0 or e.y >= fworld.ly0 and e.y < fworld.ly1) and e.x >= hi.x and e.x < hi.x + hi.w and e.y >= hi.y and e.y < hi.y + hi.h
                            |> std/store:stored { world.down: hi.seq }
                ! mouse-up e
                    |> std/store:stored { world.pdown: 0 }
                    |> std/store:query(hit)
                        ! query hi when (hi.cl == 0 or e.y >= fworld.ly0 and e.y < fworld.ly1) and world.down == hi.seq and e.x >= hi.x and e.x < hi.x + hi.w and e.y >= hi.y and e.y < hi.y + hi.h
                            |> std/store:query(uids)
                                ! query u when u.uid == world.down
                                    |> std/store:stored { world.sel: world.down }
                    |> std/store:stored { world.down: -1 }
                ! scroll e
                    |> if (e.x >= fworld.lx0 and e.x < fworld.lx1 and e.y >= fworld.ly0 and e.y < fworld.ly1)
                        | then |> std/store:stored { fworld.scroll: @min(@max(0.0, fworld.scroll - e.dy), @max(0.0, @as(f64, @floatFromInt(world.icount + 1)) * 56.0 + 10.0 - (fworld.ly1 - fworld.ly0))) }
                ! close |> libs/host:quit()
                | done w2 |> libs/clay:drop(cl: h) |> libs/metal:window.close(win: w2) |> std/io:print.ln("gallery: closed (snapped)")
    | err e |> std/io:print.ln("metal init failed: {{ e:s }}")
| err e3 |> std/io:print.ln("clay init failed: {{ e3:s }}")
