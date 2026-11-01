// OMNI field-camera spike — CORDIAL ConceptGraph camera + spring layout over
// the depth field, ported control-for-control:
//   wheel        = zoom, multiplicative step 0.20 * z^0.25 about the centre
//   drag (field) = pan offset that persists (5px deadband, then free)
//   pointer      = ±12px parallax drift (POINTER_FOLLOW_STRENGTH)
//   click card   = camera glides to it (focus pan + zoom 1.35)
//   click field  = release to overview; → cycles focus, R resets, D drift
// Cards float on a d3-lite sim — zone attraction + charge repulsion + collide,
// alpha-decayed, render-position lerped like CORDIAL's renderPositions.
// Apparent scale (camera zoom × staleness shrink) picks the semantic LOD:
// full card → signature tile → uniform far tile with a kind-identity bar.
//
//   koruc run metal/tests/field_cam.k live   — hold the window, play with it
//   koruc run metal/tests/field_cam.k        — scripted: snaps to /tmp/field_cam_*

import libs/host
import libs/metal
import std/args
import std/store
import std/grid
import std/io

std/store:new(world) {
    frame: 0[i64], live: 0[i64], focus: -1[i64], hitid: -1[i64], drift: 1[i64],
    down: 0[i64], moved: 0[i64], face: 0[i64]
}

std/store:new(fworld) {
    mx: 480.0[f64], my: 310.0[f64],
    dmx: 0.0[f64], dmy: 0.0[f64], dux: 0.0[f64], duy: 0.0[f64],
    alpha: 1.0[f64], ox: 0.0[f64], oy: 0.0[f64],
    cx: 0.0[f64], cy: 0.0[f64], ctx: 0.0[f64], cty: 0.0[f64],
    ux: 0.0[f64], uy: 0.0[f64],
    cz: 0.95[f64], ctz: 0.95[f64],
    parx: 0.0[f64], pary: 0.0[f64]
}

// One row per field card: sim position (x,y + v), zone anchor (zx,zy), render
// position (rx,ry lerps toward the sim), staleness t, kind + identity tint,
// last-frame screen rect (hx,hy,hw,hh) for hit tests, apparent scale s.
std/grid:new(node, size: 12) {
    x: 0.0[f64], y: 0.0[f64], vx: 0.0[f64], vy: 0.0[f64],
    zx: 0.0[f64], zy: 0.0[f64], rx: 0.0[f64], ry: 0.0[f64],
    t: 0.0[f64], touched: 0.0[f64], kind: 0.0[f64], s: 1.0[f64],
    kr: 0.0[f64], kg: 0.0[f64], kb: 0.0[f64],
    hx: 0.0[f64], hy: 0.0[f64], hw: 0.0[f64], hh: 0.0[f64]
}

// Zones on a loose 4×3 lattice; start positions jittered off them so the sim
// visibly settles. touched staggers by 30 frames so ages (and LODs) differ.
for(0..12)
! each i |> std/grid:stored {
    node[i].zx: 170.0 + @as(f64, @floatFromInt(i - (i / 4) * 4)) * 205.0,
    node[i].zy: 165.0 + @as(f64, @floatFromInt(i / 4)) * 175.0,
    node[i].x: 170.0 + @as(f64, @floatFromInt(i - (i / 4) * 4)) * 205.0 + @as(f64, @floatFromInt((i * 137) % 67)) - 33.0,
    node[i].y: 165.0 + @as(f64, @floatFromInt(i / 4)) * 175.0 + @as(f64, @floatFromInt((i * 89) % 53)) - 26.0,
    node[i].rx: 170.0 + @as(f64, @floatFromInt(i - (i / 4) * 4)) * 205.0 + @as(f64, @floatFromInt((i * 137) % 67)) - 33.0,
    node[i].ry: 165.0 + @as(f64, @floatFromInt(i / 4)) * 175.0 + @as(f64, @floatFromInt((i * 89) % 53)) - 26.0,
    node[i].kind: @as(f64, @floatFromInt(i)),
    node[i].touched: @as(f64, @floatFromInt(0 - @as(i64, @intCast(i)) * 30)),
    node[i].kr: if (i == 0) 0.85 else if (i == 1) 0.16 else if (i == 2) 0.45 else if (i == 3) 0.90 else if (i == 4) 0.82 else if (i == 5) 0.58 else if (i == 6) 0.20 else if (i == 7) 0.25 else if (i == 8) 0.30 else if (i == 9) 0.88 else 0.65,
    node[i].kg: if (i == 0) 0.62 else if (i == 1) 0.12 else if (i == 2) 0.50 else if (i == 3) 0.86 else if (i == 4) 0.38 else if (i == 5) 0.40 else if (i == 6) 0.62 else if (i == 7) 0.45 else if (i == 8) 0.65 else if (i == 9) 0.55 else 0.35,
    node[i].kb: if (i == 0) 0.20 else if (i == 1) 0.08 else if (i == 2) 0.58 else if (i == 3) 0.78 else if (i == 4) 0.45 else if (i == 5) 0.92 else if (i == 6) 0.58 else if (i == 7) 0.85 else if (i == 8) 0.38 else if (i == 9) 0.18 else 1.00
}

