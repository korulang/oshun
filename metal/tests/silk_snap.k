// Champagne silk probe — draw.silk kind-4 instances on the offscreen
// surface, snapped to /tmp/omni_silk.bmp for pixel inspection.
// Rows sweep the material's three dials: fold angle (top), fold count
// (middle), pearl fringe (bottom). Champagne base ~0.91,0.85,0.72 off
// the omni navy clear.
//
//   koruc run metal/tests/silk_snap.k
//   sips -s format png /tmp/omni_silk.bmp --out /tmp/omni_silk.png
import libs/metal
import std/store
import std/io

std/store:new(world) { frame: 0[i64] }

libs/metal:offscreen.open(width: 840, height: 600, scale: 2.0)
| surf s |> libs/metal:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> for(0..3)
             ! each _ |> libs/metal:offscreen.frame(s)
                 ! frame f
                     |> std/store:stored { world.frame: world.frame + 1 }
                     // row 1 — angle sweep: 0, 40deg, 80deg
                     |> libs/metal:draw.silk(f, x: 40.0,  y: 40.0,  w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.0,   folds: 3.0, sheen: 1.0, pearl: 0.5)
                     |> libs/metal:draw.silk(f, x: 300.0, y: 40.0,  w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 3.0, sheen: 1.0, pearl: 0.5)
                     |> libs/metal:draw.silk(f, x: 560.0, y: 40.0,  w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 1.4,   folds: 3.0, sheen: 1.0, pearl: 0.5)
                     // row 2 — fold count: 1.5, 3, 6 waves across the short side
                     |> libs/metal:draw.silk(f, x: 40.0,  y: 220.0, w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 1.5, sheen: 1.0, pearl: 0.5)
                     |> libs/metal:draw.silk(f, x: 300.0, y: 220.0, w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 3.0, sheen: 1.0, pearl: 0.5)
                     |> libs/metal:draw.silk(f, x: 560.0, y: 220.0, w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 6.0, sheen: 1.0, pearl: 0.5)
                     // row 3 — pearl fringe: off, half, full (folds 0 = flat pearl panel first)
                     |> libs/metal:draw.silk(f, x: 40.0,  y: 400.0, w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 3.0, sheen: 1.0, pearl: 0.0)
                     |> libs/metal:draw.silk(f, x: 300.0, y: 400.0, w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 3.0, sheen: 1.0, pearl: 0.6)
                     |> libs/metal:draw.silk(f, x: 560.0, y: 400.0, w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7,   folds: 3.0, sheen: 1.0, pearl: 1.0)
                 | done _
         |> libs/metal:offscreen.snap(s, path: "/tmp/omni_silk.bmp")
         |> libs/metal:offscreen.close(s)
         |> std/io:print.ln("silk: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
