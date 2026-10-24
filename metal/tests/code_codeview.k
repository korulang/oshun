// code_codeview — the `codeview` component on a composed surface, headless.
//
// The demo renders metal/tests/silk_live.k — a real source file whose head
// mixes comment header, imports, and store decls, so comments, keywords,
// numbers, strings-adjacent sigils and plain words all take their own
// colors. file-open mints the
// resource, the omni_img doc seam decodes its real lines, code-font loads
// SF Mono into metal's registry (the offscreen path can't take font.load's
// *Window), and codeview draws it — ink silk card on a champagne room,
// gutter, spans, scroll, all of it. The card enters over 40 frames: it
// rises and fades while the scroll drifts from 4 lines up to rest at 0,
// and each code line staggers in behind the panel.
//
// Snapshots: frame 25 catches the arrive mid-flight (trailing lines still
// rising, view still settling); the post-loop snap is the settled card.
//
//   koruc run metal/tests/code_codeview.k
//   sips -s format png /tmp/code_codeview.bmp --out /tmp/code_codeview.png

import libs/metal
import libs/components/code_codeview
import app/omni_img
import std/store
import std/io

std/store:new(world) { frame: 0[i64], slot: 0[i64], fnt: 0[i64] }

app/omni_img:file-open(path: "/Users/larsde/src/oshun/metal/tests/silk_live.k")
| ok h |> libs/metal:offscreen.open(width: 920, height: 560, scale: 2.0)
    | surf s |> libs/metal:offscreen.clear.color(s, r: 0.13, g: 0.11, b: 0.09)
        |> libs/components/code_codeview:code-doc-slot() : sl
        |> std/store:stored { world.slot: sl }
        |> libs/components/code_codeview:code-font(path: "/System/Library/Fonts/SFNSMono.ttf")
            | font ft |> std/store:stored { world.fnt: ft }
            | err fe |> std/io:print.ln("code_codeview: font failed {{ fe:s }}")
        |> for(0..47)
            ! each _ |> libs/metal:offscreen.frame(s)
                ! frame f
                    |> std/store:stored { world.frame: world.frame + 1 }
                    // the room — the champagne silk drape the commander stands on
                    |> libs/metal:draw.roundrect(f, x: 0.0, y: 0.0, w: 920.0, h: 560.0, radius: 0.0, r: 0.91, g: 0.85, b: 0.72, a: 1.0)
                    // a pearl halo where the card lands — its fringe reads
                    // around the card's edges
                    |> libs/metal:draw.roundrect(f, x: 60.0, y: 20.0, w: 800.0, h: 500.0, radius: 240.0, r: 0.97, g: 0.93, b: 0.82, a: 0.30)
                    // the component — t and scroll driven by the frame count
                    |> libs/components/code_codeview:code-ease(t: @as(f64, @floatFromInt(world.frame)) / 40.0) : sc
                    |> libs/components/code_codeview:codeview(f, world.slot, face: world.fnt, x: 130.0, y: 60.0, w: 660.0, h: 420.0,
                        scroll: 4.0 * (1.0 - sc),
                        t: @as(f64, @floatFromInt(world.frame)) / 40.0, a: 1.0)
                    // caption under the card — the file's name in the mono face
                    |> app/omni_img:res-path(world.slot) : p
                    |> libs/components/code_codeview:code-path-tail(path: p) : ttl
                    |> libs/components/code_codeview:code-measure(f, text: ttl, size: 12.0, face: world.fnt) : tw
                    |> libs/metal:draw.textface(f, x: 460.0 - tw / 2.0, y: 502.0, size: 12.0, font: world.fnt, r: 0.30, g: 0.24, b: 0.16, a: 0.85, text: ttl)
                    // mid-flight snap — the previous frame's commit, still arriving
                    |> if (world.frame == 26)
                        | then |> libs/metal:offscreen.snap(s, path: "/tmp/code_codeview_arrive.bmp")
                | done _
        |> libs/metal:offscreen.snap(s, path: "/tmp/code_codeview.bmp")
        |> libs/metal:offscreen.close(s)
        |> app/omni_img:file-close(handle: h)
        |> std/io:print.ln("code_codeview: snapped + closed")
    | err e |> std/io:print.ln("metal offscreen init failed: {{ e:s }}")
| not-found p |> std/io:print.ln("code_codeview: source missing {{ p:s }}")
