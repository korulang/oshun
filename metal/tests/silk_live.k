// Animated silk — the windowed sibling of silk_snap. The draw verbs are
// identical every frame; only the frame clock moves. Snaps at frame 30
// and frame 150 must differ pixel-for-pixel — that diff IS the proof the
// ftime uniform reaches the fragment. Quits itself.
//
//   koruc run metal/tests/silk_live.k
//   sips -s format png /tmp/omni_silk_t30.bmp --out /tmp/omni_silk_t30.png
import libs/host
import libs/metal
import std/store
import std/io

std/store:new(world) { frame: 0[i64] }

libs/metal:window.open(width: 640, height: 430, title: "omni silk — animated")
| win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
        |> libs/metal:frames(win: w, count: 9999)
    ! frame f
        |> std/store:stored { world.frame: world.frame + 1 }
        |> libs/metal:draw.silk(f, x: 60.0,  y: 50.0,  w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7, folds: 3.0, sheen: 1.0, pearl: 0.6)
        |> libs/metal:draw.silk(f, x: 340.0, y: 50.0,  w: 240.0, h: 150.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.7, folds: 3.0, sheen: 1.0, pearl: 0.6)
        |> libs/metal:draw.silk(f, x: 60.0,  y: 230.0, w: 520.0, h: 160.0, radius: 14.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.3, folds: 2.0, sheen: 1.0, pearl: 0.6)
        |> if (world.frame == 30)
            | then |> libs/metal:window.snap(path: "/tmp/omni_silk_t30.bmp")
        |> if (world.frame == 150)
            | then |> libs/metal:window.snap(path: "/tmp/omni_silk_t150.bmp")
        |> if (world.frame == 160)
            | then |> libs/host:quit()
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("silk live: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
