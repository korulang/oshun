// vt binding probe — feed-only session, canned bytes, snap walk.
import libs/vt
import std/io

libs/vt:term-open(cols: 40, rows: 8, cmd: "") : h
    |> libs/vt:term-feed(h, bytes: "\x1b[1;32momni $\x1b[0m echo hi\r\nhi there\r\n") : fed
        |> libs/vt:term-snap(h) : ok
            |> libs/vt:term-cols() : nc
                |> libs/vt:term-rows() : nr
                    |> libs/vt:term-row-text(y: 0) : t0
                        |> libs/vt:term-row-text(y: 1) : t1
                            |> std/io:print.ln("snap {{ ok:d }} {{ nc:d }}x{{ nr:d }} fed={{ fed:d }}")
                            |> std/io:print.ln("row0=|{{ t0:s }}|")
                            |> std/io:print.ln("row1=|{{ t1:s }}|")
                            |> libs/vt:term-fg(i: 0) : fg0
                                |> libs/vt:term-flags(i: 0) : fl0
                                    |> std/io:print.ln("cell0 fg={{ fg0:d }} flags={{ fl0:d }}")
                                    |> libs/vt:term-close(h) : rc
                                        |> std/io:print.ln("closed {{ rc:d }}")
