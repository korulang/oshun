import libs/canvas
import libs/components/rive_card
import std/io
import std/args

std/args:all(): av
|> libs/canvas:offscreen.open(width: 640, height: 400, scale: 1.0)
| surf s
    |> libs/canvas:offscreen.clear.color(s, r: 0.10, g: 0.10, b: 0.15)
    |> libs/canvas:offscreen.frame(s)
        ! frame f
            |> libs/components/rive_card:rive-card(path: "/Users/larsde/src/koru-rive/rive-cpp/tests/unit_tests/assets/component_list_follow_path.riv", ab: 18, fr: 8, x: 0.0, y: 0.0, w: 640.0, h: 640.0, f)
        | done _
    |> libs/canvas:offscreen.snap(s, path: "/tmp/rive_card.bmp")
    |> libs/canvas:offscreen.close(s)
    |> std/io:print.ln("rive_card: snapped + closed (argc {{ av.len:d }})")
| err e |> std/io:print.ln("offscreen init failed: {{ e:s }}")
