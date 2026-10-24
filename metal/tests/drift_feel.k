// OMNI spike S1 — drift-feel on the champagne material. The silk is the
// ROOM (full-window background); documents are silk tiles floating on it.
// Depth = f(age): untouched tiles sink toward the horizon, shrink, and go
// spectral — alpha falls, the pearl fringe rises, the fog takes them.
// → cycles focus and stamps touched (touch is a write), T tilts,
// D toggles drift, esc quits. A canned agent materializes two parked
// documents on schedule — its acts carry the violet rule.
//
//   koruc run metal/tests/drift_feel.k
//   sips -s format png /tmp/omni_drift_t60.bmp --out /tmp/omni_drift_t60.png

import libs/host
import libs/metal
import std/store
import std/io

std/store:new(world) { frame: 0[i64], focus: 0[i64], n: 8[i64], tiltT: 0[i64], drift: 1[i64], pa: 0[i64], pb: 0[i64], pc: 0[i64], face: 0[i64] }
std/store:new(cam) { tilt: 0.0[f64] }
std/store:new(mark) { x: 0.0[f64] }

// The resource plane — one row per document. `t` is drift 0..1 (0 = held
// now, 1 = at the fog line); the r* fields are derived per frame.
std/store:new(res, capacity: 10) {
    id: i64,
    cx: f64, cy: f64,
    touched: i64,
    actor: i64, alive: i64,
    t: f64, s: f64,
    rx: f64, ry: f64, rw: f64, rh: f64
}

