// gradient — the two-stop gradient primitive, linear + radial.
//
//   koruc run canvas/tests/gradient.k
//   sips -s format png /tmp/gradient.bmp --out /tmp/gradient.png

import libs/host
import libs/canvas
import std/store
import std/io

std/store:new(world) { frame: 0[i64] }

libs/canvas:window.open(width: 640, height: 400, title: "gradient primitive")
| win w |> libs/canvas:window.clear.color(win: w, r: 0.055, g: 0.06, b: 0.075)
    |> libs/canvas:frames(win: w, count: 9999)
        ! frame f
            |> std/store:stored { world.frame: world.frame + 1 }
            // linear, rounded
            |> libs/canvas:draw.gradient(f, x: 40.0, y: 40.0, w: 250.0, h: 150.0, radius: 20.0, x0: 40.0, y0: 40.0, x1: 290.0, y1: 190.0, r0: 1.0, g0: 0.30, b0: 0.42, a0: 1.0, r1: 0.30, g1: 0.52, b1: 1.0, a1: 1.0)
            // radial, soft edge
            |> libs/canvas:draw.gradient.radial(f, x: 350.0, y: 40.0, w: 200.0, h: 200.0, radius: 100.0, cx: 450.0, cy: 140.0, cr: 100.0, r0: 1.0, g0: 0.82, b0: 0.50, a0: 1.0, r1: 0.30, g1: 0.30, b1: 0.80, a1: 0.0)
            // linear with alpha endpoints, wide
            |> libs/canvas:draw.gradient(f, x: 40.0, y: 270.0, w: 520.0, h: 100.0, radius: 24.0, x0: 40.0, y0: 320.0, x1: 560.0, y1: 320.0, r0: 0.20, g0: 0.85, b0: 0.72, a0: 0.0, r1: 0.20, g1: 0.85, b1: 0.72, a1: 1.0)
            |> libs/canvas:draw.text(f, x: 52.0, y: 196.0, size: 12.0, r: 0.75, g: 0.78, b: 0.85, a: 0.9, text: "linear  red -> blue")
            |> libs/canvas:draw.text(f, x: 362.0, y: 252.0, size: 12.0, r: 0.75, g: 0.78, b: 0.85, a: 0.9, text: "radial  gold -> transparent")
            |> libs/canvas:draw.text(f, x: 52.0, y: 382.0, size: 12.0, r: 0.75, g: 0.78, b: 0.85, a: 0.9, text: "alpha ramp  transparent -> teal")
            |> if (world.frame == 20)
                | then |> libs/canvas:window.snap(path: "/tmp/gradient.bmp")
            |> if (world.frame == 28)
                | then |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("gradient: closed")
| err e |> std/io:print.ln("canvas init failed: {{ e:s }}")
