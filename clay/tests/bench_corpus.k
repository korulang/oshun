// Corpus bench — solver A/B over the fuzz gate's generated spec stream.
// The generator (LCG + spec table) and both walks are copied verbatim
// from fuzz_gate.k minus the MUT pass, so the measured workload IS the
// differentially-validated corpus: every feature the gate exercises
// (pct>1, per-side pad, floating roots, clip, img/custom, wrapped text,
// overlay, radii, borders, text config) is in the timed path. Per-frame
// interleave, same clock for both solvers:
//   lap 1  clay declare (spec query + el.* calls)
//   lap 2  clay solve (EndLayout)
//   lap 3  clay drain (each, counted)
//   lap 4  nl declare, lap 5 nl solve, lap 6 nl drain
// Both drains count commands into world.n/world.m — the printed counts
// are an in-bench equivalence sanity (must be equal). pct>1 rows fire
// ~50 diagnostics per declaration; clayErr's stdout `err t=` tokens and
// the stderr lines are part of each side's honest per-frame cost —
// filter with `tail`/`grep` when reading.
import libs/clay
import libs/nativelayout
import std/store
import std/io
import std/benchmarking

std/store:new(world) { n: 0[i64], m: 0[i64] }

// LCG state — s is the draw the depth/kind dice read; s2..s5 chain off it.
std/store:new(rng) { s: 123456789[i64], s2: 0[i64], s3: 0[i64], s4: 0[i64], s5: 0[i64] }

// Generator bookkeeping — d = spec depth (parent open-count), prev = was
// the last row a container (descend legal), wk/hk = this row's size kinds.
std/store:new(gen) { d: 1[i64], k: 0[i64], prev: 1[i64], wk: 1[i64], hk: 1[i64] }

// Spec rows in DFS order — identical schema and draws to fuzz_gate.k.
// kind: 0 panel | 1 clip | 2 img | 3 text | 4 custom.  wk/hk: 0 fit 1 grow 2 pct 3 fix.
std/store:new(specs, capacity: 2048) {
    d: i64, kind: i64, eid: i64,
    wk: i64, w: f64, hk: i64, h: f64,
    dir: i64, gap: i64, padl: i64, padr: i64, padt: i64, padb: i64,
    ax: i64, ay: i64, dk: i64,
    r: f64, g: f64, b: f64, a: f64,
    ova: f64,
    crtl: f64, crtr: f64, cbl: f64, cbr: f64,
    ar: f64,
    br: f64, bg: f64, bb: f64, ba: f64,
    bwl: i64, bwr: i64, bwt: i64, bwb: i64, bwc: i64,
    fat: i64, fx: f64, fy: f64,
    fae: i64, fap: i64, exw: f64, exh: f64, zi: i64, fct: i64,
    ox: f64, oy: f64, hv: i64,
    fid: i64, ls: i64, lh: i64, wm: i64, tal: i64,
    txc: i64, fs: f64,
}

