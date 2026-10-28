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
    |> libs/host:mic.read(mic: m, max: 16000)
        | ok pcm |> std/io:print.ln("drained {{ pcm.len:d }} bytes") |> std/io:free(content: pcm)
            |> libs/host:mic.stop(mic: m) |> std/io:print.ln("mic: stopped")
        | empty |> std/io:print.ln("ring empty (no audio yet)") |> libs/host:mic.stop(mic: m)
| err st |> std/io:print.ln("mic.start refused: {{ st:d }}")
