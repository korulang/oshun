// Dialog spike: the first synchronous host verbs, called the way
// dialogs are really triggered — from inside a pump arm. The tor
// blocks, spins a nested modal loop, and the answer IS the branch.
//
//   Tray "◉ dlg" -> "Confirm..." is an NSAlert -> | ok | | cancel |.
//   Tray -> "Alert" is a one-button NSAlert (dismissal is the answer).
//   Tray -> "Open..." is an NSOpenPanel -> | path | or | cancel |.
//   Tray -> "Quit" exits.
//
// The tray is the trigger surface because a windowless app's main menu
// is only visible while frontmost — and unbundled binaries cannot
// activate on demand. The status item is always reachable.
//
//   koruc run host/tests/dialog.k

import libs/host
import std/io

[with(libs/host)]
tray.new(title: "◉ dlg")
| tray t |> tray.item(tray: t, label: "Confirm...", action: "confirm", tag: 2)
         |> tray.item(tray: t, label: "Alert", action: "alert", tag: 3)
         |> tray.item(tray: t, label: "Open...", action: "open", tag: 4)
         |> tray.sep(tray: t)
         |> tray.item(tray: t, label: "Quit", action: "quit", tag: 9)
         |> host.run(count: 45000)
     ! tray-action a |> std/io:print.ln("tray: \"{{ a.action:s }}\" tag={{ a.tag:d }}")
                     |> if (a.tag == 2)
                         | then |> dialog.confirm(title: "◉ koru", message: "host verbs are real now")
                             | ok |> std/io:print.ln("dialog: ok")
                             | cancel |> std/io:print.ln("dialog: cancel")
                     |> if (a.tag == 3)
                         | then |> dialog.alert(title: "◉ koru", message: "dismiss me")
                                 |> std/io:print.ln("dialog: dismissed")
                     |> if (a.tag == 4)
                         | then |> dialog.open(title: "pick a file")
                             | path p |> std/io:print.ln("dialog: path \"{{ p:s }}\"")
                             | cancel |> std/io:print.ln("dialog: open cancelled")
                     |> if (a.tag == 9)
                         | then |> quit()
     | done |> tray.remove(tray: t) |> std/io:print.ln("dialog: run clean")
| err e |> std/io:print.ln("tray init failed: {{ e:s }}")
