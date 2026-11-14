// comp_button — the `button` component alone on the champagne wall.
// Four variants in a row: primary (ink silk, champagne label), secondary
// (pearl panel + hairline + floor shadow), ghost (label until hot), and a
// disabled secondary. The component measures its own label and hit-tests
// its own rect — the demo only forwards raw pointer scalars (mx, my, down)
// from the mouse arms; press/hover/disabled all live inside the tor.
//
// Scripted pass for the deterministic run: hover the primary, hold it
// (snap — dipped and darkened), release, hover the secondary (snap — gold
// hairline + deeper shadow), hover the ghost (snap — pearl wash), then
// rest the pointer on the disabled one (snap — stays dim, swallows the
// hover), and quit.
//
//   koruc run canvas/tests/comp_button.k
//   sips -s format png /tmp/comp_button_press.bmp --out /tmp/comp_button_press.png

import libs/host
import libs/canvas
import libs/components
import std/store
import std/io

std/store:new(world) { frame: 0[i64], down: 0[i64] }
std/store:new(fworld) { mx: -1.0[f64], my: -1.0[f64] }

libs/canvas:window.open(width: 800, height: 400, title: "component — button")
| win w |> libs/canvas:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
    |> libs/canvas:frames(win: w, count: 9999)
        ! frame f
            |> std/store:stored { world.frame: world.frame + 1 }
            // the room — champagne silk, same drape as the commander's
            |> libs/canvas:draw.roundrect(f, x: 0.0, y: 0.0, w: 800.0, h: 400.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
            // the component row — each tor owns its own box and states
            |> libs/components:button(win: w, f, text: "engage",  size: 15.0, face: 0, x: 90.0,  y: 182.0, variant: 1, fworld.mx, fworld.my, world.down, disabled: 0)
            |> libs/components:button(win: w, f, text: "hold",    size: 15.0, face: 0, x: 280.0, y: 182.0, variant: 0, fworld.mx, fworld.my, world.down, disabled: 0)
            |> libs/components:button(win: w, f, text: "dismiss", size: 15.0, face: 0, x: 470.0, y: 182.0, variant: 2, fworld.mx, fworld.my, world.down, disabled: 0)
            |> libs/components:button(win: w, f, text: "locked",  size: 15.0, face: 0, x: 660.0, y: 182.0, variant: 0, fworld.mx, fworld.my, world.down, disabled: 1)
            // the scripted pointer — events land on the NEXT frame's drain
            |> if (world.frame == 15)
                | then |> libs/canvas:input.move(x: 115.0, y: 200.0)
            |> if (world.frame == 25)
                | then |> libs/canvas:input.mouse(x: 115.0, y: 200.0)
            |> if (world.frame == 32)
                | then |> libs/canvas:window.snap(path: "/tmp/comp_button_press.bmp")
            |> if (world.frame == 36)
                | then |> libs/canvas:input.up(x: 115.0, y: 200.0)
            |> if (world.frame == 45)
                | then |> libs/canvas:input.move(x: 305.0, y: 200.0)
            |> if (world.frame == 52)
                | then |> libs/canvas:window.snap(path: "/tmp/comp_button_hover.bmp")
            |> if (world.frame == 60)
                | then |> libs/canvas:input.move(x: 495.0, y: 200.0)
            |> if (world.frame == 66)
                | then |> libs/canvas:window.snap(path: "/tmp/comp_button_ghost.bmp")
            |> if (world.frame == 72)
                | then |> libs/canvas:input.move(x: 685.0, y: 200.0)
            |> if (world.frame == 78)
                | then |> libs/canvas:window.snap(path: "/tmp/comp_button_rest.bmp")
            |> if (world.frame == 84)
                | then |> libs/host:quit()
        ! mouse-move m
            |> std/store:stored { fworld.mx: m.x, fworld.my: m.y }
        ! mouse-drag m
            |> std/store:stored { fworld.mx: m.x, fworld.my: m.y }
        ! mouse-down m
            |> std/store:stored { fworld.mx: m.x, fworld.my: m.y }
            |> std/store:stored { world.down: 1 }
        ! mouse-up m
            |> std/store:stored { fworld.mx: m.x, fworld.my: m.y }
            |> std/store:stored { world.down: 0 }
        ! key-down k when k.code == 53 |> libs/host:quit()
        ! close |> libs/host:quit()
        | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("comp_button: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
