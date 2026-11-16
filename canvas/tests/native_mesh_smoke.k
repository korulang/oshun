// koru-native mesh smoke: uniform mesh.* surface compile+run check on
// the freestanding rasterizer. Same contract as canvas/tests/mesh_probe.k
// but on the window/frames path — the native arm has no offscreen.
//
//   koruc canvas/tests/native_mesh_smoke.k --build=koru-native

import libs/host
import libs/canvas
import std/io

libs/canvas:window.open(width: 320, height: 200, title: "koru native mesh")
| win w |> libs/canvas:window.clear.color(win: w, r: 0.06, g: 0.08, b: 0.14)
     |> libs/canvas:frames(win: w, count: 60)
    ! frame f
        |> libs/canvas:mesh.open() : m
        |> libs/canvas:mesh.tri(h: m, x1: 40.0, y1: 40.0, x2: 160.0, y2: 40.0, x3: 160.0, y3: 120.0)
        |> libs/canvas:mesh.tri(h: m, x1: 40.0, y1: 40.0, x2: 160.0, y2: 120.0, x3: 40.0, y3: 120.0)
        |> libs/canvas:draw.mesh(f, h: m, r: 0.9, g: 0.3, b: 0.2, a: 1.0)
        |> libs/canvas:mesh.reset(h: m)
        |> libs/canvas:window.snap(path: "native_mesh")
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/canvas:window.close(win: w2)
              |> std/io:print.ln("native mesh: frames done, window closed")
| err e |> std/io:print.ln("native init failed: {{ e:s }}")
