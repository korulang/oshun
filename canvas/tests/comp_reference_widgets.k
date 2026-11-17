// comp_reference_widgets — the faithful port probe. Both widgets draw at
// their reference 1x dimensions on a #2b2b2b mat, so the capture crop can be
// scored directly against the references.
//
//   koruc run canvas/tests/comp_reference_widgets.k
//   sips -s format png /tmp/ref_widgets.bmp --out /tmp/ref_widgets.png

import libs/host
import libs/canvas
import libs/components/reference_widgets
import std/store
import std/io

std/store:new(world) { frame: 0[i64], face: -1[i64] }

libs/canvas:window.open(width: 900, height: 250, title: "omni / reference widgets")
| win w |> libs/canvas:window.clear.color(win: w, r: 0.169, g: 0.169, b: 0.169)
    |> libs/canvas:font.load(win: w, path: "/Users/larsde/src/oshun/canvas/tests/assets/SF-Pro.ttf")
        | font fc |> std/store:stored { world.face: fc }
        | err fe |> std/io:print.ln(fe)
    |> libs/canvas:frames(win: w, count: 9999)
        ! frame f
            |> std/store:stored { world.frame: world.frame + 1 }
            |> libs/components/reference_widgets:reference-bp(win: w, f, world.face, x: 0.0, y: 0.0, s: 1.0)
            |> libs/components/reference_widgets:reference-flight(win: w, f, world.face, x: 450.0, y: 0.0, s: 1.0)
            |> if (world.frame == 20)
                | then |> libs/canvas:window.snap(path: "/tmp/ref_widgets.bmp")
            |> if (world.frame == 28)
                | then |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("reference widgets: closed")
| err e |> std/io:print.ln("canvas init failed: {{ e:s }}")
