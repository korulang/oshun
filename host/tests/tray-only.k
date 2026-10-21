// Tray-only spike: a status-item app with NO window — the first member of
// the gap catalog. host.run is the windowless pump: AppKit still needs its
// event loop serviced for the menu to open, but nothing renders.
//
//   click "◉ koru" in the menu bar -> Quit exits.
//
// Automated path: tray.action pushes a synthesized quit event before the
// pump starts — the first drain fires the arm, quit() breaks the loop.
// Self-verifying end to end, no AX trust needed.
//
//   koruc run host/tests/tray-only.k

import libs/host
import std/io

[with(libs/host)]
tray.new(title: "◉ koru")
| tray t |> tray.item(tray: t, label: "Quit", action: "quit", tag: 9)
         |> tray.action(tray: 0, tag: 9, action: "synthetic-quit")
         |> host.run(count: 600)
    ! tray-action a |> std/io:print.ln("tray: \"{{ a.action:s }}\" tag={{ a.tag:d }}")
                    |> if (a.tag == 9)
                        | then |> quit()
    | done |> tray.remove(tray: t) |> std/io:print.ln("host: run clean")
| err e |> std/io:print.ln("tray init failed: {{ e:s }}")
