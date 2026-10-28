// Mic spike — VoiceProcessingIO capture: start, wait half a second of
// render cycles, read the level window, drain the ring, stop. The unit
// negotiates 16kHz f32 mono or refuses loudly (err = OSStatus*100+step;
// -1 no component, -2 format mismatch).
//   koruc run host/tests/mic.k

import libs/host
import std/io
import std/time

libs/host:mic.start()
| live m |> std/time:sleep-ms(ms: 500)
    |> libs/host:mic.level(mic: m, window: 4000) : lv
    |> std/io:print.ln("level: {{ lv:f }}")
    |> libs/host:mic.dump(mic: m, path: "/tmp/mic_dump.f32", max: 16000)
        | ok |> std/io:print.ln("dumped ring to /tmp/mic_dump.f32")
            |> libs/host:mic.stop(mic: m) |> std/io:print.ln("mic: stopped")
        | err e |> std/io:print.ln("dump failed: {{ e:s }}") |> libs/host:mic.stop(mic: m)
| err st |> std/io:print.ln("mic.start refused: {{ st:d }}")