for(0..1200)
    ! each i
        |> std/store:stored { rng.s: @mod(rng.s * 1103515245 + 12345, 2147483648) }
        |> std/store:stored { rng.s2: @mod(rng.s * 1103515245 + 12345, 2147483648) }
        |> std/store:stored { rng.s3: @mod(rng.s2 * 1103515245 + 12345, 2147483648) }
        |> std/store:stored { rng.s4: @mod(rng.s3 * 1103515245 + 12345, 2147483648) }
        |> std/store:stored { rng.s5: @mod(rng.s4 * 1103515245 + 12345, 2147483648) }
        |> std/store:stored {
            gen.d: if (gen.prev == 1 and @mod(rng.s, 100) < 30) (if (gen.d < 6) gen.d + 1 else 6) else if (@mod(rng.s, 100) < 75) gen.d else 1 + @mod(rng.s2, gen.d),
            gen.k: @mod(@divTrunc(rng.s, 400), 10),
            gen.wk: @mod(@divTrunc(rng.s, 4000), 4),
            gen.hk: @mod(@divTrunc(rng.s, 16000), 4)
        }
        |> std/store:insert(specs) {
            gen.d,
            kind: if (gen.k < 5) 0 else if (gen.k < 7) 1 else if (gen.k < 8) 2 else if (gen.k < 9) 4 else 3,
            eid: @as(i64, @intCast(i)),
            gen.wk,
            w: if (gen.wk == 2) (if (@mod(rng.s2, 8) == 0) 1.02 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 97), 58))) / 100.0 else 0.05 + @as(f64, @floatFromInt(@mod(rng.s2, 94))) / 100.0) else if (gen.wk == 1 and @mod(rng.s2, 2) == 0) 0.0 else 4.0 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 300), 76))),
            gen.hk,
            h: if (gen.hk == 2) (if (@mod(@divTrunc(rng.s2, 7919), 8) == 0) 1.02 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 611953), 58))) / 100.0 else 0.05 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 60000), 94))) / 100.0) else if (gen.hk == 1 and @mod(@divTrunc(rng.s2, 7), 2) == 0) 0.0 else 4.0 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 1000000), 76))),
            dir: @mod(rng.s3, 2),
            gap: @mod(@divTrunc(rng.s3, 2), 8),
            padl: @mod(@divTrunc(rng.s3, 16), 10),
            padr: if (@mod(@divTrunc(rng.s4, 256), 4) == 3) @mod(@divTrunc(rng.s4, 4096), 10) else @mod(@divTrunc(rng.s3, 16), 10),
            padt: if (@mod(@divTrunc(rng.s4, 65536), 4) == 3) @mod(@divTrunc(rng.s4, 1048576), 10) else @mod(@divTrunc(rng.s3, 16), 10),
            padb: if (@mod(@divTrunc(rng.s4, 16777216), 4) == 3) @mod(@divTrunc(rng.s4, 268435456), 10) else @mod(@divTrunc(rng.s3, 16), 10),
            ax: @mod(@divTrunc(rng.s3, 160), 3),
            ay: @mod(@divTrunc(rng.s3, 480), 3),
            dk: @mod(@divTrunc(rng.s3, 1440), 5),
            r: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s3, 7200), 256))),
            g: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s3, 1843200), 256))),
            b: @as(f64, @floatFromInt(@mod(rng.s4, 256))),
            a: if (@mod(@divTrunc(rng.s4, 256), 6) == 0) 128.0 else 255.0,
            ova: if (@mod(@divTrunc(rng.s5, 4), 5) == 4) 0.2 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s5, 1024), 70))) / 100.0 else 0.0,
            crtl: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 2097152), 24))),
            crtr: if (@mod(@divTrunc(rng.s4, 268435456), 4) == 3) @as(f64, @floatFromInt(@mod(@divTrunc(rng.s3, 2097152), 24))) else @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 2097152), 24))),
            cbl: if (@mod(@divTrunc(rng.s5, 256), 4) == 3) @as(f64, @floatFromInt(@mod(@divTrunc(rng.s3, 33554432), 24))) else @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 2097152), 24))),
            cbr: if (@mod(@divTrunc(rng.s5, 65536), 4) == 3) @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 268435456), 24))) else @as(f64, @floatFromInt(@mod(@divTrunc(rng.s2, 2097152), 24))),
            ar: if (@mod(@divTrunc(rng.s3, 805306368), 3) == 0) 0.0 else 0.5 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s5, 402653184), 6))) * 0.5,
            br: @as(f64, @floatFromInt(@mod(rng.s5, 256))),
            bg: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s5, 256), 256))),
            bb: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s5, 65536), 256))),
            ba: if (@mod(@divTrunc(rng.s5, 16777216), 6) == 0) 0.0 else 255.0,
            bwl: if (@mod(@divTrunc(rng.s4, 131072), 4) == 3) @mod(@divTrunc(rng.s4, 524288), 7) else 0,
            bwr: if (@mod(@divTrunc(rng.s3, 262144), 4) == 3) @mod(@divTrunc(rng.s5, 2097152), 7) else 0,
            bwt: if (@mod(@divTrunc(rng.s5, 1048576), 4) == 3) @mod(@divTrunc(rng.s3, 32768), 7) else 0,
            bwb: if (@mod(@divTrunc(rng.s4, 33554432), 5) == 4) @mod(@divTrunc(rng.s5, 8192), 7) else 0,
            bwc: if (@mod(@divTrunc(rng.s2, 134217728), 5) == 4) 1 + @mod(@divTrunc(rng.s5, 2048), 5) else 0,
            fat: if (@mod(@divTrunc(rng.s4, 1536), 5) == 0) (if (@mod(@divTrunc(rng.s5, 1073741824), 2) == 0) 1 else 3) else 0,
            fae: @mod(@divTrunc(rng.s5, 1048576), 9),
            fap: @mod(@divTrunc(rng.s4, 24576), 9),
            exw: if (@mod(@divTrunc(rng.s4, 33554432), 3) == 2) @as(f64, @floatFromInt(@mod(@divTrunc(rng.s5, 512), 12))) else 0.0,
            exh: if (@mod(@divTrunc(rng.s5, 134217728), 3) == 2) @as(f64, @floatFromInt(@mod(@divTrunc(rng.s4, 262144), 12))) else 0.0,
            zi: if (@mod(@divTrunc(rng.s5, 33554432), 3) == 2) @mod(@divTrunc(rng.s4, 16), 9) - 4 else 0,
            fct: @mod(@divTrunc(rng.s5, 1073741824), 2),
            fx: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s4, 7680), 400))) - 60.0,
            fy: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s4, 614400), 320))) - 40.0,
            ox: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s4, 4915200), 160))) - 80.0,
            oy: @as(f64, @floatFromInt(@mod(@divTrunc(rng.s4, 7864320), 160))) - 80.0,
            hv: @mod(@divTrunc(rng.s4, 12582912), 4),
            fid: @mod(@divTrunc(rng.s5, 201326592), 4),
            ls: if (@mod(@divTrunc(rng.s4, 2097152), 4) == 3) @mod(@divTrunc(rng.s5, 262144), 4) else 0,
            lh: if (@mod(@divTrunc(rng.s5, 8388608), 5) == 4) 10 + @mod(@divTrunc(rng.s4, 4096), 30) else 0,
            wm: @mod(@divTrunc(rng.s5, 4194304), 3),
            tal: @mod(@divTrunc(rng.s4, 67108864), 3),
            txc: @mod(@divTrunc(rng.s5, 201326592), 5),
            fs: 8.0 + @as(f64, @floatFromInt(@mod(@divTrunc(rng.s5, 50331648), 20))),
        }
            | row _
        |> std/store:stored { gen.prev: if (gen.k < 7) 1 else 0 }

