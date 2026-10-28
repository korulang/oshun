// Paste spike — writes a known string to the clipboard, reads it back,
// prints it. The pasteboard write is verified end to end here; the
// synthesized Cmd+V needs a focused text field and an AX grant — only a
// human can receipt that half.
//   koruc run host/tests/paste.k

import libs/host
import std/io

libs/host:paste.text(text: "koru paste spike")
| ok |> libs/host:paste.read()
    | ok clip |> std/io:print.ln("clipboard: {{ clip:s }}") |> std/io:free(content: clip)
    | empty |> std/io:print.ln("clipboard empty after write — write failed")
| err e |> std/io:print.ln("paste failed: {{ e:s }}")
