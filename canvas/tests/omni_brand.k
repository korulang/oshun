// Omni brand plate — full-field champagne silk at plate res, snapped for
// omni/visual/background.png. Derived from the material, not authored.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 1600, height: 1000, scale: 1.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 |> libs/canvas:draw.roundrect(f, x: 0.0, y: 0.0, w: 1600.0, h: 1000.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/omni_brand.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("brand: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