std/store:insert(res) { id: 0, cx: 140.0, cy: 170.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
| row _ |> std/store:insert(res) { id: 1, cx: 340.0, cy: 170.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
    | row _ |> std/store:insert(res) { id: 2, cx: 540.0, cy: 170.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
        | row h3 |> std/store:insert(res) { id: 3, cx: 740.0, cy: 170.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
            | row _ |> std/store:insert(res) { id: 4, cx: 140.0, cy: 430.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                | row _ |> std/store:insert(res) { id: 5, cx: 340.0, cy: 430.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                    | row _ |> std/store:insert(res) { id: 6, cx: 540.0, cy: 430.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                        | row _ |> std/store:insert(res) { id: 7, cx: 740.0, cy: 430.0, touched: 0, actor: 0, alive: 1, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                            | row _ |> std/store:insert(res) { id: 8, cx: 240.0, cy: 300.0, touched: 0, actor: 1, alive: 0, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                                | row a |> std/store:insert(res) { id: 9, cx: 640.0, cy: 300.0, touched: 0, actor: 1, alive: 0, t: 0.0, s: 1.0, rx: 0.0, ry: 0.0, rw: 0.0, rh: 0.0 }
                                    | row b |> std/store:stored { world.pa: a, world.pb: b, world.pc: h3 }

libs/metal:window.open(width: 960, height: 620, title: "omni — drift feel, esc quits")
| win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
        |> libs/metal:font.load(win: w, path: "/tmp/archivo/Archivo_Black/ArchivoBlack-Regular.ttf")
            | font fnt |> std/store:stored { world.face: fnt }
                |> libs/metal:text.offset(win: w, text: "omni", size: 26.0, face: fnt, index: 4) : mw
                |> std/store:stored { mark.x: 480.0 - mw / 2.0 }
            | err e |> std/io:print.ln("font failed: {{ e:s }}")
        |> libs/metal:frames(win: w, count: 99999)
            ! frame f
                |> std/store:stored { world.frame: world.frame + 1 }
                |> std/store:stored { cam.tilt: cam.tilt + (@as(f64, @floatFromInt(world.tiltT)) - cam.tilt) * 0.10 }
                // The agent acts on a schedule: two parked documents materialize,
                // and row h3 is flagged agent-touched — the violet rule marks it.
                |> if (world.frame == 100)
                    | then |> std/store:stored { res[world.pa].alive: 1, res[world.pa].touched: world.frame }
                |> if (world.frame == 170)
                    | then |> std/store:stored { res[world.pb].alive: 1, res[world.pb].touched: world.frame }
                |> if (world.frame == 170)
                    | then |> std/store:stored { res[world.pc].actor: 1, res[world.pc].touched: world.frame }
                // The room: champagne silk wall-to-wall, no authored chrome.
                |> libs/metal:draw.roundrect(f, x: 0.0, y: 0.0, w: 960.0, h: 620.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
                |> if (world.face > 0)
                    | then |> libs/metal:draw.textface(f, mark.x, y: 22.0, size: 26.0, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "omni")
                // Fog line — the vanishing shelf documents drift toward, revealed
                // only when the plane tilts.
                |> libs/metal:draw.rect(f, x: 0.0, y: 228.0, w: 960.0, h: 2.0, r: 0.45, g: 0.45, b: 0.55, a: cam.tilt * 0.4)
                |> std/store:query(res)
                    ! query r
                        // Drift clock: 240 frames (~4s) of neglect to reach the fog
                        // line. Touched stamps reset it — that is law 6.
                        |> std/store:stored { r.t: if (world.drift == 0) 0.0 else if (r.alive == 0) 0.0 else if (world.frame - r.touched > 240) 1.0 else @as(f64, @floatFromInt(world.frame - r.touched)) / 240.0 }
                        |> std/store:stored { r.s: 1.0 - 0.62 * r.t }
                        |> std/store:stored { r.rx: r.cx * (1.0 - r.t) + 480.0 * r.t - 75.0 * r.s, r.ry: r.cy * (1.0 - r.t) + 205.0 * r.t - 48.0 * r.s + (205.0 - r.cy) * 0.55 * cam.tilt - r.t * 90.0 * cam.tilt, r.rw: 150.0 * r.s, r.rh: 96.0 * r.s * (1.0 - 0.35 * cam.tilt) }
                        // The document: silk tile whose pearl fringe RISES with
                        // depth — spectral is what discharged looks like — while
                        // alpha falls toward the fog.
                        |> libs/metal:draw.roundrect(f, x: r.rx, y: r.ry, w: r.rw, h: r.rh, radius: 10.0, r: 0.91, g: 0.85, b: 0.72, a: @as(f64, @floatFromInt(r.alive)) * (1.0 - 0.78 * r.t))
                        // Title rule — the document reading, a single dark line.
                        |> libs/metal:draw.rect(f, x: r.rx + 12.0 * r.s, y: r.ry + 14.0 * r.s, w: r.rw * 0.55, h: 3.0, r: 0.16, g: 0.12, b: 0.08, a: @as(f64, @floatFromInt(r.alive)) * (1.0 - 0.78 * r.t) * 0.7)
                        // Agent-acted: the violet rule under the tile.
                        |> libs/metal:draw.rect(f, x: r.rx, y: r.ry + r.rh + 5.0, w: r.rw, h: 4.0, r: 0.65, g: 0.35, b: 1.0, a: @as(f64, @floatFromInt(r.alive * r.actor)))
                        // Focus pip.
                        |> libs/metal:draw.rect(f, x: r.rx + r.rw / 2.0 - 4.0, y: r.ry - 13.0, w: 8.0, h: 8.0, r: 0.16, g: 0.12, b: 0.08, a: @as(f64, @floatFromInt(r.alive)) * (1.0 - 0.78 * r.t) * @as(f64, if (r.id == world.focus) 1.0 else 0.25))
                |> if (world.frame == 60)
                    | then |> libs/metal:window.snap(path: "/tmp/omni_drift_t60.bmp")
                |> if (world.frame == 300)
                    | then |> libs/metal:window.snap(path: "/tmp/omni_drift_t300.bmp")
            ! key-down k when k.code == 124
                |> std/store:stored { world.focus: if (world.focus + 1 >= world.n) 0 else world.focus + 1 }
                |> std/store:query(res)
                    ! query r when r.id == world.focus
                        |> std/store:stored { r.touched: world.frame }
            ! key-down k when k.code == 17
                |> std/store:stored { world.tiltT: if (world.tiltT == 0) 1 else 0 }
            ! key-down k when k.code == 2
                |> std/store:stored { world.drift: if (world.drift == 0) 1 else 0 }
            ! key-down k when k.code == 53 |> libs/host:quit()
            ! close |> libs/host:quit()
            | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("drift feel: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
