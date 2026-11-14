// Dedup probe — three image.load calls on one path should return the
// same handle (shared decode), frees should drop the refcount without
// killing the texture until the last one.
import libs/canvas
import std/io

libs/canvas:window.open(width: 400, height: 300, title: "dedup")
| win w |> libs/canvas:image.load(win: w, path: "/tmp/oshun_logo.png")
    | img a |> libs/canvas:image.load(win: w, path: "/tmp/oshun_logo.png")
        | img b |> libs/canvas:image.load(win: w, path: "/tmp/oshun_logo.png")
            | img c |> std/io:print.ln("handles: {{ a:d }} {{ b:d }} {{ c:d }}")
                |> libs/canvas:image.free(tex: a) : r1
                    |> libs/canvas:image.free(tex: b) : r2
                        |> std/io:print.ln("refs after frees: {{ r1:d }} {{ r2:d }}")
                        |> libs/canvas:frames(win: w, count: 1)
                            ! frame _ |> _
                            | done w2 |> libs/canvas:window.close(win: w2)
            | err e |> std/io:print.ln("load3: {{ e:s }}")
                |> libs/canvas:frames(win: w, count: 1)
                    ! frame _ |> _
                    | done w2 |> libs/canvas:window.close(win: w2)
        | err e |> std/io:print.ln("load2: {{ e:s }}")
            |> libs/canvas:frames(win: w, count: 1)
                ! frame _ |> _
                | done w2 |> libs/canvas:window.close(win: w2)
    | err e |> std/io:print.ln("load1: {{ e:s }}")
        |> libs/canvas:frames(win: w, count: 1)
            ! frame _ |> _
            | done w2 |> libs/canvas:window.close(win: w2)
| err e |> std/io:print.ln("init failed: {{ e:s }}")
