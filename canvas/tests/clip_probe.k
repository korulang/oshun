// Offscreen probe for clip.push.path — circle-ish clip over a big rect,
// nested path∩path clip, and clip.pop restore. Snap BMP is the oracle.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 400, height: 300, scale: 2.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 // diamond clip path centered (200,150) r=90
                 |> libs/canvas:path.open() : clip
                     |> libs/canvas:path.move(p: clip, x: 200.0, y: 60.0)
                     |> libs/canvas:path.line(p: clip, x: 290.0, y: 150.0)
                     |> libs/canvas:path.line(p: clip, x: 200.0, y: 240.0)
                     |> libs/canvas:path.line(p: clip, x: 110.0, y: 150.0)
                     |> libs/canvas:path.close(p: clip)
                     // small circle-ish octagon clip for nesting
                     |> libs/canvas:path.open() : inner
                         |> libs/canvas:path.move(p: inner, x: 200.0, y: 100.0)
                         |> libs/canvas:path.line(p: inner, x: 250.0, y: 150.0)
                         |> libs/canvas:path.line(p: inner, x: 200.0, y: 200.0)
                         |> libs/canvas:path.line(p: inner, x: 150.0, y: 150.0)
                         |> libs/canvas:path.close(p: inner)
                         // diamond clip → draw rect that should be cut to diamond
                         |> libs/canvas:draw.clip.push.path(f, p: clip, evenodd: 0)
                         |> libs/canvas:draw.rect(f, x: 50.0, y: 50.0, w: 300.0, h: 200.0, r: 0.9, g: 0.5, b: 0.2, a: 1.0)
                         // nested: inner square clip → only overlap survives
                         |> libs/canvas:draw.clip.push.path(f, p: inner, evenodd: 0)
                         |> libs/canvas:draw.rect(f, x: 120.0, y: 80.0, w: 160.0, h: 140.0, r: 0.2, g: 0.8, b: 0.4, a: 1.0)
                         |> libs/canvas:draw.clip.pop(f)
                         // still diamond-clipped: blue rect right half
                         |> libs/canvas:draw.rect(f, x: 200.0, y: 60.0, w: 100.0, h: 180.0, r: 0.3, g: 0.4, b: 0.95, a: 1.0)
                         |> libs/canvas:draw.clip.pop(f)
                         // unclipped again: white corner marker
                         |> libs/canvas:draw.rect(f, x: 10.0, y: 10.0, w: 30.0, h: 30.0, r: 1, g: 1, b: 1, a: 1.0)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/clip_probe.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("clip_probe: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
