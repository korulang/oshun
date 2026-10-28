// Overlay spike — the summon idiom: window.overlay opens HIDDEN,
// window.show orders it in centered on the main screen, frames paints it,
// snap captures the pill at frame 30, host:quit ends it at 40.
// Render probe only — the bars are fixed geometry proving draw.* works on
// the borderless kind, not a stand-in for live audio.
//
//   koruc run metal/tests/overlay.k
//   sips -s format png /tmp/overlay_snap.bmp --out /tmp/overlay_snap.png

import libs/host
import libs/metal
import std/store
import std/io

std/store:new(world) { frame: 0[i64] }

libs/metal:window.overlay(width: 360, height: 72, radius: 20.0)
| win w |> libs/metal:window.show(win: w) |> libs/metal:window.clear.color(win: w, r: 0.07, g: 0.06, b: 0.11)
        |> libs/metal:frames(win: w, count: 9999)
    ! frame f
        |> std/store:stored { world.frame: world.frame + 1 }
        |> libs/metal:draw.rect(f, x: 60.0, y: 26.0, w: 4.0, h: 20.0, r: 0.4, g: 0.9, b: 0.5, a: 1.0)
        |> libs/metal:draw.rect(f, x: 80.0, y: 18.0, w: 4.0, h: 36.0, r: 0.4, g: 0.9, b: 0.5, a: 1.0)
        |> libs/metal:draw.rect(f, x: 100.0, y: 30.0, w: 4.0, h: 12.0, r: 0.4, g: 0.9, b: 0.5, a: 1.0)
        |> libs/metal:draw.rect(f, x: 120.0, y: 14.0, w: 4.0, h: 44.0, r: 0.4, g: 0.9, b: 0.5, a: 1.0)
        |> libs/metal:draw.rect(f, x: 140.0, y: 22.0, w: 4.0, h: 28.0, r: 0.4, g: 0.9, b: 0.5, a: 1.0)
        |> if (world.frame == 30)
            | then |> libs/metal:window.snap(path: "/tmp/overlay_snap.bmp")
        |> if (world.frame == 40)
            | then |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("overlay: shown, framed, closed")
| err e |> std/io:print.ln("overlay init failed: {{ e:s }}")
