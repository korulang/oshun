// Split-flush baseline — two instFlush calls per frame with the second far
// larger than the first: 3 roundrects (~288 B), then draw.triangle forces a
// mid-frame flush, then 2000 rects (~192 KB) overflow the first flush's
// buffer. Exercises the instance-buffer growth path for the ring change.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 640, height: 400, scale: 2.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> for(0..5)
             ! each _ |> libs/canvas:offscreen.frame(s)
                 ! frame f
                     |> libs/canvas:draw.roundrect(f, x: 40.0, y: 40.0, w: 100.0, h: 60.0, radius: 10.0, r: 0.9, g: 0.4, b: 0.4, a: 1.0)
                     |> libs/canvas:draw.roundrect(f, x: 180.0, y: 40.0, w: 100.0, h: 60.0, radius: 10.0, r: 0.4, g: 0.8, b: 0.45, a: 1.0)
                     |> libs/canvas:draw.roundrect(f, x: 320.0, y: 40.0, w: 100.0, h: 60.0, radius: 10.0, r: 0.4, g: 0.45, b: 0.9, a: 1.0)
                     |> libs/canvas:draw.triangle(f)
                     |> for(0..2000)
                         ! each i |> libs/canvas:draw.rect(f, x: @as(f64, @floatFromInt(@mod(i, 50))) * 12.0, y: 20.0 + @as(f64, @floatFromInt(@divTrunc(i, 50))) * 9.0, w: 10.0, h: 7.0, r: 0.3, g: 0.6, b: 0.9, a: 1.0)
                 | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/omni_split.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("split: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
