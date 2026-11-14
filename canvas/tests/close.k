// metal lifecycle smoke: open a window, run five frames, walk the | done
// path through window.close. Exercises the close+release sequence that
// segfaulted when a closed NSWindow was messaged after release.
import libs/host
import libs/canvas
import std/io

libs/canvas:window.open(width: 640, height: 480, title: "close test")
| win w |> libs/canvas:frames(win: w, count: 5)
    ! frame f |> libs/canvas:draw.rect(f, x: 10.0, y: 10.0, w: 20.0, h: 20.0, r: 0.5, g: 0.5, b: 0.5, a: 1.0)
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
