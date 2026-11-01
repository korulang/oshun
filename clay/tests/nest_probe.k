import libs/clay
import std/store
import std/io
import std/benchmarking

std/store:new(world) { f: 0[i64], n: 0[i64] }

libs/clay:init(width: 640, height: 400)
| cl h |> std/benchmarking:climb(warmup: 2, frames: 4, reps: 1)
    ! pass
        |> std/store:stored { world.f: world.f + 1 }
        |> if (world.f > 1)
            | then |> libs/clay:layout(cl: h)
                ! tree t |> _
                | solved cls |> libs/clay:each(cl: cls)
                    ! cmd rc |> std/store:stored { world.n: world.n + 1 }
                    | drained |> _
        |> std/io:print.ln("n {{ world.n:d }}")