// Sim passes — named tors because grid:sweep wants one branch per site.
// Zone attraction: d3 forceX/forceY, strength 0.5, alpha-scaled.
tor zone-pull {}
zone-pull = std/grid:sweep(node)
! sweep n |> std/grid:stored { n.vx: n.vx + (n.zx - n.x) * 0.5 * fworld.alpha, n.vy: n.vy + (n.zy - n.y) * 0.5 * fworld.alpha }

// Charge + collide, pairwise. Self excluded by the d2 > 1 guard. Charge
// repels ∝ 1/d; collide pushes apart inside a 160px card radius.
tor pairwise {}
pairwise = for(0..12)
    ! each i |> for(0..12)
        ! each j |> std/grid:stored {
            node[i].vx: node[i].vx + (node[i].x - node[j].x) * if ((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y) > 1.0) (24000.0 * fworld.alpha / ((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y)) / @sqrt((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y)) + if ((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y) < 25600.0) (160.0 - @sqrt((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y))) * 0.30 * fworld.alpha / @sqrt((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y)) else 0.0) else 0.0,
            node[i].vy: node[i].vy + (node[i].y - node[j].y) * if ((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y) > 1.0) (24000.0 * fworld.alpha / ((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y)) / @sqrt((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y)) + if ((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y) < 25600.0) (160.0 - @sqrt((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y))) * 0.30 * fworld.alpha / @sqrt((node[i].x - node[j].x) * (node[i].x - node[j].x) + (node[i].y - node[j].y) * (node[i].y - node[j].y)) else 0.0) else 0.0
        }

// Integrate: velocityDecay 0.90, soft bounds, render-lerp 0.14, drift clock.
tor integrate {}
integrate = std/grid:sweep(node)
! sweep n |> std/grid:stored {
    n.vx: n.vx * 0.90, n.vy: n.vy * 0.90,
    n.x: @min(890.0, @max(70.0, n.x + n.vx)),
    n.y: @min(560.0, @max(60.0, n.y + n.vy)),
    n.t: if (world.drift == 0) 0.0 else @min(1.0, @max(0.0, (@as(f64, @floatFromInt(world.frame)) - n.touched) / 300.0)),
    n.rx: n.rx + (n.x - n.rx) * 0.14,
    n.ry: n.ry + (n.y - n.ry) * 0.14
}

// Camera solve: apparent scale + screen rect through the camera transform —
// screen = centre + (world − centre)·zoom + focusPan + userPan + parallax.
tor cam-solve {}
cam-solve = std/grid:sweep(node)
! sweep n |> std/grid:stored {
    n.s: fworld.cz * (1.0 - 0.5 * n.t),
    n.hw: 150.0 * fworld.cz * (1.0 - 0.5 * n.t), n.hh: 96.0 * fworld.cz * (1.0 - 0.5 * n.t),
    n.hx: 480.0 + (n.rx - 480.0) * fworld.cz + fworld.ox - 75.0 * fworld.cz * (1.0 - 0.5 * n.t),
    n.hy: 310.0 + (n.ry - 310.0) * fworld.cz + fworld.oy - 48.0 * fworld.cz * (1.0 - 0.5 * n.t)
}