libs/clay:init(width: 900, height: 640)
| cl h |> libs/nativelayout:nl.init(width: 900, height: 640)
    | ncl nh |> std/benchmarking:climb(warmup: 30, frames: 300, reps: 3)
        ! pass
            |> std/store:stored { world.n: 0, world.m: 0 }
            |> libs/clay:layout(cl: h)
                ! tree t
                    |> libs/clay:el.open(t)
                    |> libs/clay:el.cfg(t, wk: 1, w: 0.0, hk: 1, h: 0.0, dir: 1, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: 0.0, g: 0.0, b: 0.0, a: 0.0, fat: 0, fx: 0.0, fy: 0.0, fae: 0, fap: 0, exw: 0.0, exh: 0.0, zi: 0, fct: 0, eid: 7000001, ovr: 0.0, ovg: 0.0, ovb: 0.0, ova: 0.0, crtl: 0.0, crtr: 0.0, crbl: 0.0, crbr: 0.0, ar: 0.0, br: 0.0, bg: 0.0, bb: 0.0, ba: 0.0, bwl: 0, bwr: 0, bwt: 0, bwb: 0, bwc: 0)
                    |> std/store:query(specs)
                        ! query s
                            |> libs/clay:el.close-to(t, s.d)
                            |> if (s.kind == 0)
                                | then |> libs/clay:el.open(t)
                                    |> libs/clay:el.cfg(t,
                                        wk: if (s.dk == 1 or s.dk == 3) 1 else if (s.dk == 2) 3 else s.wk, s.w,
                                        hk: if (s.dk == 1) 3 else if (s.dk == 2 or s.dk == 3) 1 else s.hk, s.h,
                                        s.dir, s.gap, s.padl, s.padr, s.padt, s.padb, s.ax, s.ay,
                                        s.r, s.g, s.b, s.a, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.eid, ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc)
                            |> if (s.kind == 1)
                                | then |> libs/clay:el.clip(t, s.wk, s.w, s.hk, s.h,
                                    s.dir, s.gap, s.padl, s.padr, s.padt, s.padb,
                                    s.r, s.g, s.b, s.a,
                                    ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.ox, s.oy, horiz: @mod(s.hv, 2), vert: @divTrunc(s.hv, 2))
                            |> if (s.kind == 2)
                                | then |> libs/clay:el.open(t)
                                    |> libs/clay:el.img(t, s.wk, s.w, s.hk, s.h,
                                        data: s.eid + 5000, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.eid, ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc)
                                    |> libs/clay:el.close(t)
                            |> if (s.kind == 3)
                                | then |> libs/clay:el.text(t,
                                    tx: if (s.txc == 0) "the quick brown fox jumps over the lazy dog" else if (s.txc == 1) "lorem ipsum dolor sit" else if (s.txc == 2) "ab cd" else "w",
                                    s.fs, s.r, s.g, s.b, s.a, s.eid, s.fid, s.ls, s.lh, s.wm, s.tal)
                            |> if (s.kind == 4)
                                | then |> libs/clay:el.open(t)
                                    |> libs/clay:el.custom(t, s.wk, s.w, s.hk, s.h,
                                        data: s.eid + 9000, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.eid, ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc)
                                    |> libs/clay:el.close(t)
                    |> std/benchmarking:lap(k: 1)
                | solved cls |> std/benchmarking:lap(k: 2)
                    |> libs/clay:each(cl: cls)
                        ! cmd rc |> std/store:stored { world.n: world.n + 1 }
                        | drained |> _
                    |> std/benchmarking:lap(k: 3)
            |> libs/nativelayout:nl.layout(cl: nh)
                ! ntree nt
                    |> libs/nativelayout:nl.el.open(t: nt)
                    |> libs/nativelayout:nl.el.cfg(t: nt, wk: 1, w: 0.0, hk: 1, h: 0.0, dir: 1, gap: 0, padl: 0, padr: 0, padt: 0, padb: 0, ax: 0, ay: 0, r: 0.0, g: 0.0, b: 0.0, a: 0.0, fat: 0, fx: 0.0, fy: 0.0, fae: 0, fap: 0, exw: 0.0, exh: 0.0, zi: 0, fct: 0, eid: 7000001, ovr: 0.0, ovg: 0.0, ovb: 0.0, ova: 0.0, crtl: 0.0, crtr: 0.0, crbl: 0.0, crbr: 0.0, ar: 0.0, br: 0.0, bg: 0.0, bb: 0.0, ba: 0.0, bwl: 0, bwr: 0, bwt: 0, bwb: 0, bwc: 0)
                    |> std/store:query(specs)
                        ! query s
                            |> libs/nativelayout:nl.el.close-to(t: nt, s.d)
                            |> if (s.kind == 0)
                                | then |> libs/nativelayout:nl.el.open(t: nt)
                                    |> libs/nativelayout:nl.el.cfg(t: nt,
                                        wk: if (s.dk == 1 or s.dk == 3) 1 else if (s.dk == 2) 3 else s.wk, s.w,
                                        hk: if (s.dk == 1) 3 else if (s.dk == 2 or s.dk == 3) 1 else s.hk, s.h,
                                        s.dir, s.gap, s.padl, s.padr, s.padt, s.padb, s.ax, s.ay,
                                        s.r, s.g, s.b, s.a, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.eid, ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc)
                            |> if (s.kind == 1)
                                | then |> libs/nativelayout:nl.el.clip(t: nt, s.wk, s.w, s.hk, s.h,
                                    s.dir, s.gap, s.padl, s.padr, s.padt, s.padb,
                                    s.r, s.g, s.b, s.a,
                                    ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.ox, s.oy, horiz: @mod(s.hv, 2), vert: @divTrunc(s.hv, 2))
                            |> if (s.kind == 2)
                                | then |> libs/nativelayout:nl.el.open(t: nt)
                                    |> libs/nativelayout:nl.el.img(t: nt, s.wk, s.w, s.hk, s.h,
                                        data: s.eid + 5000, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.eid, ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc)
                                    |> libs/nativelayout:nl.el.close(t: nt)
                            |> if (s.kind == 3)
                                | then |> libs/nativelayout:nl.el.text(t: nt,
                                    tx: if (s.txc == 0) "the quick brown fox jumps over the lazy dog" else if (s.txc == 1) "lorem ipsum dolor sit" else if (s.txc == 2) "ab cd" else "w",
                                    s.fs, s.r, s.g, s.b, s.a, s.eid, s.fid, s.ls, s.lh, s.wm, s.tal)
                            |> if (s.kind == 4)
                                | then |> libs/nativelayout:nl.el.open(t: nt)
                                    |> libs/nativelayout:nl.el.custom(t: nt, s.wk, s.w, s.hk, s.h,
                                        data: s.eid + 9000, s.fat, s.fx, s.fy, s.fae, s.fap, s.exw, s.exh, s.zi, s.fct, s.eid, ovr: s.r, ovg: s.g, ovb: s.b, s.ova, s.crtl, s.crtr, crbl: s.cbl, crbr: s.cbr, s.ar, s.br, s.bg, s.bb, s.ba, s.bwl, s.bwr, s.bwt, s.bwb, s.bwc)
                                    |> libs/nativelayout:nl.el.close(t: nt)
                    |> std/benchmarking:lap(k: 4)
                | nsolved cls |> std/benchmarking:lap(k: 5)
                    |> libs/nativelayout:nl.each(cl: cls)
                        ! cmd rc |> std/store:stored { world.m: world.m + 1 }
                        | drained |> _
                    |> std/benchmarking:lap(k: 6)
        | done d
            |> std/benchmarking:lap.ms(k: 1): a1 |> std/benchmarking:lap.ms(k: 2): a2 |> std/benchmarking:lap.ms(k: 3): a3
            |> std/benchmarking:lap.ms(k: 4): a4 |> std/benchmarking:lap.ms(k: 5): a5 |> std/benchmarking:lap.ms(k: 6): a6
            |> std/io:print.ln("corpus bench — clay: decl {{ a1:f }} solve {{ a2:f }} drain {{ a3:f }} cmds {{ world.n:d }} | nl: decl {{ a4:f }} solve {{ a5:f }} drain {{ a6:f }} cmds {{ world.m:d }} | frame {{ d.ms:f }} laps {{ d.laps:d }}")
            |> libs/nativelayout:nl.drop(cl: nh)
            |> libs/clay:drop(cl: h)
    | err ne |> std/io:print.ln("nl init failed: {{ ne:s }}")
| err e |> std/io:print.ln("clay init failed: {{ e:s }}")
