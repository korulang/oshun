// host/tests/notify2.k — notification probe under a FRESH bundle id.
// org.koru.oshun.notify already has an answered auth prompt (dismissed
// counts as a decision — macOS won't re-prompt for that id), so this
// probe uses org.koru.oshun.notify2, which is still notDetermined and
// WILL show the real permission prompt on first send.
//
//   koruc bundle host/tests/notify2.k
//   open "host/tests/Oshun Notify 2.app"
//
// Click ◉ nf2 → Notify: the system auth prompt appears (Allow it),
// click Notify again: a real banner. The app must stay alive — the
// auth request is async XPC and a send-then-exit process kills the
// connection before the prompt machinery engages.

import libs/host
import std/build
import std/io

std/build:app { name: "Oshun Notify 2", id: "org.koru.oshun.notify2", version: "0.1", icon: "koru.icns" }

[with(libs/host)]
tray.new(title: "◉ nf2")
| tray t |> tray.item(tray: t, label: "Notify", action: "notify", tag: 2)
         |> tray.item(tray: t, label: "Quit", action: "quit", tag: 9)
         |> host.run(count: 60000)
     ! tray-action a |> std/io:print.ln("tray: \"{{ a.action:s }}\" tag={{ a.tag:d }}")
                     |> if (a.tag == 2)
                         | then |> notify.send(title: "◉ koru", body: "the notify verb is real")
                             | ok |> std/io:print.ln("notify: sent")
                             | err e |> std/io:print.ln("notify: {{ e:s }}")
                     |> if (a.tag == 9)
                         | then |> quit()
     | done |> tray.remove(tray: t) |> std/io:print.ln("notify2: run clean")
| err e |> std/io:print.ln("tray init failed: {{ e:s }}")
