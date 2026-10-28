// Dictate spike — the summon loop end to end in one file:
//   needle.load + string accumulator + mic.start + two hotkey watches ->
//   host.run idles -> Ctrl+Option+Period DOWN clears the accumulator,
//   mints an overlay, shows it, runs a nested frames pump -> each frame
//   drains mic.read into needle stream.process and appends the chunk's
//   committed text to the accumulator -> key UP hides -> frames exits ->
//   stream.stop appends its tail -> paste.string pushes the JOIN to the
//   clipboard + Cmd+V -> Ctrl+Option+Q quits.
//
// Engine, mic, and the accumulator are minted at top level and BORROWED
// inside arms — warm across presses. The overlay mints/discharges per
// press inside the arm: no obligation crosses the pump boundary.
//
//   koruc run host/tests/dictate.k

import libs/host
import libs/metal
import libs/needle
import std/io
import std/json

libs/needle:load(path: "/Users/larsde/.cache/cactus-needle/whistle/2.0.0/whistle.cact")
| ready eng |> libs/host:mic.start()
    | live m |> libs/host:hotkey.watch(key: 47, mods: 6144)
        | watching hk1 |> libs/host:hotkey.watch(key: 12, mods: 6144)
            | watching hk2 |> libs/host:host.run(count: 9999999)
                ! hotkey h when h.key == 47 and h.down == 1
                    |> libs/metal:window.overlay(width: 360, height: 72, radius: 20.0)
                        | win ov |> libs/metal:window.show(win: ov)
                            |> libs/metal:window.clear.color(win: ov, r: 0.07, g: 0.06, b: 0.11)
                            |> libs/metal:frames(win: ov, count: 9999999)
                                ! frame f
                                    |> libs/host:mic.level(mic: m, window: 800) : lv
                                    |> libs/metal:draw.rect(f, x: 20.0, y: 26.0, w: lv * 4000.0, h: 20.0, r: 0.4, g: 0.9, b: 0.5, a: 1.0)
                                ! hotkey h2 when h2.key == 47 and h2.down == 0
                                    |> libs/metal:window.hide(win: ov)
                                | done ov2 |> libs/host:mic.read(mic: m, max: 480000)
                                    | ok pcm |> libs/needle:transcribe(eng, pcm, language: "en")
                                        | ok json |> std/json:get.string(json, key: "text")
                                            | ok t |> std/io:print.ln("transcript: {{ t:s }}")
                                                |> libs/host:paste.text(text: t)
                                                    | ok |> std/io:print.ln("paste: ok")
                                                        |> std/io:free(content: json)
                                                        |> std/io:free(content: pcm)
                                                    | err e |> std/io:print.ln("paste err: {{ e:s }}")
                                                        |> std/io:free(content: json)
                                                        |> std/io:free(content: pcm)
                                            | not-found |> std/io:print.ln("no text in result")
                                                |> std/io:free(content: json)
                                                |> std/io:free(content: pcm)
                                        | err e |> std/io:print.ln("transcribe err: {{ e:s }}")
                                            |> std/io:free(content: pcm)
                                    | empty
                                    |> libs/metal:window.close(win: ov2)
                        | err e |> std/io:print.ln("overlay err: {{ e:s }}")
                ! hotkey h when h.key == 12 and h.down == 1
                    |> libs/host:quit()
                | done |> libs/host:hotkey.unwatch(hk: hk1)
                    |> libs/host:hotkey.unwatch(hk: hk2)
                    |> libs/host:mic.stop(mic: m)
                    |> libs/needle:unload(eng)
                    |> std/io:print.ln("dictate: clean shutdown")
            | err e |> std/io:print.ln("watch err: {{ e:s }}")
        | err e |> std/io:print.ln("watch err: {{ e:s }}")
    | err st |> std/io:print.ln("mic err: {{ st:d }}")
| err e |> std/io:print.ln("needle err: {{ e:s }}")
