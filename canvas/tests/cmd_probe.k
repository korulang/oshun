// Headless probe for the commander's wire path: does `file-open(path: "...")`
// mint a bridge handle through std/bridge:run on the image scope? Prints the
// arm that fired; the mint itself lands in /tmp/omni_probe/holds.log.

import std/bridge
import std/io
import app/omni_img

[with]std/bridge:create(id: "probe", scope: "image", world: "/tmp/omni_probe"): br
|> std/bridge:run(br, source: "file-open(path: \"/tmp/omni_cmd_t60.png\")")
    | result r |> std/io:print.ln("RESULT handles={{ r.handles:d }} bound={{ r.bound:s }}")
    | error e |> std/io:print.ln("ERROR {{ e.kind:s }}: {{ e.message:s }}")
    | residue r |> std/io:print.ln("RESIDUE report={{ r.report:s }}")
    | defined d |> std/io:print.ln("DEFINED {{ d:s }}")
    | unhandled-branch u |> std/io:print.ln("UNHANDLED {{ u.branch:s }}")
    | partial p |> std/io:print.ln("PARTIAL {{ p.ran:d }}/{{ p.total:d }}")
|> std/bridge:close(br)
|> std/io:print.ln("done")
