// Liquid glass — kind-5 panes refracting the image-atlas backdrop.
// clay/tests/test.png (a blue/orange check board) draws fullscreen;
// each pane's uv field maps its own rect into that draw, so the bezel
// lens bends the real pixels beneath. Grid sweeps the material's
// dials: refraction depth (top row), bezel width (middle), tint and
// chromatic aberration (bottom). Snaps frame 30; esc/close quits.
//
//   koruc run mat_glass.k                    (from canvas/tests)
//   sips -s format png /tmp/omni_glass.bmp --out /tmp/omni_glass.png
import libs/host
import libs/canvas
import std/store
import std/io

std/store:new(world) { frame: 0[i64], img: 0[i64] }

libs/canvas:window.open(width: 920, height: 660, title: "omni glass — liquid glass panes")
| win w |> libs/canvas:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
        |> libs/canvas:image.load(win: w, path: "../../clay/tests/test.png")
            | img im |> std/store:stored { world.img: im }
            | err e |> std/io:print.ln("image failed: {{ e:s }}")
        |> libs/canvas:frames(win: w, count: 9999)
            ! frame f
                |> std/store:stored { world.frame: world.frame + 1 }
                // the backdrop — one image draw the panes all refract
                |> if (world.img > 0)
                    | then |> libs/canvas:draw.image(f, tex: world.img, x: 0.0, y: 0.0, w: 920.0, h: 660.0)
                // row 1 — refraction depth: 0 (flat pane), 12, 26 points
                |> libs/canvas:draw.glass(f, x: 40.0,  y: 40.0,  w: 260.0, h: 170.0, radius: 4.0,  tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 0.0,  rim: 9.0, aberr: 0.3, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.05)
                |> libs/canvas:draw.glass(f, x: 330.0, y: 40.0,  w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 12.0, rim: 9.0, aberr: 0.3, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.05)
                |> libs/canvas:draw.glass(f, x: 620.0, y: 40.0,  w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 26.0, rim: 9.0, aberr: 0.3, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.05)
                // row 2 — bezel width: thin ring, standard, half the pane
                |> libs/canvas:draw.glass(f, x: 40.0,  y: 240.0, w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 6.0,  refract: 20.0, rim: 9.0, aberr: 0.3, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.05)
                |> libs/canvas:draw.glass(f, x: 330.0, y: 240.0, w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 20.0, rim: 9.0, aberr: 0.3, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.05)
                |> libs/canvas:draw.glass(f, x: 620.0, y: 240.0, w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 70.0, refract: 20.0, rim: 9.0, aberr: 0.3, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.05)
                // row 3 — tint + aberration: clear edge, cool glass, amber
                |> libs/canvas:draw.glass(f, x: 40.0,  y: 440.0, w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 18.0, rim: 9.0, aberr: 0.0, r: 1.0,  g: 1.0,  b: 1.0,  a: 0.0)
                |> libs/canvas:draw.glass(f, x: 330.0, y: 440.0, w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 18.0, rim: 9.0, aberr: 0.4, r: 0.75, g: 0.88, b: 1.0,  a: 0.16)
                |> libs/canvas:draw.glass(f, x: 620.0, y: 440.0, w: 260.0, h: 170.0, radius: 22.0, tex: world.img, bx: 0.0, by: 0.0, bw: 920.0, bh: 660.0, bezel: 28.0, refract: 18.0, rim: 9.0, aberr: 0.7, r: 1.0,  g: 0.82, b: 0.55, a: 0.20)
                |> if (world.frame == 30)
                    | then |> libs/canvas:window.snap(path: "/tmp/omni_glass.bmp")
            ! key-down k when k.code == 53 |> libs/host:quit()
            ! close |> libs/host:quit()
            | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("glass: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
