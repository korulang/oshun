// OMNI — the commander. A `>` line where you type the wire grammar the
// agent would: `file-open(path: "/abs/path.png")` runs through the real
// bridge — the pool mints custody, the surface materializes a document at
// its slot. Images decode and show; everything else is a document tile.
// `file-close(handle: "a1b2c3")` discharges. Drift = age since mint.
// D toggles drift, Tab dismisses boot elements, esc quits.
//
// Layout: the chrome regions (wordmark band, commander strip, custody
// plane) are SOLVED, not written — a dock dialect tree in libs/ui over
// the libs/clay solver. Resize the window and the regions reflow; every
// draw reads world.* rects the solver handed back this frame.
//
//   mkdir -p /tmp/omni_world
//   koruc run metal/tests/commander.k

import libs/host
import libs/metal
import libs/clay
import libs/ui
import libs/math
import libs/hist
import std/bridge
import std/store
import std/string
import std/io
import app/omni_img
import libs/components

std/store:new(world) { frame: 0[i64], caret: 0[i64], face: 0[i64], drift: 1[i64], remote: 0[i64], hi: 0[i64], cmdv: 0[i64], hubv: 0[i64], foci: 10[i64], fscan: 0[i64], fwrap: 0[i64], mic: 0[i64] }

// The solved view — the rects clay hands back each frame. Stores take one
// scalar type per table, so the f64 geometry lives in its own store.
std/store:new(view) {
    topx: 0.0[f64], topy: 0.0[f64], topw: 0.0[f64], toph: 0.0[f64],
    stripx: 0.0[f64], stripy: 0.0[f64], stripw: 0.0[f64], striph: 0.0[f64],
    planex: 0.0[f64], planey: 0.0[f64], planew: 0.0[f64], planeh: 0.0[f64]
}

// The surface itself is a store — elements are rows, `kind` is the variant
// tag, render is dispatch. Boot seeds the remote glyph, the wordmark, and
// its caption; `ttl` is the frame an element auto-dismisses (0 = never,
// only a keypress removes it).
std/store:new(el, capacity: 8) {
    id: i64, kind: i64, alive: i64, ttl: i64
}

std/store:insert(el) { id: 1, kind: 1, alive: 1, ttl: 0 }
| row _ |> std/store:insert(el) { id: 2, kind: 2, alive: 1, ttl: 0 }
    | row _ |> std/store:insert(el) { id: 3, kind: 3, alive: 1, ttl: 0 }
        | row _ |> _

// The custody plane — slot-keyed rows. Slot is the module's stable id;
// alive flips when the bridge mints/discharges through the vocabulary.
std/store:new(res, capacity: 10) {
    slot: i64,
    alive: i64, kind: i64, tex: i64,
    born: i64, touched: i64,
    t: f64, s: f64, ar: f64,
    rx: f64, ry: f64, rw: f64, rh: f64, px: f64, py: f64, vx: f64, vy: f64
}