libs/metal:window.open(width: 960, height: 620, title: "omni — field cam, esc quits")
| win w |> libs/metal:window.clear.color(win: w, r: 0.10, g: 0.10, b: 0.15)
    |> std/args:get(index: 1)
        | arg a |> std/store:stored { world.live: if (a == "live") 1 else 0 }
        | out-of-bounds |> std/store:stored { world.live: 0 }
    |> libs/metal:font.load(win: w, path: "/tmp/archivo/Archivo_Black/ArchivoBlack-Regular.ttf")
        | font fnt |> std/store:stored { world.face: fnt }
        | err e |> std/io:print.ln("font failed: {{ e:s }}")
    |> libs/metal:frames(win: w, count: if (world.live == 1) 999999 else 380)
        ! frame f
            |> std/store:stored { world.frame: world.frame + 1 }
            // Camera springs — CORDIAL stiffness/damping as per-frame lerp:
            // focus pan + zoom chase their targets, parallax lags slower.
            |> std/store:stored { fworld.alpha: @max(0.03, fworld.alpha * 0.995) }
            |> std/store:stored { fworld.cx: fworld.cx + (fworld.ctx - fworld.cx) * 0.12, fworld.cy: fworld.cy + (fworld.cty - fworld.cy) * 0.12, fworld.cz: fworld.cz + (fworld.ctz - fworld.cz) * 0.10 }
            |> std/store:stored { fworld.parx: fworld.parx + (((fworld.mx - 480.0) / 480.0) * 12.0 - fworld.parx) * 0.08, fworld.pary: fworld.pary + (((fworld.my - 310.0) / 310.0) * 12.0 - fworld.pary) * 0.08 }
            |> std/store:stored { fworld.ox: fworld.cx + fworld.ux + fworld.parx, fworld.oy: fworld.cy + fworld.uy + fworld.pary }
            // A focused card stays centred: re-aim the pan target every frame
            // at the card's CURRENT render position (the sim keeps jostling it).
            |> if (world.focus >= 0)
                | then |> std/store:stored { fworld.ctx: (480.0 - node[world.focus].rx) * fworld.ctz, fworld.cty: (310.0 - node[world.focus].ry) * fworld.ctz }
            |> zone-pull() |> pairwise() |> integrate() |> cam-solve()
            // Champagne room.
            |> libs/metal:draw.roundrect(f, x: 0.0, y: 0.0, w: 960.0, h: 620.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
            |> if (world.face > 0)
                | then |> libs/metal:draw.textface(f, x: 18.0, y: 16.0, size: 20.0, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 0.55, text: "field cam")
            // The field: zone dots (the spring's anchors, faint) then cards.
            |> for(0..12)
                ! each i |> libs/metal:draw.rect(f, x: 480.0 + (node[i].zx - 480.0) * fworld.cz + fworld.ox - 2.0, y: 310.0 + (node[i].zy - 310.0) * fworld.cz + fworld.oy - 2.0, w: 4.0, h: 4.0, r: 0.4, g: 0.35, b: 0.3, a: 0.35)
            |> for(0..12)
                ! each i |> if (node[i].s >= 0.75)
                    | then |> libs/metal:draw.shadow(f, x: node[i].hx + 2.0, y: node[i].hy + 5.0, w: node[i].hw, h: node[i].hh, radius: 10.0 * node[i].s, blur: 14.0 * node[i].s, r: 0.15, g: 0.1, b: 0.05, a: 0.3 * (1.0 - 0.6 * node[i].t))
                        |> libs/metal:draw.panel(f, x: node[i].hx, y: node[i].hy, w: node[i].hw, h: node[i].hh, radius: 10.0 * node[i].s, r: 0.97, g: 0.92, b: 0.80, a: 1.0 - 0.55 * node[i].t, bw: 1.5, br: 0.55, bg: 0.45, bb: 0.30, ba: 0.9 * (1.0 - 0.55 * node[i].t))
                        |> libs/metal:draw.rect(f, x: node[i].hx, y: node[i].hy + node[i].hh - 6.0 * node[i].s, w: node[i].hw, h: 6.0 * node[i].s, r: node[i].kr, g: node[i].kg, b: node[i].kb, a: 0.95 * (1.0 - 0.55 * node[i].t))
                        |> libs/metal:draw.rect(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 30.0 * node[i].s, w: node[i].hw * 0.8, h: 5.0 * node[i].s, r: 0.55, g: 0.48, b: 0.38, a: 0.55 * (1.0 - 0.55 * node[i].t))
                        |> libs/metal:draw.rect(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 42.0 * node[i].s, w: node[i].hw * 0.62, h: 5.0 * node[i].s, r: 0.55, g: 0.48, b: 0.38, a: 0.45 * (1.0 - 0.55 * node[i].t))
                        |> libs/metal:draw.rect(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 54.0 * node[i].s, w: node[i].hw * 0.7, h: 5.0 * node[i].s, r: 0.55, g: 0.48, b: 0.38, a: 0.35 * (1.0 - 0.55 * node[i].t))
                        |> if (world.face > 0)
                            | then |> if (node[i].kind == 0.0)
                                | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "hub")
                                | else |> if (node[i].kind == 1.0)
                                    | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "button")
                                    | else |> if (node[i].kind == 2.0)
                                        | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "caption")
                                        | else |> if (node[i].kind == 3.0)
                                            | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "wordmark")
                                            | else |> if (node[i].kind == 4.0)
                                                | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "remote")
                                                | else |> if (node[i].kind == 5.0)
                                                    | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "waveform")
                                                    | else |> if (node[i].kind == 6.0)
                                                        | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "docpage")
                                                        | else |> if (node[i].kind == 7.0)
                                                            | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "codeview")
                                                            | else |> if (node[i].kind == 8.0)
                                                                | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "diffview")
                                                                | else |> if (node[i].kind == 9.0)
                                                                    | then |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.16, g: 0.12, b: 0.08, a: 1.0 - 0.55 * node[i].t, text: "turnview")
                                                                    | else |> libs/metal:draw.textface(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 10.0 * node[i].s, size: 11.0 * node[i].s, font: world.face, r: 0.55, g: 0.35, b: 0.95, a: 1.0 - 0.55 * node[i].t, text: "agent")
                    | else |> if (node[i].s >= 0.38)
                        | then |> libs/metal:draw.panel(f, x: node[i].hx, y: node[i].hy, w: node[i].hw, h: node[i].hh, radius: 10.0 * node[i].s, r: 0.95, g: 0.90, b: 0.77, a: 0.92 * (1.0 - 0.55 * node[i].t), bw: 1.0, br: 0.55, bg: 0.45, bb: 0.30, ba: 0.7 * (1.0 - 0.55 * node[i].t))
                            |> libs/metal:draw.rect(f, x: node[i].hx, y: node[i].hy + node[i].hh - 5.0 * node[i].s, w: node[i].hw, h: 5.0 * node[i].s, r: node[i].kr, g: node[i].kg, b: node[i].kb, a: 0.95 * (1.0 - 0.55 * node[i].t))
                            |> libs/metal:draw.rect(f, x: node[i].hx + 12.0 * node[i].s, y: node[i].hy + 16.0 * node[i].s, w: node[i].hw * 0.55, h: 5.0 * node[i].s, r: 0.35, g: 0.3, b: 0.24, a: 0.8 * (1.0 - 0.55 * node[i].t))
                        | else |> libs/metal:draw.roundrect(f, x: node[i].hx, y: node[i].hy, w: node[i].hw, h: node[i].hh, radius: 8.0 * node[i].s, r: 0.93, g: 0.88, b: 0.75, a: 0.85 * (1.0 - 0.5 * node[i].t))
                            |> libs/metal:draw.rect(f, x: node[i].hx, y: node[i].hy + node[i].hh - 4.0 * node[i].s, w: node[i].hw, h: 4.0 * node[i].s, r: node[i].kr, g: node[i].kg, b: node[i].kb, a: 0.9 * (1.0 - 0.5 * node[i].t))
                            |> libs/metal:draw.rect(f, x: node[i].hx + node[i].hw * 0.12, y: node[i].hy + node[i].hh * 0.3, w: node[i].hw * 0.45, h: 3.0 * node[i].s, r: 0.4, g: 0.35, b: 0.28, a: 0.7 * (1.0 - 0.5 * node[i].t))
            // Focus ring — after all cards so it always reads.
            |> if (world.focus >= 0)
                | then |> libs/metal:draw.panel(f, x: node[world.focus].hx - 5.0, y: node[world.focus].hy - 5.0, w: node[world.focus].hw + 10.0, h: node[world.focus].hh + 10.0, radius: 12.0, r: 0.65, g: 0.35, b: 1.0, a: 0.0, bw: 2.0, br: 0.65, bg: 0.35, bb: 1.0, ba: 0.85)
            // Scripted receipts: zoom → pan → focus → reset → aged drift.
            |> if (world.frame == 40 and world.live == 0)
                | then |> libs/metal:window.snap(path: "/tmp/field_cam_1_overview.bmp")
            |> if (world.frame == 50 and world.live == 0)
                | then |> libs/metal:input.scroll(x: 480.0, y: 310.0, dx: 0.0, dy: -140.0)
            |> if (world.frame == 54 and world.live == 0)
                | then |> libs/metal:input.scroll(x: 480.0, y: 310.0, dx: 0.0, dy: -140.0)
            |> if (world.frame == 58 and world.live == 0)
                | then |> libs/metal:input.scroll(x: 480.0, y: 310.0, dx: 0.0, dy: -140.0)
            |> if (world.frame == 85 and world.live == 0)
                | then |> libs/metal:window.snap(path: "/tmp/field_cam_2_zoom.bmp")
            |> if (world.frame == 95 and world.live == 0)
                | then |> libs/metal:input.mouse(x: 300.0, y: 300.0)
            |> if (world.frame == 98 and world.live == 0)
                | then |> libs/metal:input.drag(x: 340.0, y: 320.0)
            |> if (world.frame == 101 and world.live == 0)
                | then |> libs/metal:input.drag(x: 390.0, y: 345.0)
            |> if (world.frame == 104 and world.live == 0)
                | then |> libs/metal:input.up(x: 390.0, y: 345.0)
            |> if (world.frame == 125 and world.live == 0)
                | then |> libs/metal:window.snap(path: "/tmp/field_cam_3_pan.bmp")
            |> if (world.frame == 135 and world.live == 0)
                | then |> libs/metal:input.key(code: 124)
            |> if (world.frame == 165 and world.live == 0)
                | then |> libs/metal:window.snap(path: "/tmp/field_cam_4_focus.bmp")
            |> if (world.frame == 175 and world.live == 0)
                | then |> libs/metal:input.key(code: 15)
            |> if (world.frame == 205 and world.live == 0)
                | then |> libs/metal:window.snap(path: "/tmp/field_cam_5_reset.bmp")
            |> if (world.frame == 350 and world.live == 0)
                | then |> libs/metal:window.snap(path: "/tmp/field_cam_6_drift.bmp")
            |> if (world.frame == 370 and world.live == 0)
                | then |> libs/host:quit()
        ! mouse-move e
            |> std/store:stored { fworld.mx: e.x, fworld.my: e.y }
        ! mouse-down e
            |> std/store:stored { world.down: 1, world.moved: 0 }
            |> std/store:stored { fworld.dmx: e.x, fworld.dmy: e.y, fworld.dux: fworld.ux, fworld.duy: fworld.uy }
        ! mouse-drag e
            |> if (world.down == 1)
                | then |> std/store:stored { world.moved: if ((e.x - fworld.dmx) * (e.x - fworld.dmx) + (e.y - fworld.dmy) * (e.y - fworld.dmy) > 25.0) 1 else world.moved }
                    |> if (world.moved == 1)
                        | then |> std/store:stored { fworld.ux: fworld.dux + (e.x - fworld.dmx), fworld.uy: fworld.duy + (e.y - fworld.dmy) }
        ! mouse-up e
            |> std/store:stored { world.down: 0 }
            |> if (world.moved == 0)
                | then |> std/store:stored { world.hitid: -1 }
                    |> for(0..12)
                        ! each i |> if (e.x >= node[i].hx and e.x < node[i].hx + node[i].hw and e.y >= node[i].hy and e.y < node[i].hy + node[i].hh)
                            | then |> std/grid:stored { node[i].touched: @as(f64, @floatFromInt(world.frame)) }
                                |> std/store:stored { world.hitid: @as(i64, @intCast(i)) }
                    |> if (world.hitid >= 0)
                        | then |> std/store:stored { world.focus: world.hitid } |> std/store:stored { fworld.ctz: 1.35 }
                        | else |> std/store:stored { world.focus: -1 } |> std/store:stored { fworld.ctx: 0.0, fworld.cty: 0.0 }
        ! scroll e
            |> std/store:stored { fworld.ctz: @min(4.0, @max(0.30, fworld.ctz * (if (e.dy > 0.0) 1.0 - 0.20 * @sqrt(@sqrt(fworld.ctz)) else 1.0 + 0.20 * @sqrt(@sqrt(fworld.ctz))))) }
        ! key-down k when k.code == 124
            |> std/store:stored { world.focus: if (world.focus + 1 >= 12) 0 else world.focus + 1 }
            |> std/store:stored { fworld.ctz: 1.35 }
            |> std/grid:stored { node[world.focus].touched: @as(f64, @floatFromInt(world.frame)) }
        ! key-down k when k.code == 15
            |> std/store:stored { world.focus: -1 }
            |> std/store:stored { fworld.ctx: 0.0, fworld.cty: 0.0, fworld.ux: 0.0, fworld.uy: 0.0, fworld.ctz: 0.95 }
        ! key-down k when k.code == 2
            |> std/store:stored { world.drift: if (world.drift == 0) 1 else 0 }
        ! key-down k when k.code == 53 |> libs/host:quit()
        ! close |> libs/host:quit()
        | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("field cam: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
