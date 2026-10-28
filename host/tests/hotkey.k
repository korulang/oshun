// Hotkey spike — Carbon RegisterEventHotKey lands a real registration
// (status==noErr is the receipt), then synthetic pushes exercise the
// ring -> arm path in both directions. A real keypress is the half only
// a keyboard can prove; the ring half is asserted here.
//
//   koruc run host/tests/hotkey.k

import libs/host
import std/io

libs/host:hotkey.watch(key: 49, mods: 6144)
| watching hk
    |> libs/host:hotkey.action(key: 49, mods: 6144, down: 1)
    |> libs/host:hotkey.action(key: 49, mods: 6144, down: 0)
    |> libs/host:host.run(count: 30)
        ! hotkey h |> std/io:print.ln("hotkey: down={{ h.down:d }} key={{ h.key:d }} mods={{ h.mods:d }}")
        | done |> libs/host:hotkey.unwatch(hk) |> std/io:print.ln("hotkey: unwatched, pump done")
| err e |> std/io:print.ln("watch failed: {{ e:s }}")