std/store:insert(res) { slot: 0, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
| row _ |> std/store:insert(res) { slot: 1, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
    | row _ |> std/store:insert(res) { slot: 2, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
        | row _ |> std/store:insert(res) { slot: 3, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
            | row _ |> std/store:insert(res) { slot: 4, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
                | row _ |> std/store:insert(res) { slot: 5, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
                    | row _ |> std/store:insert(res) { slot: 6, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
                        | row _ |> std/store:insert(res) { slot: 7, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
                            | row _ |> std/store:insert(res) { slot: 8, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
                                | row _ |> std/store:insert(res) { slot: 9, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0, px: 0.0, py: 0.0, vx: 0.0, vy: 0.0 }
                                    | row _ |> _

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_world"): br
|> std/string:from-page(text: "")
    | ok a |> std/string:take(s: a): txt
        |> std/string:from-page(text: "file-open(path: \"/abs/x.png\") — enter runs it on the bridge")
            | ok b |> std/string:take(s: b): status
                |> libs/clay:init(width: 960.0, height: 640.0)
                    | cl h |> libs/metal:window.open(width: 960, height: 640, title: "omni — commander")
                        | win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
                            |> libs/metal:font.load(win: w, path: "/tmp/archivo/Archivo_Black/ArchivoBlack-Regular.ttf")
                                | font fnt |> std/store:stored { world.face: fnt }
                                | err e |> std/io:print.ln("font failed: {{ e:s }}")
                            |> libs/metal:image.load(win: w, path: "/Users/larsde/Downloads/apple-remote.png")
                                | img rimg |> std/store:stored { world.remote: rimg }
                                | err e |> std/io:print.ln("remote png: {{ e:s }}")
                            |> libs/metal:frames(win: w, count: 99999)
                                ! frame f
                                    |> std/store:stored { world.frame: world.frame + 1 }
                                    |> libs/metal:window.size(win: w) : sz
                                    // The room.
                                    |> libs/metal:draw.silk(f, x: 0.0, y: 0.0, sz.w, sz.h, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.35, folds: 3.0, sheen: 0.7, pearl: 0.45)
                                    // The chrome is solved: a dock tree — wordmark band top,
                                    // commander strip bottom, custody plane fill — and the
                                    // commands it hands back are the rects everything reads.
                                    |> libs/clay:dims(cl: h, width: sz.w, height: sz.h)
                                    |> libs/clay:layout(cl: h)
                                        ! tree t
                                            |> libs/ui:panelx(t, dock: "", ws: "star", w: 0.0, hs: "star", h: 0.0, dir: "ttb", gap: 0, pad: 0, ax: "start", ay: "start", r: 0.0, g: 0.0, b: 0.0, a: 1.0, fl: 0, fx: 0.0, fy: 0.0, eid: 0)
                                            |> libs/ui:panelx(t, dock: "top", ws: "star", w: 0.0, hs: "fix", h: 56.0, dir: "ltr", gap: 0, pad: 0, ax: "start", ay: "start", r: 0.0, g: 0.0, b: 0.0, a: 1.0, fl: 0, fx: 0.0, fy: 0.0, eid: 1)
                                            |> libs/clay:el.close-to(t, d: 1)
                                            // dock words size, they do not place — the strip lands on the
                                            // bottom edge because it is the LAST child and the fill above
                                            // it grows (WPF's last-child-fill, through ordering not words).
                                            |> libs/ui:panelx(t, dock: "fill", ws: "star", w: 0.0, hs: "star", h: 0.0, dir: "ltr", gap: 0, pad: 0, ax: "start", ay: "start", r: 0.0, g: 0.0, b: 0.0, a: 1.0, fl: 0, fx: 0.0, fy: 0.0, eid: 3)
                                            |> libs/clay:el.close-to(t, d: 1)
                                            |> libs/ui:panelx(t, dock: "bottom", ws: "star", w: 0.0, hs: "fix", h: 80.0, dir: "ltr", gap: 0, pad: 0, ax: "start", ay: "start", r: 0.0, g: 0.0, b: 0.0, a: 1.0, fl: 0, fx: 0.0, fy: 0.0, eid: 2)
                                            |> libs/clay:el.close-to(t, d: 0)
                                        | solved cls |> libs/clay:each(cl: cls)
                                            ! cmd rc |> if (rc.ud == 1)
                                                | then |> std/store:stored { view.topx: rc.x, view.topy: rc.y, view.topw: rc.w, view.toph: rc.h }
                                                |> if (rc.ud == 2)
                                                    | then |> std/store:stored { view.stripx: rc.x, view.stripy: rc.y, view.stripw: rc.w, view.striph: rc.h }
                                                |> if (rc.ud == 3)
                                                    | then |> std/store:stored { view.planex: rc.x, view.planey: rc.y, view.planew: rc.w, view.planeh: rc.h }
                                            | drained |> _
                                    // The bridge's presence — hidden until the boot layer is
                                    // dismissed, so it never crowds the remote on open.
                                    |> if (world.hubv == 1)
                                        | then |> libs/components:hub(win: w, f, text: "omni", cx: view.planex + view.planew / 2.0, cy: view.planey + view.planeh * 0.48, r: view.planeh * 0.10, glow: 0.12 + 0.6 * if (world.frame % 140 < 70) @as(f64, @floatFromInt(world.frame % 140)) / 70.0 else @as(f64, @floatFromInt(140 - world.frame % 140)) / 70.0)
                                    // Element lifecycle — a row past its ttl dies; keypress kills too.
                                    |> std/store:query(el)
                                        ! query e
                                            |> if (e.ttl > 0)
                                                | then |> if (world.frame > e.ttl)
                                                    | then |> std/store:stored { e.alive: 0 }
                                    // The surface renders what the store holds — kind-dispatched.
                                    |> std/store:query(el)
                                        ! query e
                                            |> if (e.alive == 1)
                                                | then |> if (e.kind == 1)
                                                    | then |> if (world.remote > 0)
                                                        | then |> libs/components:remote(f, tex: world.remote, cx: view.planex + view.planew / 2.0, cy: view.planey + view.planeh * 0.44, h: view.planeh * 0.67, glow: 0.12 + 0.6 * if (world.frame % 140 < 70) @as(f64, @floatFromInt(world.frame % 140)) / 70.0 else @as(f64, @floatFromInt(140 - world.frame % 140)) / 70.0)
                                            |> if (e.alive == 1)
                                                | then |> if (e.kind == 2)
                                                    | then |> if (world.face > 0)
                                                        | then |> libs/components:wordmark(win: w, f, world.face, text: "omni", size: 26.0, cx: view.topx + view.topw / 2.0, y: view.topy + 20.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55)
                                            |> if (e.alive == 1)
                                                | then |> if (e.kind == 3)
                                                    | then |> libs/components:caption(win: w, f, text: "siri remote", cx: view.planex + view.planew / 2.0, y: view.planey + view.planeh * 0.82, a: 0.12 + 0.6 * if (world.frame % 140 < 70) @as(f64, @floatFromInt(world.frame % 140)) / 70.0 else @as(f64, @floatFromInt(140 - world.frame % 140)) / 70.0)
                                    // Hold-to-talk: the mic button's HID event already lands here;
                                    // its audio rides the HCI-snoop bridge into /tmp/omni_remote_mic.wav.
                                    |> if (world.mic == 1)
                                        | then |> libs/components:caption(win: w, f, text: "listening", cx: view.planex + view.planew / 2.0, y: view.planey + view.planeh * 0.10, a: 0.35 + 0.5 * if (world.frame % 60 < 30) @as(f64, @floatFromInt(world.frame % 60)) / 30.0 else @as(f64, @floatFromInt(60 - world.frame % 60)) / 30.0)
                                    // The custody plane — the surface draws what the bridge says lives.
                                    // Orbit: a mint seeds the card at the hub with an outward fling,
                                    // then a damped spring pulls it toward its slot's anchor on the
                                    // ring. The ring slowly turns; staleness sags the target radius —
                                    // drift is orbital decay, not a lerp to a landing spot.
                                    |> std/store:query(res)
                                        ! query r
                                            |> app/omni_img:res-live(r.slot) : lv
                                                |> app/omni_img:res-kind(r.slot) : kd
                                                    |> if (lv == 1)
                                                        | then |> if (r.alive == 0)
                                                            | then |> libs/math:cos(x: @as(f64, @floatFromInt(r.slot)) * 0.6283) : c0
                                                                |> libs/math:sin(x: @as(f64, @floatFromInt(r.slot)) * 0.6283) : s0
                                                                    |> std/store:stored { r.alive: 1, r.born: world.frame, r.touched: world.frame, r.kind: kd, r.px: view.planex + view.planew / 2.0, r.py: view.planey + view.planeh * 0.48, r.vx: c0 * 6.0, r.vy: s0 * 6.0 }
                                                    |> if (lv == 0)
                                                        | then |> if (r.alive == 1)
                                                            | then |> if (r.tex > 0)
                                                                | then |> libs/metal:image.free(r.tex)
                                                            |> std/store:stored { r.alive: 0, r.tex: 0 }
                                                    |> if (r.alive == 1)
                                                        | then |> if (r.kind == 1)
                                                            | then |> if (r.tex == 0)
                                                                | then |> app/omni_img:res-path(r.slot) : p
                                                                    |> libs/metal:image.load(win: w, path: p)
                                                                        | img t |> libs/metal:image.width(tex: t) : iw
                                                                            |> libs/metal:image.height(tex: t) : ih
                                                                                |> std/store:stored { r.tex: t, r.ar: @as(f64, @floatFromInt(iw)) / @as(f64, @floatFromInt(ih)) }
                                                                        | err e |> std/io:print.ln("image: {{ e:s }}")
                                                    |> std/store:stored { r.t: if (r.alive == 0) 0.0 else if (world.drift == 0) 0.0 else if (world.frame - r.touched > 240) 1.0 else @as(f64, @floatFromInt(world.frame - r.touched)) / 240.0 }
                                                    |> std/store:stored { r.s: 1.0 - 0.35 * r.t }
                                                    |> std/store:stored { r.rw: @as(f64, if (r.ar >= 1.0) view.planeh * 0.34 else view.planeh * 0.34 * r.ar) * r.s, r.rh: @as(f64, if (r.ar >= 1.0) view.planeh * 0.34 / r.ar else view.planeh * 0.34) * r.s }
                                                    |> libs/math:cos(x: @as(f64, @floatFromInt(r.slot)) * 0.6283 + @as(f64, @floatFromInt(world.frame)) * 0.0005) : ca
                                                        |> libs/math:sin(x: @as(f64, @floatFromInt(r.slot)) * 0.6283 + @as(f64, @floatFromInt(world.frame)) * 0.0005) : sa
                                                            |> std/store:stored { r.vx: (r.vx + (view.planex + view.planew / 2.0 + ca * (view.planeh * 0.30 + r.t * view.planeh * 0.14) - r.px) * 0.04) * 0.78, r.vy: (r.vy + (view.planey + view.planeh * 0.48 + sa * (view.planeh * 0.30 + r.t * view.planeh * 0.14) - r.py) * 0.04) * 0.78 }
                                                            |> std/store:stored { r.px: r.px + r.vx, r.py: r.py + r.vy }
                                                            |> std/store:stored { r.rx: r.px - r.rw / 2.0, r.ry: r.py - r.rh / 2.0 }
                                                    |> if (r.slot == world.foci and r.alive == 1)
                                                        | then |> libs/metal:draw.roundrect(f, x: r.rx - 4.0, y: r.ry - 4.0, w: r.rw + 8.0, h: r.rh + 8.0, radius: 13.0, r: 0.95, g: 0.85, b: 0.4, a: 0.9)
                                                    |> libs/metal:draw.panel(f, x: r.rx, y: r.ry, w: r.rw, h: r.rh, radius: 10.0, r: 0.97, g: 0.95, b: 0.89, a: @as(f64, @floatFromInt(r.alive)) * (1.0 - 0.5 * r.t) * @as(f64, if (r.tex > 0) 0.55 else 0.9), bw: 1.0, br: 0.80, bg: 0.70, bb: 0.55, ba: @as(f64, @floatFromInt(r.alive)) * (1.0 - 0.5 * r.t) * 0.5)
                                                    |> if (r.tex > 0)
                                                        | then |> libs/metal:draw.image(f, r.tex, x: r.rx + 8.0 * r.s, y: r.ry + 8.0 * r.s, w: r.rw - 16.0 * r.s, h: r.rh - 16.0 * r.s)
                                                    // kind dispatch — the bridge's kind field picks the
                                                    // renderer: 1 image → its decoded texture above,
                                                    // 2 audio → the waveform the bytes decoded into.
                                                    |> if (r.alive == 1 and r.kind == 2)
                                                        | then |> libs/components:waveform(f, r.slot, x: r.rx + 10.0 * r.s, y: r.ry + 10.0 * r.s, w: r.rw - 20.0 * r.s, h: r.rh - 20.0 * r.s, a: (1.0 - 0.5 * r.t) * 0.9)
                                                    |> app/omni_img:res-id(r.slot) : hid
                                                        |> if (r.alive == 1)
                                                            | then |> libs/metal:draw.text(f, x: r.rx + 6.0 * r.s, y: r.ry + r.rh + 4.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: (1.0 - 0.5 * r.t) * 0.8, text: hid)
                                    // The commander strip — hidden at boot; Tab reveals and toggles it.
                                    |> if (world.cmdv == 1)
                                        | then |> libs/metal:draw.rect(f, x: view.stripx, y: view.stripy, w: view.stripw, h: view.striph, r: 0.16, g: 0.12, b: 0.08, a: 0.92)
                                            |> libs/metal:draw.text(f, x: view.stripx + 30.0, y: view.stripy + 22.0, size: 20.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, text: "> ")
                                            |> libs/metal:text.offset(win: w, text: "> ", size: 20.0, face: 0, index: 2) : px
                                            |> libs/metal:draw.text(f, x: view.stripx + 30.0 + px, y: view.stripy + 22.0, size: 20.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, text: txt.data)
                                            |> libs/metal:text.offset(win: w, text: txt.data, size: 20.0, face: 0, index: world.caret) : cx
                                            |> libs/metal:draw.rect(f, x: view.stripx + 30.0 + px + cx, y: view.stripy + 24.0, w: 1.5, h: 24.0, r: 0.95, g: 0.85, b: 0.4, a: 1.0)
                                            |> libs/metal:draw.text(f, x: view.stripx + view.stripw - 380.0, y: view.stripy + 28.0, size: 12.0, r: 0.91, g: 0.85, b: 0.72, a: 0.6, text: status.data)
                                    |> if (world.frame == 60)
                                        | then |> libs/metal:window.snap(path: "/tmp/omni_cmd_t60.bmp")
                                    |> if (world.frame == 200)
                                        | then |> libs/metal:window.snap(path: "/tmp/omni_cmd_minted.bmp")
                                    |> if (world.frame == 600)
                                        | then |> libs/metal:window.snap(path: "/tmp/omni_cmd_t600.bmp")
                                ! key-down k when k.chars.len > 0
                                    |> std/string:len(s: txt) : n
                                        |> std/string:substring(s: txt, start: 0, end: @as(usize, @intCast(world.caret)))
                                            | ok left |> std/string:substring(s: txt, start: @as(usize, @intCast(world.caret)), end: n)
                                                | ok right |> std/string:clear(s: txt) |> std/string:append(s: txt, text: left.data)
                                                    | ok |> std/string:append(s: txt, text: k.chars)
                                                        | ok |> std/string:append(s: txt, text: right.data)
                                                            | ok |> std/string:free(s: left) |> std/string:free(s: right)
                                                                |> std/store:stored { world.caret: world.caret + @as(i64, @intCast(k.chars.len)) }
                                                            | err _ |> std/string:free(s: left) |> std/string:free(s: right)
                                                        | err _ |> std/string:free(s: left) |> std/string:free(s: right)
                                                    | err _ |> std/string:free(s: left) |> std/string:free(s: right)
                                                | err _ |> std/string:free(s: left)
                                            | err _ |> _
                                ! key-down k when k.code == 51
                                    |> if (world.caret > 0)
                                        | then |> std/string:len(s: txt) : n
                                            |> std/string:substring(s: txt, start: 0, end: @as(usize, @intCast(world.caret - 1)))
                                                | ok left |> std/string:substring(s: txt, start: @as(usize, @intCast(world.caret)), end: n)
                                                    | ok right |> std/string:clear(s: txt) |> std/string:append(s: txt, text: left.data)
                                                        | ok |> std/string:append(s: txt, text: right.data)
                                                            | ok |> std/string:free(s: left) |> std/string:free(s: right)
                                                                |> std/store:stored { world.caret: world.caret - 1 }
                                                            | err _ |> std/string:free(s: left) |> std/string:free(s: right)
                                                        | err _ |> std/string:free(s: left) |> std/string:free(s: right)
                                                    | err _ |> std/string:free(s: left)
                                                | err _ |> _
                                ! key-down k when k.code == 123
                                    |> std/store:stored { world.caret: if (world.caret > 0) world.caret - 1 else 0 }
                                ! key-down k when k.code == 124
                                    |> std/string:len(s: txt) : n
                                        |> std/store:stored { world.caret: if (world.caret < @as(i64, @intCast(n))) world.caret + 1 else @as(i64, @intCast(n)) }
                                ! key-down k when k.code == 126
                                    |> libs/hist:count() : hc
                                        |> std/store:stored { world.hi: if (world.hi < hc) world.hi + 1 else world.hi }
                                        |> if (world.hi > 0)
                                            | then |> libs/hist:get(i: world.hi - 1) : ht
                                                |> std/string:clear(s: txt)
                                                |> std/string:append(s: txt, text: ht)
                                                    | ok |> std/string:len(s: txt) : nl
                                                        |> std/store:stored { world.caret: @as(i64, @intCast(nl)) }
                                                    | err _ |> _
                                ! key-down k when k.code == 125
                                    |> std/store:stored { world.hi: if (world.hi > 0) world.hi - 1 else 0 }
                                    |> if (world.hi > 0)
                                        | then |> libs/hist:get(i: world.hi - 1) : ht
                                            |> std/string:clear(s: txt)
                                            |> std/string:append(s: txt, text: ht)
                                                | ok |> std/string:len(s: txt) : nl
                                                    |> std/store:stored { world.caret: @as(i64, @intCast(nl)) }
                                                | err _ |> _
                                    |> if (world.hi == 0)
                                        | then |> std/string:clear(s: txt)
                                            |> std/store:stored { world.caret: 0 }
                                ! key-down k when k.code == 36
                                    |> std/string:len(s: txt) : nl0
                                        |> if (nl0 > 0)
                                            | then |> libs/hist:push(text: txt.data)
                                    |> std/bridge:run(br, source: txt.data)
                                        | result _ |> std/string:clear(s: status) |> std/string:append(s: status, text: "ok — minted")
                                            | ok |> _
                                            | err _ |> _
                                        | error e |> std/string:clear(s: status) |> std/string:append(s: status, text: "error: ")
                                            | ok |> std/string:append(s: status, text: e.message)
                                                | ok |> _
                                                | err _ |> _
                                            | err _ |> _
                                        | defined d |> std/string:clear(s: status) |> std/string:append(s: status, text: "defined ")
                                            | ok |> std/string:append(s: status, text: d)
                                                | ok |> _
                                                | err _ |> _
                                            | err _ |> _
                                        | residue _ |> std/string:clear(s: status) |> std/string:append(s: status, text: "residue")
                                            | ok |> _
                                            | err _ |> _
                                        | unhandled-branch ub |> std/string:clear(s: status) |> std/string:append(s: status, text: "unhandled ")
                                            | ok |> std/string:append(s: status, text: ub.branch)
                                                | ok |> _
                                                | err _ |> _
                                            | err _ |> _
                                        | partial _ |> std/string:clear(s: status) |> std/string:append(s: status, text: "partial")
                                            | ok |> _
                                            | err _ |> _
                                    |> std/string:clear(s: txt)
                                    |> std/store:stored { world.caret: 0, world.hi: 0 }
                                ! key-down k when k.code == 48
                                    |> std/store:query(el)
                                        ! query e
                                            |> if (e.alive == 1)
                                                | then |> std/store:stored { e.alive: 0 }
                                    |> std/store:stored { world.hubv: 1, world.cmdv: if (world.cmdv == 0) 1 else 0 }
                                ! key-down k when k.code == 2
                                    |> std/store:stored { world.drift: if (world.drift == 0) 1 else 0 }
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 96   // TV — the remote's Doom-Tab
                                    |> std/store:query(el)
                                        ! query e
                                            |> if (e.alive == 1)
                                                | then |> std/store:stored { e.alive: 0 }
                                    |> std/store:stored { world.hubv: 1, world.cmdv: if (world.cmdv == 0) 1 else 0 }
                                ! remote-button r when r.down == 1 and r.page == 1 and r.button == 134    // back — pop the commander
                                    |> std/store:stored { world.cmdv: 0 }
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 4    // mic — hold to talk
                                    |> std/store:stored { world.mic: 1 }
                                ! remote-button r when r.down == 0 and r.page == 12 and r.button == 4    // mic release — mint the recording onto the bridge
                                    |> std/store:stored { world.mic: 0 }
                                    |> std/bridge:run(br, source: "file-open(path: \"/tmp/omni_remote_mic.wav\")")
                                        | result _ |> _
                                        | error _ |> _
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 205   // play — toggle drift
                                    |> std/store:stored { world.drift: if (world.drift == 0) 1 else 0 }
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 48    // power — quit
                                    |> libs/host:quit()
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 69    // dpad right — focus next card
                                    |> std/store:stored { world.fscan: 99, world.fwrap: 99 }
                                    |> std/store:query(res)
                                        ! query e
                                            |> if (e.alive == 1 and e.slot > world.foci and e.slot < world.fscan)
                                                | then |> std/store:stored { world.fscan: e.slot }
                                            |> if (e.alive == 1 and e.slot < world.fwrap)
                                                | then |> std/store:stored { world.fwrap: e.slot }
                                    |> std/store:stored { world.foci: if (world.fscan < 99) world.fscan else world.fwrap }
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 68    // dpad left — focus previous card
                                    |> std/store:stored { world.fscan: -1, world.fwrap: -1 }
                                    |> std/store:query(res)
                                        ! query e
                                            |> if (e.alive == 1 and e.slot < world.foci and e.slot > world.fscan)
                                                | then |> std/store:stored { world.fscan: e.slot }
                                            |> if (e.alive == 1 and e.slot > world.fwrap)
                                                | then |> std/store:stored { world.fwrap: e.slot }
                                    |> std/store:stored { world.foci: if (world.fscan > -1) world.fscan else world.fwrap }
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 66    // dpad up — history back
                                    |> libs/hist:count() : hc
                                        |> std/store:stored { world.hi: if (world.hi < hc) world.hi + 1 else world.hi }
                                        |> if (world.hi > 0)
                                            | then |> libs/hist:get(i: world.hi - 1) : ht
                                                |> std/string:clear(s: txt)
                                                |> std/string:append(s: txt, text: ht)
                                                    | ok |> std/string:len(s: txt) : nl
                                                        |> std/store:stored { world.caret: @as(i64, @intCast(nl)) }
                                                    | err _ |> _
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 67    // dpad down — history forward
                                    |> std/store:stored { world.hi: if (world.hi > 0) world.hi - 1 else 0 }
                                    |> if (world.hi > 0)
                                        | then |> libs/hist:get(i: world.hi - 1) : ht
                                            |> std/string:clear(s: txt)
                                            |> std/string:append(s: txt, text: ht)
                                                | ok |> std/string:len(s: txt) : nl
                                                    |> std/store:stored { world.caret: @as(i64, @intCast(nl)) }
                                                | err _ |> _
                                    |> if (world.hi == 0)
                                        | then |> std/string:clear(s: txt)
                                            |> std/store:stored { world.caret: 0 }
                                ! remote-button r when r.down == 1 and r.page == 12 and r.button == 128   // center — arm file-close on the focused card
                                    |> if (world.foci < 10)
                                        | then |> app/omni_img:res-live(slot: world.foci) : fl
                                            |> if (fl == 1)
                                                | then |> app/omni_img:res-id(slot: world.foci) : chid
                                                    |> std/string:clear(s: txt)
                                                    |> std/string:append(s: txt, text: "file-close(handle: \"")
                                                        | ok |> std/string:append(s: txt, text: chid)
                                                            | ok |> std/string:append(s: txt, text: "\")")
                                                                | ok |> std/string:len(s: txt) : cn
                                                                    |> std/store:stored { world.caret: @as(i64, @intCast(cn)), world.cmdv: 1, world.hubv: 1 }
                                                                | err _ |> _
                                                            | err _ |> _
                                                        | err _ |> _
                                ! key-down k when k.code == 53 |> libs/host:quit()
                                ! close |> libs/host:quit()
                                | done w2 |> libs/clay:drop(cl: h) |> libs/metal:window.close(win: w2) |> std/string:free(s: txt) |> std/string:free(s: status) |> std/bridge:close(br) |> std/io:print.ln("commander: closed")
                        | err e |> libs/clay:drop(cl: h) |> std/string:free(s: txt) |> std/string:free(s: status) |> std/bridge:close(br) |> std/io:print.ln("metal init failed: {{ e:s }}")
                    | err e2 |> std/io:print.ln("clay init failed: {{ e2:s }}")
            | err _ |> std/io:print.ln("status page failed")
| err _ |> std/io:print.ln("init failed")
