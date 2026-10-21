// Menu spike: a real NSApp.mainMenu — the second host verb, riding the
// same chrome ring as the tray. "App" heading with a Quit item carrying
// keyEquivalent "q" — Cmd-Q fires menuItemClicked: for free.
//
//   the "App" menu appears in the menu bar; clicking Quit or pressing
//   Cmd-Q exits.
//
// Automated path: menu.action pushes a synthesized beep into the same
// ring — verifies ring -> arm dispatch without AX trust. The real Quit
// (click or Cmd-Q) is the exit; `count` caps the run for CI.
//
//   koruc run host/tests/menu.k

import libs/host
import std/build
import std/io

std/build:app { name: "Oshun Menu Probe", id: "org.koru.oshun.menu", version: "0.1" }

[with(libs/host)]
menu.new()
| menu m |> menu.bar(menu: m, title: "App")
    | bar b |> menu.item(bar: b, label: "Quit Oshun Menu Probe", key: "q", action: "quit", tag: 9)
            |> menu.action(tag: 5, action: "synthetic-beep")
            |> host.run(count: 3600)
        ! menu-action a |> std/io:print.ln("menu: \"{{ a.action:s }}\" tag={{ a.tag:d }}")
                        |> if (a.tag == 9)
                            | then |> quit()
        | done |> menu.remove(menu: m) |> std/io:print.ln("menu: run clean")
    | err e |> std/io:print.ln("bar failed: {{ e:s }}")
| err e |> std/io:print.ln("menu init failed: {{ e:s }}")
