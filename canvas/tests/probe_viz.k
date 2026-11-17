import std/bridge
import std/io

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_world_probe"): br
|> std/bridge:run(br, source: "file-open(path: \"/Users/larsde/src/oshun/canvas/tests/assets/voice_take.wav\")")
    | result _ |> std/bridge:run(br, source: "file-open(path: \"/Users/larsde/src/oshun/canvas/tests/assets/voice_take_alt.wav\")")
        | result _ |> std/io:print.ln("both minted")
        | error e |> std/io:print.ln("b {{ e.message:s }}")
    | error e |> std/io:print.ln("a {{ e.message:s }}")
