// Offscreen probe for the mesh verbs — mesh.open/tri/reset + draw.mesh.
// Two triangles forming a quad + one standalone tri; asymmetric coords
// so orientation/viewport bugs show. Snap BMP is the oracle.
import libs/canvas
import std/io

libs/canvas:offscreen.open(width: 320, height: 200, scale: 1.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
         |> libs/canvas:offscreen.frame(s)
             ! frame f
                 |> libs/canvas:mesh.open() : m
                     // quad as two tris: (40,40)(160,40)(160,120) + (40,40)(160,120)(40,120)
                     |> libs/canvas:mesh.tri(h: m, x1: 40.0, y1: 40.0, x2: 160.0, y2: 40.0, x3: 160.0, y3: 120.0)
                     |> libs/canvas:mesh.tri(h: m, x1: 40.0, y1: 40.0, x2: 160.0, y2: 120.0, x3: 40.0, y3: 120.0)
                     |> libs/canvas:draw.mesh(f, h: m, r: 0.9, g: 0.3, b: 0.2, a: 1.0)
                     |> libs/canvas:mesh.open() : m2
                         |> libs/canvas:mesh.tri(h: m2, x1: 200.0, y1: 140.0, x2: 280.0, y2: 140.0, x3: 240.0, y3: 190.0)
                         |> libs/canvas:draw.mesh(f, h: m2, r: 0.2, g: 0.6, b: 0.9, a: 0.7)
             | done _
         |> libs/canvas:offscreen.snap(s, path: "/tmp/mesh_probe.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("mesh_probe: snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
