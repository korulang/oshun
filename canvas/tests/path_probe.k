// Offscreen probe for the vector-path verbs — path.open/move/line/quad/
// cubic/close, transform.push/pop, draw.path fill+stroke. Asymmetric
// shapes on purpose: orientation bugs show as mirrored geometry, and the
// snap BMP is the oracle — inspect /tmp/path_probe.bmp before believing.
// Path building rides the same frame arm (offscreen.frame is one-shot);
// per-frame path building is the consumer's job in real use.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 640, height: 400, scale: 2.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 // filled triangle — move/line/line/close, fill only
                 |> libs/canvas:path.open() : tri
                     |> libs/canvas:path.move(p: tri, x: 80.0, y: 40.0)
                     |> libs/canvas:path.line(p: tri, x: 40.0, y: 140.0)
                     |> libs/canvas:path.line(p: tri, x: 120.0, y: 140.0)
                     |> libs/canvas:path.close(p: tri)
                     // blob — quad bulges, dual paint, round joins
                     |> libs/canvas:path.open() : blob
                         |> libs/canvas:path.move(p: blob, x: 200.0, y: 60.0)
                         |> libs/canvas:path.quad(p: blob, cx: 280.0, cy: 20.0, x: 360.0, y: 60.0)
                         |> libs/canvas:path.quad(p: blob, cx: 400.0, cy: 140.0, x: 360.0, y: 200.0)
                         |> libs/canvas:path.line(p: blob, x: 240.0, y: 200.0)
                         |> libs/canvas:path.close(p: blob)
                         // wave — two cubics, stroke only
                         |> libs/canvas:path.open() : wave
                             |> libs/canvas:path.move(p: wave, x: 60.0, y: 260.0)
                             |> libs/canvas:path.cubic(p: wave, c1x: 160.0, c1y: 200.0, c2x: 260.0, c2y: 320.0, x: 360.0, y: 260.0)
                             |> libs/canvas:path.cubic(p: wave, c1x: 460.0, c1y: 200.0, c2x: 560.0, c2y: 320.0, x: 620.0, y: 260.0)
                             // bowtie — evenodd vs nonzero diverge
                             |> libs/canvas:path.open() : bow
                                 |> libs/canvas:path.move(p: bow, x: 420.0, y: 240.0)
                                 |> libs/canvas:path.line(p: bow, x: 500.0, y: 340.0)
                                 |> libs/canvas:path.line(p: bow, x: 580.0, y: 240.0)
                                 |> libs/canvas:path.line(p: bow, x: 500.0, y: 300.0)
                                 |> libs/canvas:path.close(p: bow)
                                 // unit triangle for the transform test
                                 |> libs/canvas:path.open() : ttri
                                     |> libs/canvas:path.move(p: ttri, x: 0.0, y: 0.0)
                                     |> libs/canvas:path.line(p: ttri, x: 40.0, y: 0.0)
                                     |> libs/canvas:path.line(p: ttri, x: 20.0, y: 60.0)
                                     |> libs/canvas:path.close(p: ttri)
                                     // ---- draws ----
                                     |> libs/canvas:draw.path(f, p: tri, fr: 0.95, fg: 0.75, fb: 0.3, fa: 1.0, sr: 0, sg: 0, sb: 0, sa: 0, sw: 0, join: 1, cap: 1, evenodd: 0)
                                     |> libs/canvas:draw.path(f, p: blob, fr: 0.2, fg: 0.7, fb: 0.6, fa: 0.9, sr: 0.1, sg: 0.15, sb: 0.2, sa: 1.0, sw: 4.0, join: 1, cap: 1, evenodd: 0)
                                     |> libs/canvas:draw.path(f, p: wave, fr: 0, fg: 0, fb: 0, fa: 0, sr: 0.9, sg: 0.4, sb: 0, sa: 1.0, sw: 3.0, join: 0, cap: 2, evenodd: 0)
                                     |> libs/canvas:draw.path(f, p: bow, fr: 0.8, fg: 0.3, fb: 0.6, fa: 1.0, sr: 0, sg: 0, sb: 0, sa: 0, sw: 0, join: 1, cap: 1, evenodd: 0)
                                     // transformed triangle: translate(150,280) scale(1.5)
                                     |> libs/canvas:transform.push(f, a: 1.5, b: 0, c: 0, d: 1.5, e: 150.0, g: 280.0)
                                     |> libs/canvas:draw.path(f, p: ttri, fr: 0.4, fg: 0.6, fb: 0.95, fa: 1.0, sr: 0, sg: 0, sb: 0, sa: 0, sw: 0, join: 1, cap: 1, evenodd: 0)
                                     |> libs/canvas:transform.pop(f)
                                     // nested pushes compose: net translate(60,-60)
                                     |> libs/canvas:transform.push(f, a: 1, b: 0, c: 0, d: 1, e: 0.0, g: -60.0)
                                     |> libs/canvas:transform.push(f, a: 1, b: 0, c: 0, d: 1, e: 60.0, g: 0.0)
                                     |> libs/canvas:draw.path(f, p: bow, fr: 0.95, fg: 0.9, fb: 0.4, fa: 1.0, sr: 0, sg: 0, sb: 0, sa: 0, sw: 0, join: 1, cap: 1, evenodd: 1)
                                     |> libs/canvas:transform.pop(f)
                                     |> libs/canvas:transform.pop(f)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/path_probe.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("path_probe: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
