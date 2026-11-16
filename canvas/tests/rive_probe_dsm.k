// Offscreen probe for kr/rive ops -> canvas replay (continuation-yield).
import libs/canvas
import kr/rive
import probe
import std/io
import std/args

std/args:all(): av
|> libs/canvas:offscreen.open(width: 640, height: 400, scale: 1.0)
| surf s
    |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
    |> libs/canvas:offscreen.frame(s)
        ! frame f
            |> kr/rive:open(path: av[1])
            | loaded r
                |> kr/rive:ops(r, ab: 9, frame: 0)
                    ! op o |> probe:step(o, f)
                    | done n |> std/io:print.ln("ops {{ n:d }}") |> kr/rive:free(r)
            | failed e
                |> std/io:print.ln("open failed")
        | done _
    |> libs/canvas:offscreen.snap(s, path: "/tmp/rive_dsm.bmp")
    |> libs/canvas:offscreen.close(s)
    |> std/io:print.ln("rive_probe: snapped + closed")
| err e |> std/io:print.ln("offscreen init failed: {{ e:s }}")
