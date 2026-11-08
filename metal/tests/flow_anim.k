// Flow animation probe — the REAL windowed path at Retina scale. Draws
// components/flow with t=frame/60 for 72 frames and snaps the last one
// to /tmp/flow_anim.bmp — a windowed-path reference next to the
// offscreen sweeps. Quits itself.
import libs/host
import libs/metal
import libs/components/flow
import std/store
import std/io

std/store:new(g) { frame: 0[i64] }

libs/metal:window.open(width: 800, height: 560, title: "flow anim probe")
| win w |> libs/metal:window.clear.color(win: w, r: 0.94, g: 0.89, b: 0.78) |> libs/metal:frames(win: w, count: 72)
    ! frame f
        |> std/store:stored { g.frame: g.frame + 1 }
        |> libs/components/flow:flow(f, cx: 400.0, cy: 280.0, w: 620.0, h: 420.0, t: @as(f64, @floatFromInt(g.frame)) / 60.0, a: 1.0)
        |> if (g.frame == 72)
            | then |> libs/metal:window.snap(path: "/tmp/flow_anim.bmp")
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("flow anim: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
