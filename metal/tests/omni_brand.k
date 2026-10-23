// Omni brand plate — full-field champagne silk at plate res, snapped for
// omni/visual/background.png. Derived from the material, not authored.
import libs/metal
import std/io

libs/metal:offscreen.open(width: 1600, height: 1000, scale: 1.0)
| surf s |> libs/metal:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/metal:offscreen.frame(s)
             ! frame f
                 |> libs/metal:draw.silk(f, x: 0.0, y: 0.0, w: 1600.0, h: 1000.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.35, folds: 3.0, sheen: 0.7, pearl: 0.45)
             | done _
         |> libs/metal:offscreen.snap(s, path: "/tmp/omni_brand.bmp")
         |> libs/metal:offscreen.close(s)
         |> std/io:print.ln("brand: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
