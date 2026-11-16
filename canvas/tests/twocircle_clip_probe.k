// Offscreen probe for clip.push.path — circle-ish clip over a big rect,
// nested path∩path clip, and clip.pop restore. Snap BMP is the oracle.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 400, height: 300, scale: 2.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 // TWO disjoint cubic circles in ONE path — mimics
                 // clip_tests' two ellipse children joined as one contour
                 |> libs/canvas:path.open() : clip
                     // circle A centered (100,150) r=60
                     |> libs/canvas:path.move(p: clip, x: 100.0, y: 90.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 133.0, c1y: 90.0, c2x: 160.0, c2y: 117.0, x: 160.0, y: 150.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 160.0, c1y: 183.0, c2x: 133.0, c2y: 210.0, x: 100.0, y: 210.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 67.0, c1y: 210.0, c2x: 40.0, c2y: 183.0, x: 40.0, y: 150.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 40.0, c1y: 117.0, c2x: 67.0, c2y: 90.0, x: 100.0, y: 90.0)
                     // circle B centered (300,150) r=60 — second contour
                     |> libs/canvas:path.move(p: clip, x: 300.0, y: 90.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 333.0, c1y: 90.0, c2x: 360.0, c2y: 117.0, x: 360.0, y: 150.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 360.0, c1y: 183.0, c2x: 333.0, c2y: 210.0, x: 300.0, y: 210.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 267.0, c1y: 210.0, c2x: 240.0, c2y: 183.0, x: 240.0, y: 150.0)
                     |> libs/canvas:path.cubic(p: clip, c1x: 240.0, c1y: 117.0, c2x: 267.0, c2y: 90.0, x: 300.0, y: 90.0)
                     |> libs/canvas:path.close(p: clip)
                     |> libs/canvas:draw.clip.push.path(f, p: clip, evenodd: 0)
                     // big rect covering both circles — ink only inside them
                     |> libs/canvas:draw.rect(f, x: 20.0, y: 60.0, w: 360.0, h: 180.0, r: 0.9, g: 0.5, b: 0.2, a: 1.0)
                     |> libs/canvas:draw.clip.pop(f)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/twocircle_clip.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("twocircle_clip: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
