// ui_probe — MC-3 producer for koru-os. A real oshun component — a
// labeled button over a caption — declared through the same
// libs/ui:panelx + libs/ui:text + libs/clay:el.cfg dialect surface and
// solved by libs/clay that gallery_live.k uses, drained as the same
// CmdView stream, and printed as a normalized text dump. No window,
// no metal: the stream IS the artifact — koru/native/cmdview.zig
// rasterizes it into a kwin window backing on the bare-metal target.
//
// Two states per run, the gallery's own idiom (state -> restyle ->
// redraw): ==A== normal palette, ==B== hot palette (the pointer-inside
// variant the kernel selects on hit-test). One text element carries
// the live slot: tx "t=0000" with eid 90 — the kernel rewrites the
// digits per tick; eid 2 marks the button's own commands as the hit
// region. The button rides el.cfg (not panelx) because panelx exposes
// no corner radius — crtl..cbr=10 is what makes it a button and not a
// rect; el.cfg is the same declaration surface gallery_live uses for
// its spacer panels.
//
//   koruc run koruos/ui_probe.k > ui_cmds.txt
//
// Canvas is the window BODY: 316x174 (320x200 backing minus 2px frame
// and 22px titlebar, offset (2,24) kernel-side).

import libs/clay
import libs/ui
import std/io
import std/store

std/store:new(world) { hot: 0[i64] }

// One normalized line per render command — geometry/colors as f64 in
// clay's own units (the kernel rounds); tx rides last, empty for
// non-text commands. Printed INSIDE the cmd arm: clay borrows the
// string through the drain, so the copy must happen there.
//
// el.cfg numeric rails (clay.h enums): wk/hk 3=fixed; dir 1=TTB;
// ax/ay 2=center; corner radius in px on all four corners.

libs/clay:init(width: 316.0, height: 174.0)
| cl h
    // ---- state A: normal -------------------------------------------------
    |> std/io:print.ln("==A==")
    |> libs/clay:layout(cl: h)
        ! tree t
            // root surface — dark panel, children centered as a group
            |> libs/ui:panelx(t, dock: "", ws: "fix", w: 316.0, hs: "fix", h: 174.0, dir: "ttb", gap: 14, pad: 0, ax: "center", ay: "center", r: 16.0, g: 18.0, b: 26.0, a: 255.0, fl: 0, fx: 0.0, fy: 0.0, eid: 1)
            // the button — eid 2 owns the hit region; hot palette when
            // world.hot == 1 (the ==B== pass below); cr=10 all corners
            |> libs/clay:el.open(t)
            |> libs/clay:el.cfg(t, wk: 3, w: 150.0, hk: 3, h: 48.0, dir: 1, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 2, ay: 2,
                r: if (world.hot == 1) 96.0 else 52.0,
                g: if (world.hot == 1) 150.0 else 120.0,
                b: if (world.hot == 1) 255.0 else 246.0,
                a: 255.0,
                fat: 0, fx: 0.0, fy: 0.0, fae: 0, fap: 0, exw: 0.0, exh: 0.0, zi: 0, fct: 0, eid: 2,
                ovr: 0.0, ovg: 0.0, ovb: 0.0, ova: 0.0,
                crtl: 10.0, crtr: 10.0, crbl: 10.0, crbr: 10.0,
                ar: 0.0, br: 0.0, bg: 0.0, bb: 0.0, ba: 0.0,
                bwl: 0, bwr: 0, bwt: 0, bwb: 0, bwc: 0)
            |> libs/ui:text(t, tx: "ENGAGE", fs: 15.0, r: 255.0, g: 255.0, b: 255.0, a: 255.0, eid: 3)
            |> libs/clay:el.close(t)
            // live slot — kernel rewrites the digits (eid 90)
            |> libs/ui:text(t, tx: "t=0000", fs: 11.0, r: 140.0, g: 146.0, b: 160.0, a: 255.0, eid: 90)
            |> libs/clay:el.close(t)
        | solved cA |> libs/clay:each(cl: cA)
            ! cmd rc |> std/io:print.ln("C {{ rc.kind:d }} {{ rc.x:f }} {{ rc.y:f }} {{ rc.w:f }} {{ rc.h:f }} {{ rc.r:f }} {{ rc.g:f }} {{ rc.b:f }} {{ rc.a:f }} {{ rc.fs:f }} {{ rc.ud:d }} {{ rc.ctl:f }} {{ rc.ctr:f }} {{ rc.cbl:f }} {{ rc.cbr:f }} {{ rc.tx:s }}")
            | drained
    // ---- state B: hot ------------------------------------------------------
    |> std/store:stored { world.hot: 1 }
    |> std/io:print.ln("==B==")
    |> libs/clay:layout(cl: h)
        ! tree t
            |> libs/ui:panelx(t, dock: "", ws: "fix", w: 316.0, hs: "fix", h: 174.0, dir: "ttb", gap: 14, pad: 0, ax: "center", ay: "center", r: 16.0, g: 18.0, b: 26.0, a: 255.0, fl: 0, fx: 0.0, fy: 0.0, eid: 1)
            |> libs/clay:el.open(t)
            |> libs/clay:el.cfg(t, wk: 3, w: 150.0, hk: 3, h: 48.0, dir: 1, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 2, ay: 2,
                r: if (world.hot == 1) 96.0 else 52.0,
                g: if (world.hot == 1) 150.0 else 120.0,
                b: if (world.hot == 1) 255.0 else 246.0,
                a: 255.0,
                fat: 0, fx: 0.0, fy: 0.0, fae: 0, fap: 0, exw: 0.0, exh: 0.0, zi: 0, fct: 0, eid: 2,
                ovr: 0.0, ovg: 0.0, ovb: 0.0, ova: 0.0,
                crtl: 10.0, crtr: 10.0, crbl: 10.0, crbr: 10.0,
                ar: 0.0, br: 0.0, bg: 0.0, bb: 0.0, ba: 0.0,
                bwl: 0, bwr: 0, bwt: 0, bwb: 0, bwc: 0)
            |> libs/ui:text(t, tx: "ENGAGE", fs: 15.0, r: 255.0, g: 255.0, b: 255.0, a: 255.0, eid: 3)
            |> libs/clay:el.close(t)
            |> libs/ui:text(t, tx: "t=0000", fs: 11.0, r: 140.0, g: 146.0, b: 160.0, a: 255.0, eid: 90)
            |> libs/clay:el.close(t)
        | solved cB |> libs/clay:each(cl: cB)
            ! cmd rc |> std/io:print.ln("C {{ rc.kind:d }} {{ rc.x:f }} {{ rc.y:f }} {{ rc.w:f }} {{ rc.h:f }} {{ rc.r:f }} {{ rc.g:f }} {{ rc.b:f }} {{ rc.a:f }} {{ rc.fs:f }} {{ rc.ud:d }} {{ rc.ctl:f }} {{ rc.ctr:f }} {{ rc.cbl:f }} {{ rc.cbr:f }} {{ rc.tx:s }}")
            | drained
            |> libs/clay:drop(cl: h)
                |> std/io:print.ln("==END==")
| err e |> std/io:print.ln("clay init failed: {{ e:s }}")
