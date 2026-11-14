// Flow sweep — the real components/flow tor at 25 animation phases,
// one offscreen frame + snap per phase (snap sits inside the `! each`
// arm so `i` is in scope for the path). The gallery's live flicker was
// only ever seen moving; this freezes every phase for scanning.
// Snaps land at /tmp/flow_sweep_N.bmp.
import libs/canvas
import libs/components/flow
import std/io

libs/canvas:offscreen.open(width: 800, height: 560, scale: 1.0)
| surf s |> libs/canvas:offscreen.clear.color(s, r: 0.94, g: 0.89, b: 0.78)
         |> for(0..25)
             ! each i
                 |> libs/canvas:offscreen.frame(s)
                     ! frame f
                         |> libs/components/flow:flow(f, cx: 400.0, cy: 280.0, w: 620.0, h: 420.0, t: @as(f64, @floatFromInt(i)) * 0.12, a: 1.0)
                     | done _
                 |> libs/canvas:offscreen.snap(s, path: "/tmp/flow_sweep_{{ i:d }}.bmp")
         |> libs/canvas:offscreen.close(s)
         |> std/io:print.ln("sweep: 25 phases snapped + closed")
| err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
