// Dome probe — the glass-first dome over a real photograph, palette
// ctx-injected from a theme store exactly as the gallery does. The
// backdrop is /Users/larsde/Downloads/86474.jpg (forest). Snaps
// /tmp/dome_probe.bmp at frame 20, quits at 25.
import libs/host
import libs/canvas
import libs/components/glasscard
import libs/components/lens
import libs/math
import std/store
import std/ctx
import std/io

std/store:new(st) { frame: 0[i64], face: 0[i64], tex: 0[i64] }
std/store:new(sd) { ddx: 0.0[f64], ddy: 0.0[f64] }
std/store:new(theme) {
    pr: 0.90[f64], pg: 0.92[f64], pb: 0.96[f64],
    kr: 0.94[f64], kg: 0.95[f64], kb: 0.98[f64],
    rr: 0.30[f64], rg: 0.50[f64], rb: 0.80[f64],
    ir: 0.14[f64], ig: 0.18[f64], ib: 0.26[f64],
    li: 1.0[f64], lg: 1.0[f64], lb: 1.0[f64],
}

libs/canvas:window.open(width: 800, height: 560, title: "dome probe")
| win w
    |> libs/canvas:window.clear.color(win: w, r: 0.90, g: 0.92, b: 0.96)
    |> libs/canvas:font.load(win: w, path: "/System/Library/Fonts/SFNSMono.ttf")
        | font fc |> std/store:stored { st.face: fc }
        | err fe |> std/io:print.ln(fe)
    |> libs/canvas:image.load(win: w, path: "/Users/larsde/Downloads/86474.jpg")
        | img tx |> std/store:stored { st.tex: tx }
        | err ie |> std/io:print.ln(ie)
    |> libs/canvas:frames(win: w, count: 90)
    ! frame f
        |> std/store:stored { st.frame: st.frame + 1 }
        |> libs/math:sin(x: @as(f64, @floatFromInt(st.frame)) / 60.0 * 0.21) : d1
        |> libs/math:sin(x: @as(f64, @floatFromInt(st.frame)) / 60.0 * 0.14 + 2.1) : d2
        |> libs/math:sin(x: @as(f64, @floatFromInt(st.frame)) / 60.0 * 0.19 + 1.7) : d3
        |> libs/math:sin(x: @as(f64, @floatFromInt(st.frame)) / 60.0 * 0.12 + 0.6) : d4
        |> std/store:stored { sd.ddx: d1 * 60.0 + d2 * 15.0, sd.ddy: d3 * 45.0 + d4 * 12.0 }
        |> std/ctx(theme)
        |> libs/components/glasscard:glasscard(win: w, f, st.tex, cx: 285.0, cy: 280.0, w: 210.0, h: 58.0, bx: 80.0 + sd.ddx, by: 170.0 + sd.ddy, bw: 640.0, bh: 220.0, rad: 29.0, label: "frost", st.face, a: 1.0, li: 1.0, lg: 1.0, lb: 1.0)
        |> libs/components/lens:lens(win: w, f, st.tex, cx: 515.0, cy: 280.0, w: 210.0, h: 58.0, bx: 80.0 + sd.ddx, by: 170.0 + sd.ddy, bw: 640.0, bh: 220.0, rad: 29.0, label: "lens", st.face, a: 1.0, tr: 0.10, tg: 0.12, tb: 0.17, ta: 0.55, li: 1.0, lg: 1.0, lb: 1.0)
        |> if (st.frame == 20)
            | then |> libs/canvas:window.snap(path: "/tmp/dome_probe_a.bmp")
        |> if (st.frame == 80)
            | then |> libs/canvas:window.snap(path: "/tmp/dome_probe_b.bmp")
        |> if (st.frame >= 85)
            | then |> libs/host:quit()
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/canvas:window.close(win: w2) |> std/io:print.ln("dome probe: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
