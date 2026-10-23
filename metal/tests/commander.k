// OMNI — the commander. A `>` line where you type the wire grammar the
// agent would: `file-open(path: "/abs/path.png")` runs through the real
// bridge — the pool mints custody, the surface materializes a document at
// its slot. Images decode and show; everything else is a document tile.
// `file-close(handle: "a1b2c3")` discharges. Drift = age since mint.
// D toggles drift, esc quits.
//
//   mkdir -p /tmp/omni_world
//   koruc run metal/tests/commander.k

import libs/host
import libs/metal
import std/bridge
import std/store
import std/string
import std/io
import app/omni_img
import libs/components

std/store:new(world) { frame: 0[i64], caret: 0[i64], face: 0[i64], drift: 1[i64], remote: 0[i64] }

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
    rx: f64, ry: f64, rw: f64, rh: f64
}

std/store:insert(res) { slot: 0, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
| row _ |> std/store:insert(res) { slot: 1, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
    | row _ |> std/store:insert(res) { slot: 2, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
        | row _ |> std/store:insert(res) { slot: 3, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
            | row _ |> std/store:insert(res) { slot: 4, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                | row _ |> std/store:insert(res) { slot: 5, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                    | row _ |> std/store:insert(res) { slot: 6, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                        | row _ |> std/store:insert(res) { slot: 7, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                            | row _ |> std/store:insert(res) { slot: 8, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                                | row _ |> std/store:insert(res) { slot: 9, alive: 0, kind: 0, tex: 0, born: 0, touched: 0, t: 0.0, s: 1.0, ar: 1.5, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                                    | row _ |> _

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_world"): br
|> std/string:from-page(text: "")
    | ok a |> std/string:take(s: a): txt
        |> std/string:from-page(text: "file-open(path: \"/abs/x.png\") — enter runs it on the bridge")
            | ok b |> std/string:take(s: b): status
                |> libs/metal:window.open(width: 960, height: 640, title: "omni — commander")
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
                                // The room.
                                |> libs/metal:draw.silk(f, x: 0.0, y: 0.0, w: 960.0, h: 640.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.35, folds: 3.0, sheen: 0.7, pearl: 0.45)
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
                                                    | then |> libs/components:remote(f, tex: world.remote, cx: 480.0, cy: 280.0, h: 340.0, glow: 0.12 + 0.6 * if (world.frame % 140 < 70) @as(f64, @floatFromInt(world.frame % 140)) / 70.0 else @as(f64, @floatFromInt(140 - world.frame % 140)) / 70.0)
                                        |> if (e.alive == 1)
                                            | then |> if (e.kind == 2)
                                                | then |> if (world.face > 0)
                                                    | then |> libs/components:wordmark(win: w, f, world.face, text: "omni", size: 26.0, cx: 480.0, y: 20.0, r: 0.16, g: 0.12, b: 0.08, a: 0.55)
                                        |> if (e.alive == 1)
                                            | then |> if (e.kind == 3)
                                                | then |> libs/components:caption(win: w, f, text: "siri remote", cx: 480.0, y: 462.0, a: 0.12 + 0.6 * if (world.frame % 140 < 70) @as(f64, @floatFromInt(world.frame % 140)) / 70.0 else @as(f64, @floatFromInt(140 - world.frame % 140)) / 70.0)
                                // The custody plane — the surface draws what the bridge says lives.
                                |> std/store:query(res)
                                    ! query r
                                        |> app/omni_img:res-live(r.slot) : lv
                                            |> app/omni_img:res-kind(r.slot) : kd
                                                |> if (lv == 1)
                                                    | then |> if (r.alive == 0)
                                                        | then |> std/store:stored { r.alive: 1, r.born: world.frame, r.touched: world.frame, r.kind: kd }
                                                |> if (lv == 0)
                                                    | then |> if (r.alive == 1)
                                                        | then |> std/store:stored { r.alive: 0, r.tex: 0 }
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
                                                |> std/store:stored { r.rw: @as(f64, if (r.ar >= 1.0) 150.0 else 150.0 * r.ar) * r.s, r.rh: @as(f64, if (r.ar >= 1.0) 150.0 / r.ar else 150.0) * r.s }
                                                |> std/store:stored { r.rx: 100.0 + @as(f64, @floatFromInt(r.slot % 5)) * 170.0 * (1.0 - 0.55 * r.t) + (264.0 + @as(f64, @floatFromInt(r.slot % 5)) * 60.0) * r.t - r.rw / 2.0, r.ry: 140.0 + @as(f64, if (r.slot < 5) 0.0 else 190.0) * (1.0 - 0.55 * r.t) + (113.0 + @as(f64, if (r.slot < 5) 0.0 else 60.0)) * r.t - r.rh / 2.0 }
                                                |> libs/metal:draw.silk(f, x: r.rx, y: r.ry, w: r.rw, h: r.rh, radius: 10.0, r: 0.91, g: 0.85, b: 0.72, a: @as(f64, @floatFromInt(r.alive)) * (1.0 - 0.5 * r.t) * @as(f64, if (r.tex > 0) 0.3 else 1.0), angle: 0.25 + @as(f64, @floatFromInt(r.slot)) * 0.4, folds: 2.0, sheen: 1.0, pearl: 0.4 + 0.6 * r.t)
                                                |> if (r.tex > 0)
                                                    | then |> libs/metal:draw.image(f, r.tex, x: r.rx + 8.0 * r.s, y: r.ry + 8.0 * r.s, w: r.rw - 16.0 * r.s, h: r.rh - 16.0 * r.s)
                                                |> app/omni_img:res-id(r.slot) : hid
                                                    |> if (r.alive == 1)
                                                        | then |> libs/metal:draw.text(f, x: r.rx + 6.0 * r.s, y: r.ry + r.rh + 4.0, size: 11.0, r: 0.16, g: 0.12, b: 0.08, a: (1.0 - 0.5 * r.t) * 0.8, text: hid)
                                // The commander strip — the wire grammar, typed by hand.
                                |> libs/metal:draw.rect(f, x: 0.0, y: 560.0, w: 960.0, h: 80.0, r: 0.16, g: 0.12, b: 0.08, a: 0.92)
                                |> libs/metal:draw.text(f, x: 30.0, y: 582.0, size: 20.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, text: "> ")
                                |> libs/metal:text.offset(win: w, text: "> ", size: 20.0, face: 0, index: 2) : px
                                    |> libs/metal:draw.text(f, x: 30.0 + px, y: 582.0, size: 20.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, text: txt.data)
                                    |> libs/metal:text.offset(win: w, text: txt.data, size: 20.0, face: 0, index: world.caret) : cx
                                        |> libs/metal:draw.rect(f, x: 30.0 + px + cx, y: 584.0, w: 1.5, h: 24.0, r: 0.95, g: 0.85, b: 0.4, a: 1.0)
                                        |> libs/metal:draw.text(f, x: 560.0, y: 588.0, size: 12.0, r: 0.91, g: 0.85, b: 0.72, a: 0.6, text: status.data)
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
                            ! key-down k when k.code == 36
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
                                |> std/store:stored { world.caret: 0 }
                            ! key-down k when k.code == 48
                                |> std/store:query(el)
                                    ! query e
                                        |> if (e.alive == 1)
                                            | then |> std/store:stored { e.alive: 0 }
                            ! key-down k when k.code == 2
                                |> std/store:stored { world.drift: if (world.drift == 0) 1 else 0 }
                            ! key-down k when k.code == 53 |> libs/host:quit()
                            ! close |> libs/host:quit()
                            | done w2 |> libs/metal:window.close(win: w2) |> std/string:free(s: txt) |> std/string:free(s: status) |> std/bridge:close(br) |> std/io:print.ln("commander: closed")
                    | err e |> std/string:free(s: txt) |> std/string:free(s: status) |> std/bridge:close(br) |> std/io:print.ln("metal init failed: {{ e:s }}")
            | err _ |> std/io:print.ln("status page failed")
| err _ |> std/io:print.ln("init failed")
