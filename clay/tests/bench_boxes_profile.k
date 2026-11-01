// profiling build: long climb for `sample`; not a measurement.
// bench_boxes_split1 shape (declare + drain, no paint) with the current
// expansion: single ordered leaves walk, capture-local HSL, multi-line
// panelx. climb(warmup: 30, frames: 4096, reps: 25) ≈ a minute of frames.
// Laps: 1 = expand+declare, 2 = endlayout, 3 = drain.
import libs/clay
import libs/ui
import std/store
import std/io
import std/benchmarking

std/store:new(world) { n: 0[i64], f: 0[i64] }

std/store:new(leaves, capacity: 1024) { i: i64, gr: i64, gc: i64 }

std/store:new(gs) { t: 0.0[f64], off: 0.0[f64] }

for(0..600)
    ! each j |> std/store:insert(leaves) { i: @as(i64, @intCast(j)), gr: @divTrunc(@as(i64, @intCast(j)), 30), gc: @mod(@as(i64, @intCast(j)), 30) }

libs/clay:init(width: 900, height: 640)
| cl h |> std/benchmarking:climb(warmup: 30, frames: 4096, reps: 25)
    ! pass
        |> std/store:stored { world.f: world.f + 1 }
        |> std/store:stored { gs.t: @as(f64, @floatFromInt(world.f)) / 120.0 }
        |> std/store:stored { world.n: 0 }
        |> libs/clay:layout(cl: h)
            ! tree t
                |> libs/ui:panel(t, dock: "", ws: "star", w: 1.0, hs: "star", h: 1.0, dir: "ttb", gap: 4, pad: 10, ax: "start", ay: "start", r: 0.0, g: 0.0, b: 0.0, a: 0.0, fl: 0, fx: 0.0, fy: 0.0)
                |> std/store:query(leaves)
                    ! query lf
                        |> if (lf.gc == 0)
                            | then |> libs/clay:el.close-to(t, d: 1)
                                |> libs/ui:panel(t, dock: "", ws: "star", w: 1.0, hs: "auto", h: 0.0, dir: "", gap: 4, pad: 0, ax: "start", ay: "start", r: 0.0, g: 0.0, b: 0.0, a: 0.0, fl: 0, fx: 0.0, fy: 0.0)
                        |> capture { hh: @mod(gs.t * 60.0 + @as(f64, @floatFromInt(lf.i)) * 3.0, 360.0), k0: 0.0[f64], k8: 0.0[f64], k4: 0.0[f64] }
                            ! as a |> captured { a.hh, k0: @mod(0.0 + a.hh / 30.0, 12.0), k8: @mod(8.0 + a.hh / 30.0, 12.0), k4: @mod(4.0 + a.hh / 30.0, 12.0) }
                            | captured c |> libs/ui:panelx(t, dock: "", ws: "fix", w: 24.0, hs: "fix", h: 24.0, dir: "", gap: 0, pad: 0, ax: "start", ay: "start",
                                r: (0.55 - 0.315 * @max(-1.0, @min(@min(c.k0 - 3.0, 9.0 - c.k0), 1.0))) * 255.0,
                                g: (0.55 - 0.315 * @max(-1.0, @min(@min(c.k8 - 3.0, 9.0 - c.k8), 1.0))) * 255.0,
                                b: (0.55 - 0.315 * @max(-1.0, @min(@min(c.k4 - 3.0, 9.0 - c.k4), 1.0))) * 255.0,
                                a: 255.0, fl: 0, fx: 0.0, fy: 0.0, eid: lf.i)
                                |> libs/clay:el.close(t)
                |> std/benchmarking:lap(k: 1)
            | solved cls
                |> std/benchmarking:lap(k: 2)
                |> libs/clay:each(cl: cls)
                    ! cmd rc
                        |> std/store:stored { gs.off: 6.0 * @sin(gs.t * 3.0 + @as(f64, @floatFromInt(rc.ud)) * 0.1) }
                        |> std/store:stored { world.n: world.n + 1 }
                    | drained |> _
    | done d |> std/benchmarking:lap.ms(k: 1): a1 |> std/benchmarking:lap.ms(k: 2): a2 |> std/benchmarking:lap.ms(k: 3): a3
        |> std/io:print.ln("full: frame {{ d.ms:f }} ms | expand+declare {{ a1:f }} | endlayout {{ a2:f }} | drain {{ a3:f }} | laps {{ d.laps:d }} | {{ world.n:d }} cmds")
        |> libs/clay:drop(cl: h)
| err x |> std/io:print.ln("clay init failed: {{ x:s }}")
