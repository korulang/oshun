// avatar probe — circle crop check. Loads Victoria's neutral portrait,
// draws the medallion on the blue-paper stage, snaps /tmp/avatar_probe.bmp
// at frame 20, quits at 25.
import libs/host
import libs/metal
import libs/components/avatar
import std/store
import std/ctx
import std/io

std/store:new(st) { frame: 0[i64], face: 0[i64], tex: 0[i64] }
std/store:new(theme) {
    pr: 0.90[f64], pg: 0.92[f64], pb: 0.96[f64],
    kr: 0.94[f64], kg: 0.95[f64], kb: 0.98[f64],
    rr: 0.30[f64], rg: 0.50[f64], rb: 0.80[f64],
    ir: 0.14[f64], ig: 0.18[f64], ib: 0.26[f64],
}

libs/metal:window.open(width: 800, height: 560, title: "avatar probe")
| win w
    |> libs/metal:window.clear.color(win: w, r: 0.90, g: 0.92, b: 0.96)
    |> libs/metal:font.load(win: w, path: "/Users/larsde/Downloads/SF-Pro.ttf")
        | font fc |> std/store:stored { st.face: fc }
        | err fe |> std/io:print.ln(fe)
    |> libs/metal:image.load(win: w, path: "/Users/larsde/src/6digit-victoria/neutral_albedo.jpg")
        | img tx |> std/store:stored { st.tex: tx }
        | err ie |> std/io:print.ln(ie)
    |> libs/metal:frames(win: w, count: 30)
    ! frame f
        |> std/store:stored { st.frame: st.frame + 1 }
        |> std/ctx(theme)
        |> libs/components/avatar:avatar(win: w, f, st.tex, cx: 400.0, cy: 260.0, d: 220.0, name: "victoria", st.face, a: 1.0)
        |> if (st.frame == 20)
            | then |> libs/metal:window.snap(path: "/tmp/avatar_probe.bmp")
        |> if (st.frame >= 25)
            | then |> libs/host:quit()
    ! key-down k when k.code == 53 |> libs/host:quit()
    ! close |> libs/host:quit()
    | done w2 |> libs/metal:window.close(win: w2) |> std/io:print.ln("avatar probe: closed")
| err e |> std/io:print.ln("metal init failed: {{ e:s }}")
