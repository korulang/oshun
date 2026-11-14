// Offscreen probe for draw.bezier — the stroked quadratic Bézier kind.
// Six curves covering the cases the SDF has to survive: a broad arc, an
// S-bend, a degenerate straight line (P1 on the segment midpoint), a
// sharp hook, a P0==P2 loop, and a hairline. Snap is the oracle —
// inspect /tmp/bezier.bmp before believing any of it.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 640, height: 400, scale: 2.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 // broad arc — control well above the chord
                 |> libs/canvas:draw.bezier(f, x0: 60.0, y0: 320.0, x1: 320.0, y1: 40.0, x2: 580.0, y2: 320.0, w: 6.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
                 // S-bend — control below, thinner, ink
                 |> libs/canvas:draw.bezier(f, x0: 60.0, y0: 120.0, x1: 200.0, y1: 260.0, x2: 340.0, y2: 120.0, w: 2.5, r: 0.16, g: 0.12, b: 0.08, a: 0.9)
                 |> libs/canvas:draw.bezier(f, x0: 340.0, y0: 120.0, x1: 480.0, y1: 260.0, x2: 580.0, y2: 120.0, w: 2.5, r: 0.16, g: 0.12, b: 0.08, a: 0.9)
                 // degenerate — P1 exactly on the chord midpoint: must
                 // render as a straight segment, not vanish
                 |> libs/canvas:draw.bezier(f, x0: 80.0, y0: 200.0, x1: 320.0, y1: 200.0, x2: 560.0, y2: 200.0, w: 3.0, r: 0.4, g: 0.8, b: 0.45, a: 1.0)
                 // sharp hook — control far off-axis
                 |> libs/canvas:draw.bezier(f, x0: 480.0, y0: 340.0, x1: 560.0, y1: 60.0, x2: 120.0, y2: 340.0, w: 4.0, r: 0.8, g: 0.3, b: 0.7, a: 0.95)
                 // loop — P0 == P2, control pulled away
                 |> libs/canvas:draw.bezier(f, x0: 160.0, y0: 90.0, x1: 320.0, y1: 10.0, x2: 160.0, y2: 90.0, w: 3.0, r: 0.95, g: 0.6, b: 0.3, a: 0.9)
                 // hairline — sub-pixel-ish width, AA check
                 |> libs/canvas:draw.bezier(f, x0: 40.0, y0: 360.0, x1: 320.0, y1: 300.0, x2: 600.0, y2: 360.0, w: 0.75, r: 1.0, g: 1.0, b: 1.0, a: 0.8)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/bezier.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("bezier: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
