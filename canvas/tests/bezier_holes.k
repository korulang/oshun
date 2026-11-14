// Hole probe for draw.bezier — replicates the geometry regime where the
// gallery's flow piece punched traveling gaps: gentle near-horizontal
// S-curves, control points oscillating around the chord (small A — the
// degenerate-cubic territory), widths 1.5–3.4 like flow.kz. Sixteen
// phases in one static frame; a hole shows as a background gap inside a
// stroke band. Snap /tmp/bezier_holes.bmp and scan the bands.
import libs/canvas
import libs/math
import std/io

libs/canvas:offscreen.open(width: 640, height: 640, scale: 1.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.94, g: 0.89, b: 0.78)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 // 16 gentle S-curves, light card bg, ink strokes —
                 // phase sweep stands in for flow's animated control pts
                 |> for(0..16)
                     ! each i
                         |> libs/math:sin(x: @as(f64, @floatFromInt(i)) * 0.55) : sn
                         |> libs/canvas:draw.bezier(f,
                             x0: 60.0, y0: 40.0 + @as(f64, @floatFromInt(i)) * 36.0,
                             x1: 320.0 - @as(f64, @floatFromInt(i % 3)) * 30.0, y1: 40.0 + @as(f64, @floatFromInt(i)) * 36.0 + 30.0 * sn,
                             x2: 580.0, y2: 40.0 + @as(f64, @floatFromInt(i)) * 36.0,
                             w: 1.5 + @as(f64, @floatFromInt(i % 4)) * 0.6, r: 0.16, g: 0.12, b: 0.08, a: 0.9)
                 // two tight hooks for contrast — high curvature, wide stroke
                 |> libs/canvas:draw.bezier(f, x0: 60.0, y0: 600.0, x1: 200.0, y1: 560.0, x2: 340.0, y2: 600.0, w: 4.0, r: 0.30, g: 0.20, b: 0.11, a: 0.95)
                 |> libs/canvas:draw.bezier(f, x0: 360.0, y0: 600.0, x1: 500.0, y1: 640.0, x2: 580.0, y2: 600.0, w: 4.0, r: 0.30, g: 0.20, b: 0.11, a: 0.95)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/bezier_holes.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("holes: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
