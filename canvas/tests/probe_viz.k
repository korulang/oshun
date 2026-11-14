import std/bridge
import std/io

[with]std/bridge:create(id: "omni", scope: "image", world: "/tmp/omni_world_probe"): br
|> std/bridge:run(br, source: "file-open(path: \"/tmp/omni_remote_mic_1.wav\")")
    | result _ |> std/bridge:run(br, source: "file-open(path: \"/tmp/omni_remote_mic_3.wav\")")
        | result _ |> std/io:print.ln("both minted")
        | error e |> std/io:print.ln("b {{ e.message:s }}")
    | error e |> std/io:print.ln("a {{ e.message:s }}")
