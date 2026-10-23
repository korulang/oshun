// Frosted glass — kind-6 panes scattering the CAPTURED live scene.
// The frame first draws a real scene (silk tiles, text, color panels,
// stripes), then draw.capture splits the render pass and blit-copies
// the target into the scene texture: each pane frosts the actual
// framebuffer beneath it — the wall kind-5's image-atlas backdrop hit.
// Grid sweeps the material's dials: scatter radius (top row), milk
// density (middle), rim chamfer + grain + tint (bottom). Snaps frame
// 30; esc/close quits.
//
//   koruc run mat_frost.k                    (from metal/tests)
//   sips -s format png /tmp/omni_frost.bmp --out /tmp/omni_frost.png
import libs/host
import libs/metal
import std/store
import std/io

std/store:new(world) { frame: 0[i64] }

libs/metal:window.open(width: 920, height: 660, title: "omni frost — ground glass over the live scene")
| win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
        |> libs/metal:frames(win: w, count: 9999)
            ! frame f
                |> std/store:stored { world.frame: world.frame + 1 }
                // ===== the scene — everything the panes will frost =====
                // silk tiles behind row 1 — living drape, visibly smeared
                |> libs/metal:draw.silk(f, x: 20.0,  y: 30.0, w: 210.0, h: 175.0, radius: 10.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0, angle: 0.5,  folds: 7.0, sheen: 0.9, pearl: 0.6)
                |> libs/metal:draw.silk(f, x: 240.0, y: 30.0, w: 210.0, h: 175.0, radius: 10.0, r: 0.72, g: 0.80, b: 0.92, a: 1.0, angle: -0.4, folds: 9.0, sheen: 1.0, pearl: 0.8)
                |> libs/metal:draw.silk(f, x: 460.0, y: 30.0, w: 210.0, h: 175.0, radius: 10.0, r: 0.90, g: 0.62, b: 0.55, a: 1.0, angle: 1.1,  folds: 6.0, sheen: 0.8, pearl: 0.5)
                |> libs/metal:draw.silk(f, x: 680.0, y: 30.0, w: 210.0, h: 175.0, radius: 10.0, r: 0.62, g: 0.72, b: 0.60, a: 1.0, angle: -0.9, folds: 11.0, sheen: 1.0, pearl: 0.9)
                // text band behind row 2 — readable until the frost eats it
                |> libs/metal:draw.text(f, x: 44.0,  y: 262.0, size: 28.0, r: 1.0,  g: 0.95, b: 0.80, a: 1.0, text: "frosted glass — the scene beneath is real")
                |> libs/metal:draw.text(f, x: 44.0,  y: 300.0, size: 15.0, r: 0.75, g: 0.85, b: 1.0,  a: 1.0, text: "silk + text + panels + stripes, captured mid-frame, then scattered")
                // color panels mid-band
                |> libs/metal:draw.roundrect(f, x: 60.0,  y: 345.0, w: 220.0, h: 60.0, radius: 12.0, r: 0.90, g: 0.42, b: 0.38, a: 1.0)
                |> libs/metal:draw.roundrect(f, x: 350.0, y: 345.0, w: 220.0, h: 60.0, radius: 12.0, r: 0.38, g: 0.75, b: 0.48, a: 1.0)
                |> libs/metal:draw.roundrect(f, x: 640.0, y: 345.0, w: 220.0, h: 60.0, radius: 12.0, r: 0.42, g: 0.50, b: 0.90, a: 1.0)
                // stripes behind row 3 — sharp edges for the blur to smear
                |> libs/metal:draw.rect(f, x: 0.0, y: 450.0, w: 920.0, h: 30.0, r: 0.85, g: 0.55, b: 0.30, a: 1.0)
                |> libs/metal:draw.rect(f, x: 0.0, y: 490.0, w: 920.0, h: 30.0, r: 0.30, g: 0.62, b: 0.80, a: 1.0)
                |> libs/metal:draw.rect(f, x: 0.0, y: 530.0, w: 920.0, h: 30.0, r: 0.80, g: 0.38, b: 0.60, a: 1.0)
                |> libs/metal:draw.rect(f, x: 0.0, y: 570.0, w: 920.0, h: 30.0, r: 0.55, g: 0.70, b: 0.42, a: 1.0)
                // ===== the split — scene-so-far becomes texture(2) =====
                |> libs/metal:draw.capture(f)
                // row 1 — scatter radius: clear pane, soft frost, deep frost
                |> libs/metal:draw.frost(f, x: 40.0,  y: 40.0,  w: 260.0, h: 170.0, radius: 4.0,  rough: 0.0,  edge: 16.0, grain: 0.12, milk: 0.18, r: 1.0,  g: 1.0,  b: 1.0,  a: 1.0)
                |> libs/metal:draw.frost(f, x: 330.0, y: 40.0,  w: 260.0, h: 170.0, radius: 22.0, rough: 8.0,  edge: 16.0, grain: 0.12, milk: 0.18, r: 1.0,  g: 1.0,  b: 1.0,  a: 1.0)
                |> libs/metal:draw.frost(f, x: 620.0, y: 40.0,  w: 260.0, h: 170.0, radius: 22.0, rough: 20.0, edge: 16.0, grain: 0.12, milk: 0.18, r: 1.0,  g: 1.0,  b: 1.0,  a: 1.0)
                // row 2 — milk density: clear glass, sea glass, milky slab
                |> libs/metal:draw.frost(f, x: 40.0,  y: 240.0, w: 260.0, h: 170.0, radius: 22.0, rough: 10.0, edge: 16.0, grain: 0.12, milk: 0.10, r: 1.0,  g: 1.0,  b: 1.0,  a: 1.0)
                |> libs/metal:draw.frost(f, x: 330.0, y: 240.0, w: 260.0, h: 170.0, radius: 22.0, rough: 10.0, edge: 16.0, grain: 0.12, milk: 0.50, r: 0.85, g: 0.95, b: 1.0,  a: 1.0)
                |> libs/metal:draw.frost(f, x: 620.0, y: 240.0, w: 260.0, h: 170.0, radius: 22.0, rough: 10.0, edge: 16.0, grain: 0.12, milk: 0.90, r: 0.95, g: 0.92, b: 0.85, a: 1.0)
                // row 3 — rim + grain + tint: flat frost, heavy chamfer +
                // sparkle, amber milk
                |> libs/metal:draw.frost(f, x: 40.0,  y: 440.0, w: 260.0, h: 170.0, radius: 0.0,  rough: 12.0, edge: 0.0,  grain: 0.0,  milk: 0.25, r: 1.0,  g: 1.0,  b: 1.0,  a: 1.0)
                |> libs/metal:draw.frost(f, x: 330.0, y: 440.0, w: 260.0, h: 170.0, radius: 22.0, rough: 12.0, edge: 30.0, grain: 0.55, milk: 0.30, r: 0.90, g: 0.97, b: 1.0,  a: 1.0)
                |> libs/metal:draw.frost(f, x: 620.0, y: 440.0, w: 260.0, h: 170.0, radius: 22.0, rough: 12.0, edge: 16.0, grain: 0.20, milk: 0.60, r: 1.0,  g: 0.80, b: 0.55, a: 1.0)
                |> if (world.frame == 30)
                    | then |> libs/metal:window.snap(path: "/tmp/omni_frost.bmp")
            ! key-down k when k.code == 53 |> libs/host:quit()
            ! close |> libs/host:quit()
            | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("frost: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
