// term_termview — the `termview` component on a composed surface, headless.
//
// A feed-only session takes canned vt bytes — a champagne prompt, a
// command echo, styled output, a painted ERR span — and the component
// draws what the bytes ARE: ink card, OSC-title header, run-colored
// rows, cursor mark. Scripted, deterministic, snapped.
//
//   koruc run metal/tests/term_termview.k
//   sips -s format png /tmp/term_termview.bmp --out /tmp/term_termview.png

import libs/metal
import libs/vt
import libs/components/term_termview
import std/store
import std/io

std/store:new(world) { frame: 0[i64], term: -1[i64], fnt: 0[i64] }

libs/vt:term-open(cols: 56, rows: 12, cmd: "") : h
    |> std/store:stored { world.term: h }
    |> libs/vt:term-feed(h, bytes: "\x1b[1;32momni\x1b[0m \x1b[90m~/src/oshun\x1b[0m\r\n\x1b[32m$\x1b[0m vt-probe --session\x1b[90m # live\x1b[0m\r\npty open      \x1b[32mok\x1b[0m\r\nfeed          \x1b[32mok\x1b[0m  37 bytes\r\nsnap          \x1b[32mok\x1b[0m  40x8 walked\r\nlink          \x1b[41m ERR \x1b[0m  ghostty-vt not vendored\r\n\x1b[32m$\x1b[0m ") : fed
        |> std/io:print.ln("term: fed {{ fed:d }} bytes")
        |> libs/metal:offscreen.open(width: 1080, height: 700, scale: 2.0)
            | surf s |> libs/metal:offscreen.clear.color(s, r: 0.91, g: 0.85, b: 0.72)
                |> libs/components/term_termview:term-font(path: "/System/Library/Fonts/SFNSMono.ttf")
                    | font ft |> std/store:stored { world.fnt: ft }
                    | err fe |> std/io:print.ln("term: font failed {{ fe:s }}")
                |> for(0..40)
                    ! each _ |> libs/metal:offscreen.frame(s)
                        ! frame f
                            |> std/store:stored { world.frame: world.frame + 1 }
                            // the room — the champagne silk drape
                            |> libs/metal:draw.roundrect(f, x: 0.0, y: 0.0, w: 1080.0, h: 700.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
                            // a pearl halo where the card lands
                            |> libs/metal:draw.roundrect(f, x: 200.0, y: 130.0, w: 680.0, h: 460.0, radius: 210.0, r: 0.97, g: 0.93, b: 0.82, a: 0.35)
                            // the component — the session rises in
                            |> libs/components/term_termview:termview(f, world.term, face: world.fnt, x: 140.0, y: 60.0, w: 800.0, h: 560.0,
                                t: @as(f64, @floatFromInt(world.frame)) / 25.0, a: 1.0)
                            // the caption — system face, the demo's claim
                            |> libs/metal:draw.text(f, x: 230.0, y: 660.0, size: 13.0, r: 0.42, g: 0.34, b: 0.22, a: 0.8, text: "the terminal surface — ghostty-vt emulation, oshun's own paint")
                            // mid-flight snap — card still arriving
                            |> if (world.frame == 14)
                                | then |> libs/metal:offscreen.snap(s, path: "/tmp/term_termview_arrive.bmp")
                        | done _
                |> libs/metal:offscreen.snap(s, path: "/tmp/term_termview.bmp")
                |> libs/vt:term-close(h: world.term) : rc
                    |> std/io:print.ln("term: closed {{ rc:d }}")
                |> libs/metal:offscreen.close(s)
            | err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
