// comp_lantern_widgets — the control-family probe. Three lantern tiles on
// the gallery's paper: vitals (dot matrix), flight (progress runway), dial
// (tick gauge). The scripted twin snaps one frame and quits.
//
//   koruc run canvas/tests/comp_lantern_widgets.k
//   sips -s format png /tmp/omni_widgets.bmp --out /tmp/omni_widgets.png

import libs/host
import libs/canvas
import libs/components/lantern_tile
import std/store
import std/io

std/store:new(world) { frame: 0[i64] }

libs/canvas:window.open(width: 1200, height: 760, title: "omni / control surfaces")
| win w |> libs/canvas:window.clear.color(win: w, r: 0.91, g: 0.85, b: 0.72)
    |> libs/canvas:frames(win: w, count: 9999)
        ! frame f
            |> std/store:stored { world.frame: world.frame + 1 }
            |> libs/canvas:draw.text(f, x: 48.0, y: 38.0, size: 22.0, r: 0.16, g: 0.12, b: 0.08, a: 1.0, text: "omni / control surfaces")
            |> libs/canvas:draw.text(f, x: 48.0, y: 68.0, size: 10.0, r: 0.30, g: 0.26, b: 0.20, a: 0.85, text: "lantern tiles - vitals . flight . dial")
            |> libs/components/lantern_tile:lantern-vitals(win: w, f, face: 0, x: 45.0, y: 140.0, w: 340.0, h: 480.0, label: "vitals", chip: "resting", hero: "82", unit: "mmhg", caption: "5 min interval . systolic")
            |> libs/components/lantern_tile:lantern-flight(win: w, f, face: 0, x: 430.0, y: 140.0, w: 340.0, h: 480.0, label: "arrival", chip: "on time", hero: "12:59", unit: "AM", caption: "20 min out . gate B12", value: 0.72)
            |> libs/components/lantern_tile:lantern-dial(win: w, f, face: 0, x: 815.0, y: 140.0, w: 340.0, h: 480.0, label: "output", chip: "active", hero: "62", unit: "percent", caption: "rotary control . drag to turn", value: 0.62)
            |> if (world.frame == 24)
                | then |> libs/canvas:window.snap(path: "/tmp/omni_widgets.bmp")
            |> if (world.frame == 32)
                | then |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("widgets: closed")
| err e |> std/io:print.ln("canvas init failed: {{ e:s }}")
