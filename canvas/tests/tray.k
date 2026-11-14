// Tray spike: an NSStatusItem with a menu, events arriving through the same
// mailbox the view IMPs write. Items match on `tag` (integer `when` guards,
// the k.code == 53 precedent); `action` rides along as representedObject
// for printing.
//
//   click the "◉ koru" status item -> menu -> items print; Quit exits.
//   esc or the window's close button also quit.
//
// Automated path: libs/host:tray.action pushes a synthesized event into
// the same mailbox — verifies ring -> arm dispatch without AX trust. The
// KoruTrayTarget IMP wiring itself needs a real click (human, or System
// Events).
//
// [with(libs/canvas)] opens the impl's vocabulary: every call below is bare —
// tray.item, window.open, frames, quit — with only std/io staying qualified.
//
//   koruc run canvas/tests/tray.k

import libs/host
import libs/canvas
import std/io

[with(libs/host, libs/canvas)]
tray.new(title: "◉ koru")
| tray t |> tray.item(tray: t, label: "Beep", action: "beep", tag: 1)
         |> tray.sep(tray: t)
         |> tray.item(tray: t, label: "Quit", action: "quit", tag: 9)
         |> tray.action(tray: 0, tag: 1, action: "synthetic")
         |> window.open(width: 480, height: 320, title: "tray spike — esc to quit")
    | win w |> window.clear.color(win: w, r: 0.08, g: 0.1, b: 0.2) |> frames(win: w, count: 5400)
        ! frame f |> draw.roundrect(f, x: 40.0, y: 40.0, w: 240.0, h: 90.0, radius: 12.0, r: 0.2, g: 0.6, b: 0.9, a: 1.0)
                  |> draw.text(f, x: 58.0, y: 76.0, size: 18.0, r: 0.05, g: 0.1, b: 0.15, a: 1.0, text: "click the tray item")
        ! tray-action a |> std/io:print.ln("tray: \"{{ a.action:s }}\" tag={{ a.tag:d }} tray={{ a.tray:d }}")
                        |> if (a.tag == 9)
                            | then |> quit()
        ! key-down k when k.code == 53 |> quit()
        ! close |> quit()
        | done w2 |> window.close(win: w2) |> tray.remove(tray: t) |> std/io:print.ln("tray: closed clean")
    | err e |> tray.remove(tray: t) |> std/io:print.ln("window init failed: {{ e:s }}")
| err e2 |> std/io:print.ln("tray init failed: {{ e2:s }}")
