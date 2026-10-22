// host/tests/notify.k — notification probe: a tray app whose items fire
// notify.send. MUST be bundled to work — UNUserNotificationCenter needs a
// real bundle id:
//   koruc bundle host/tests/notify.k
//   open "host/tests/Oshun Notify Probe.app"
// Then click ◉ ntf → Notify. First click raises the system permission
// prompt (grant it); the second delivers a real banner.

import libs/host
import std/build
import std/io

std/build:app { name: "Oshun Notify Probe", id: "org.koru.oshun.notify", version: "0.1" }

[with(libs/host)]
tray.new(title: "◉ ntf")
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
     | done |> tray.remove(tray: t) |> std/io:print.ln("notify: run clean")
| err e |> std/io:print.ln("tray init failed: {{ e:s }}")
