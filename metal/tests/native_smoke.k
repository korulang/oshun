// koru-native smoke: the same window/frames/draw contract basic.k drives
// on macOS, restricted to the verbs the native rasterizer implements.
// Opens a surface, clears to a flat color, runs ~240 frames painting a
// panel + text + a moving rect each frame, snaps pixel samples to the
// wire mid-run (the KSNAP oracle), quits on Escape or ! close.
//
//   koruc metal/tests/native_smoke.k --build=koru-native
//
// count 240 at ~8ms/frame ≈ 2s of pumping — long enough for the compositor
// to pick up damage, short enough for an unattended scenario step.

import libs/host
import libs/metal
import std/io

libs/metal:window.open(width: 320, height: 200, title: "koru native metal")
| win w |> libs/metal:window.clear.color(win: w, r: 0.06, g: 0.08, b: 0.14)
     |> libs/metal:frames(win: w, count: 240)
    ! frame f
        |> libs/metal:draw.panel(f, x: 16.0, y: 16.0, w: 288.0, h: 96.0, radius: 10.0,
                                 r: 0.16, g: 0.18, b: 0.26, a: 1.0,
                                 bw: 2.0, br: 0.35, bg: 0.45, bb: 0.75, ba: 1.0)
        |> libs/metal:draw.text(f, x: 32.0, y: 36.0, size: 16.0,
                                r: 0.9, g: 0.92, b: 0.95, a: 1.0, text: "KORU NATIVE")
        |> libs/metal:draw.clip.push(f, x: 16.0, y: 120.0, w: 288.0, h: 64.0)
        |> libs/metal:draw.rect(f, x: 24.0, y: 128.0, w: 120.0, h: 48.0,
                                r: 0.9, g: 0.4, b: 0.2, a: 1.0)
        |> libs/metal:draw.clip.pop(f)
        |> libs/metal:window.snap(path: "smoke")
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/metal:window.close(win: w2)
              |> std/io:print.ln("native metal: frames done, window closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
